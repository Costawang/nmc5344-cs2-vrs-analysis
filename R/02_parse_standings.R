source("R/helpers.R")
parse_standings <- function() {
  manifest <- read_csv_project("data/source_manifest.csv")
  files <- manifest |> filter(category == "standings", !is.na(snapshot_date), snapshot_date >= as.Date("2024-01-01"))
  parsed <- list(); errors <- list()
  for (i in seq_len(nrow(files))) {
    f <- files[i, ]; lines <- read_utf8(f$local_path)
    result <- tryCatch({
      tables <- md_tables(lines)
      ix <- which(vapply(tables, function(t) all(c("Standing", "Points", "Team Name", "Roster") %in% names(t)), logical(1)))
      if (length(ix) != 1) stop("Expected exactly one standings table")
      t <- tables[[ix]]
      if (!ncol(t) %in% c(4L, 5L) || !setequal(names(t)[1:4], c("Standing", "Points", "Team Name", "Roster")))
        stop("Unexpected standings columns: ", paste(names(t), collapse = ","))
      region <- str_match(f$source_path, "standings_([a-z]+)")[, 2]
      date <- snapshot_date_in_file(f$source_path, lines)
      if (is.na(date)) stop("Missing snapshot date")
      links <- if (ncol(t) >= 5) str_match(t[[5]], "\\(([^)]+)\\)")[, 2] else rep(NA_character_, nrow(t))
      tibble(source_id = f$source_id, series = f$series, snapshot_date = date, list_region = region,
             rank = as.integer(t$Standing), points = as.double(t$Points), team = clean_text(t[["Team Name"]]),
             roster = clean_text(t$Roster), detail_relative_link = links,
             commit_sha = f$commit_sha, first_seen_utc = f$first_seen_utc, last_seen_utc = f$last_seen_utc,
             source_path = f$source_path, source_local_path = f$local_path,
             roster_signature = vapply(clean_text(t$Roster), roster_signature, character(1)),
             roster_size = lengths(lapply(clean_text(t$Roster), player_set)))
    }, error = function(e) e)
    if (inherits(result, "error")) errors[[length(errors) + 1L]] <- tibble(source_id = f$source_id, issue = conditionMessage(result)) else parsed[[length(parsed) + 1L]] <- result
  }
  err <- if (length(errors)) bind_rows(errors) else tibble(source_id = character(), issue = character())
  save_csv(err, "output/validation/standings_parse_errors.csv")
  if (nrow(err)) stop("Standings parsing errors; see validation report")
  all <- bind_rows(parsed)
  canonical_files <- all |> distinct(series, snapshot_date, list_region, source_id, first_seen_utc, last_seen_utc) |>
    group_by(series, snapshot_date, list_region) |> arrange(desc(last_seen_utc), desc(first_seen_utc), .by_group = TRUE) |>
    slice_head(n = 1) |> ungroup() |> pull(source_id)
  all$is_latest_revision <- all$source_id %in% canonical_files
  # Invitation has priority only when the same dated official global ranking exists.
  global <- all |> filter(list_region == "global", is_latest_revision) |>
    mutate(priority = match(series, c("invitation", "live", "legacy"))) |>
    group_by(snapshot_date) |> filter(priority == min(priority)) |> ungroup() |> select(-priority) |>
    arrange(snapshot_date, rank) |>
    mutate(snapshot_id = paste0(snapshot_date, "_", substr(source_id, 1, 12)),
           entry_id = paste0(snapshot_id, "_", sprintf("%04d", rank)),
           model_period = period_for(snapshot_date))
  all$canonical_global_source <- all$source_id %in% global$source_id
  catalog <- all |> group_by(source_id, series, snapshot_date, list_region, commit_sha, first_seen_utc, last_seen_utc,
                             is_latest_revision, canonical_global_source) |>
    summarise(n_rows = n(), min_rank = min(rank), max_rank = max(rank), incomplete_rosters = sum(roster_size != 5), .groups = "drop") |>
    arrange(snapshot_date, series, list_region, first_seen_utc)
  save_csv(all, "data/processed/vrs_standings_long.csv")
  save_csv(global, "data/processed/vrs_global_snapshots.csv")
  save_csv(catalog, "data/snapshot_catalog.csv")
  message("Parsed ", n_distinct(global$snapshot_date), " global dates and ", nrow(all), " source standings rows.")
  invisible(global)
}
