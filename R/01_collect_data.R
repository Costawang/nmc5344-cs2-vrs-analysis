# Archive official bytes, including superseded historical versions.
source("R/helpers.R")
collect_data <- function(update = FALSE) {
  sources <- list(valve_vrs = "ValveSoftware/counter-strike_regional_standings",
                  rules = "ValveSoftware/counter-strike_rules_and_regs")
  lock_path <- "config/source_lock.json"
  locked <- if (file.exists(lock_path) && !update) jsonlite::read_json(lock_path, simplifyVector = TRUE) else NULL
  collected <- if (is.null(locked)) format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC") else locked$collection_utc
  pins <- list(); manifests <- list(); histories <- list(); exclusions <- list()
  for (key in names(sources)) {
    repo_name <- sources[[key]]
    mirror <- paste0("work/upstream/", key, ".git")
    if (!dir.exists(mirror)) {
      status <- system2("git", c("clone", "--mirror", paste0("https://github.com/", repo_name, ".git"), shQuote(mirror)))
      if (status != 0) stop("Git clone failed: ", repo_name)
    } else if (update) git_lines(mirror, c("fetch", "origin", "+refs/heads/*:refs/heads/*"))
    pin <- if (is.null(locked)) git_lines(mirror, c("rev-parse", "refs/heads/main")) else locked$repositories[[key]]$commit_sha
    git_lines(mirror, c("cat-file", "-e", paste0(pin, "^{commit}")))
    pins[[key]] <- list(repository = repo_name, commit_sha = pin)
    history <- git_lines(mirror, c("log", pin, "--first-parent", "--format=%H%x09%cI%x09%s"))
    hist <- readr::read_tsv(I(paste(history, collapse = "\n")), col_names = c("commit_sha", "commit_time", "message"),
                            col_types = "ccc", show_col_types = FALSE)
    hist$repository <- repo_name
    histories[[key]] <- hist
    # Include the last pre-period tree as a methodological baseline.
    commits <- hist |> filter(substr(commit_time, 1, 10) >= "2024-01-01")
    baseline <- hist |> filter(substr(commit_time, 1, 10) < "2024-01-01") |> slice_head(n = 1)
    commits <- bind_rows(commits, baseline)
    seen_keys <- character(); records <- list(); appearances <- list()
    for (i in seq_len(nrow(commits))) {
      sha <- commits$commit_sha[i]
      tree <- git_tree(mirror, sha)
      keep <- if (key == "valve_vrs") {
        grepl("^(live/|invitation/|details/|standings_.*\\.md$|model/|data/|readme\\.md$|modelfit\\.png$)", tree$source_path)
      } else grepl("^(major-supplemental-rulebook\\.md|tournament-operation-requirements.*\\.md|Declaration of Conflicts of Interest\\.pdf)$", tree$source_path)
      if (i == 1) exclusions[[key]] <- tree[!keep, ] |> mutate(repository = repo_name, reason = "Not a ranking input or directly relevant interpretation document")
      tree <- tree[keep, ]
      ids <- paste(tree$source_path, tree$blob_sha, sep = "|")
      appearances[[i]] <- tibble(version_key = ids, commit_sha = sha, commit_time = commits$commit_time[i])
      new <- !ids %in% seen_keys
      seen_keys <- c(seen_keys, ids[new])
      selected <- tree$source_path[new]
      if (!length(selected)) next
      folder <- if (i == 1) "published" else paste0("history/", sha)
      new_records <- tree[new, ] |> mutate(version_key = ids[new], repository = repo_name,
        commit_sha = sha, collection_utc = collected,
        local_path = paste0("data/raw/", key, "/", folder, "/", source_path),
        in_pinned_tree = i == 1, baseline_only = substr(commits$commit_time[i], 1, 10) < "2024-01-01")
      records[[length(records) + 1L]] <- new_records
      message(key, ": ", substr(sha, 1, 8), " - ", length(selected), " new source versions")
      # Archive a small set of containing directories, then copy only selected files.
      roots <- unique(ifelse(grepl("/", selected), sub("/[^/]+$", "", selected), selected))
      roots <- roots[!vapply(roots, function(p) any(startsWith(p, paste0(setdiff(roots, p), "/"))), logical(1))]
      stage <- paste0("work/extract-", key)
      dir.create(stage, recursive = TRUE, showWarnings = FALSE)
      tarfile <- paste0("work/", key, "-extract.tar")
      # Group roots to remain below Windows command-line limits.
      batches <- split(roots, ceiling(cumsum(nchar(roots) + 4) / 5000))
      for (batch in batches) {
        git_lines(mirror, c("archive", sha, paste0("--output=", normalizePath("work", winslash = "/"), "/", basename(tarfile)), "--", batch))
        utils::untar(tarfile, exdir = stage, tar = "internal")
      }
      for (j in seq_len(nrow(new_records))) {
        rec <- new_records[j, ]
        dir.create(dirname(rec$local_path), recursive = TRUE, showWarnings = FALSE)
        src <- file.path(stage, rec$source_path)
        if (file.exists(rec$local_path)) {
          if (file_hash(src) != file_hash(rec$local_path)) stop("Existing raw file differs from official source: ", rec$local_path)
        } else if (!file.copy(src, rec$local_path, overwrite = FALSE, copy.mode = FALSE)) stop("Copy failed")
      }
      # These are fixed, task-owned scratch paths, never arbitrary source paths.
      stopifnot(startsWith(normalizePath(stage, winslash = "/"), paste0(normalizePath("work", winslash = "/"), "/")))
      unlink(stage, recursive = TRUE); unlink(tarfile)
    }
    occurrence <- bind_rows(appearances) |> arrange(commit_time) |> group_by(version_key) |>
      summarise(first_seen_commit = first(commit_sha), first_seen_utc = first(commit_time), last_seen_utc = last(commit_time), .groups = "drop")
    m <- bind_rows(records) |> left_join(occurrence, by = "version_key") |> select(-version_key)
    m$source_id <- vapply(paste(m$repository, m$source_path, m$blob_sha), hash_text, character(1))
    m$raw_url <- paste0("https://raw.githubusercontent.com/", m$repository, "/", m$commit_sha, "/", gsub(" ", "%20", m$source_path, fixed = TRUE))
    m$file_type <- tools::file_ext(m$source_path)
    m$category <- case_when(grepl("(^|/)standings_", m$source_path) ~ "standings",
      grepl("(^|/)details/", m$source_path) ~ "details", grepl("^model/", m$source_path) ~ "model",
      grepl("^data/", m$source_path) ~ "reference_input", key == "rules" ~ "rules", TRUE ~ "documentation")
    m$series <- case_when(startsWith(m$source_path, "live/") ~ "live",
      startsWith(m$source_path, "invitation/") ~ "invitation", m$category %in% c("standings", "details") ~ "legacy", TRUE ~ NA_character_)
    m$snapshot_date <- as.Date(vapply(seq_len(nrow(m)), function(i) {
      d <- snapshot_date_in_file(m$source_path[i])
      if (is.na(d) && m$category[i] == "standings") d <- snapshot_date_in_file(m$source_path[i], read_utf8(m$local_path[i]))
      as.character(d)
    }, character(1)))
    m$sha256 <- vapply(m$local_path, file_hash, character(1))
    stopifnot(all(file.info(m$local_path)$size == m$size_bytes))
    stopifnot(all(vapply(m$local_path, git_blob_hash, character(1)) == m$blob_sha))
    m$schema_version <- case_when(m$category == "standings" & m$series == "legacy" ~ "legacy_markdown",
      m$category == "standings" ~ "dated_markdown", m$category == "details" ~ "roster_report_markdown", TRUE ~ "upstream_bytes")
    m$collection_status <- "verified_bytes"
    m$notes <- ifelse(m$category == "reference_input", "Historical sample; not complete 2024-2026 match input", "")
    manifests[[key]] <- m
  }
  manifest <- bind_rows(manifests) |> arrange(repository, source_path, first_seen_utc, blob_sha)
  save_csv(manifest, "data/source_manifest.csv")
  save_csv(bind_rows(histories), "data/commit_history.csv")
  save_csv(bind_rows(exclusions), "data/source_exclusions.csv")
  jsonlite::write_json(list(collection_utc = collected, start_date = "2024-01-01", repositories = pins),
                       lock_path, auto_unbox = TRUE, pretty = TRUE)
  message("Archived ", nrow(manifest), " distinct path/blob versions.")
  invisible(manifest)
}
