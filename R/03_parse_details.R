source("R/helpers.R")
parse_details <- function() {
  g <- read_csv_project("data/processed/vrs_global_snapshots.csv")
  manifest <- read_csv_project("data/source_manifest.csv")
  md <- manifest |> filter(category == "details")
  # A link is resolved against the exact tree from which its standings file was read.
  trees <- new.env(hash = TRUE)
  summaries <- list(); matches <- list(); winnings <- list(); regions <- list(); errors <- list()
  for (i in seq_len(nrow(g))) {
    row <- g[i, ]; sha <- row$commit_sha
    if (!exists(sha, envir = trees, inherits = FALSE)) assign(sha, git_tree("work/upstream/valve_vrs.git", sha), envir = trees)
    base <- dirname(row$source_path)
    path <- if (base == ".") row$detail_relative_link else paste0(base, "/", row$detail_relative_link)
    tr <- get(sha, envir = trees)
    blob <- tr$blob_sha[match(path, tr$source_path)]
    k <- which(md$source_path == path & md$blob_sha == blob)
    result <- tryCatch({
      if (length(k) != 1 || is.na(blob)) stop("Detail link cannot be resolved to exactly one archived source")
      f <- md[k, ]; lines <- read_utf8(f$local_path); text <- paste(lines, collapse = "\n")
      val <- function(label) {
        v <- str_match(text, paste0(label, "[: ]+\\s*([-+0-9.]+)"))[, 2]
        as.double(v)
      }
      equation <- str_match(text, "Final Rank Value \\(([-+0-9.]+)\\) = Starting Rank Value \\(([-+0-9.]+)\\) \\+ Head To Head Adjustments \\(([-+0-9.]+)\\)")
      if (is.na(equation[1, 1])) stop("Unrecognized rank decomposition")
      summary <- tibble(entry_id = row$entry_id, snapshot_date = row$snapshot_date, detail_source_id = f$source_id,
        final_rank_value = as.double(equation[1, 2]), starting_rank_value = as.double(equation[1, 3]),
        h2h_adjustment = as.double(equation[1, 4]), bounty_offered = val("Bounty Offered"),
        bounty_collected = val("Bounty Collected"), opponent_network = val("Opponent Network"), lan_wins_factor = val("LAN Wins"),
        detail_team = clean_text(sub("^Team Name: *", "", lines[grepl("^Team Name:", lines)][1])),
        detail_roster = clean_text(sub("^Roster: *", "", lines[grepl("^Roster:", lines)][1])),
        detail_global_rank = as.integer(str_match(text, "Global Rank: \\[([0-9]+)\\]")[, 2]))
      reg <- str_match_all(text, "Region: \\[([^]]+)\\][^\\n]*\\nRegional Rank: \\[([0-9]+)\\]")[[1]]
      # Early report layout places Region and Regional Rank on separate sections.
      if (!nrow(reg)) {
        a <- str_match(text, "Region: \\[([^]]+)\\]")[, 2]
        b <- str_match(text, "Regional Rank: \\[([0-9]+)\\]")[, 2]
        if (!is.na(a) && !is.na(b)) reg <- matrix(c("", a, b), nrow = 1)
      }
      region <- tibble(entry_id = row$entry_id, snapshot_date = row$snapshot_date, region = tolower(reg[, 2]), regional_rank = as.integer(reg[, 3]))
      ts <- md_tables(lines)
      mi <- which(vapply(ts, function(t) "Opponent" %in% names(t), logical(1)))
      if (length(mi) != 1) stop("Expected one match contribution table")
      m <- ts[[mi]]
      names(m) <- str_replace_all(tolower(names(m)), "[^a-z0-9]", "")
      names(m)[names(m) == "participatingroster"] <- "roster"
      names(m)[names(m) == "h2hadjustment"] <- "h2hadj"
      expected <- c("matchplayed", "matchid", "date", "opponent", "wl", "ageweight", "eventweight", "bountycollected", "opponentnetwork", "lanwins", "h2hadj", "roster")
      if (!setequal(names(m), expected)) stop("Unexpected match columns: ", paste(names(m), collapse = ","))
      match <- tibble(entry_id = row$entry_id, snapshot_date = row$snapshot_date, detail_source_id = f$source_id,
        contribution_row = seq_len(nrow(m)), match_id_local = as.integer(m$matchid), match_played = as.integer(m$matchplayed),
        match_date = as.Date(m$date), opponent = clean_text(m$opponent), result = m$wl,
        age_weight = as.double(m$ageweight), event_weight = suppressWarnings(as.double(m$eventweight)),
        h2h_adjustment = as.double(m$h2hadj), match_roster = clean_text(m$roster))
      for (pair in list(c("bountycollected", "bounty_collected"), c("opponentnetwork", "opponent_network"), c("lanwins", "lan_wins"))) {
        value <- m[[pair[1]]]
        parsed <- str_match(value, "^([-+0-9.]+)\\s*\\(([-+0-9.]+)\\)$")
        if (any(is.na(parsed[, 1]) & value != "-")) stop("Unrecognized paired contribution value")
        match[[paste0(pair[2], "_raw")]] <- as.double(parsed[, 2])
        match[[paste0(pair[2], "_adjusted")]] <- as.double(parsed[, 3])
        match[[paste0(pair[2], "_reported")]] <- value != "-"
      }
      wi <- which(vapply(ts, function(t) "Prize Winnings" %in% names(t), logical(1)))
      win <- tibble()
      if (length(wi) > 1) stop("Multiple winnings tables")
      if (length(wi) == 1) {
        w <- ts[[wi]]
        if (!setequal(names(w), c("Event Date", "Age Weight", "Prize Winnings", "Scaled Winnings"))) stop("Unexpected winnings columns")
        win <- tibble(entry_id = row$entry_id, snapshot_date = row$snapshot_date, detail_source_id = f$source_id,
          winnings_row = seq_len(nrow(w)), event_date = as.Date(w[["Event Date"]]), age_weight = as.double(w[["Age Weight"]]),
          prize_winnings = numeric_value(w[["Prize Winnings"]]), scaled_winnings = numeric_value(w[["Scaled Winnings"]]))
      }
      list(summary = summary, matches = match, winnings = win, regions = region)
    }, error = function(e) e)
    if (inherits(result, "error")) errors[[length(errors) + 1L]] <- tibble(entry_id = row$entry_id, source_path = path, issue = conditionMessage(result)) else {
      summaries[[i]] <- result$summary; matches[[i]] <- result$matches
      winnings[[i]] <- result$winnings; regions[[i]] <- result$regions
    }
    if (i %% 2000 == 0) message("Parsed details: ", i, "/", nrow(g))
  }
  err <- if (length(errors)) bind_rows(errors) else tibble(entry_id = character(), source_path = character(), issue = character())
  save_csv(err, "output/validation/detail_parse_errors.csv")
  if (nrow(err)) stop("Detail parsing errors; see validation report")
  details <- bind_rows(summaries); match <- bind_rows(matches); win <- bind_rows(winnings)
  save_csv(details, "data/processed/vrs_team_details.csv")
  save_csv(bind_rows(regions), "data/processed/vrs_regions.csv")
  save_csv(win, "data/processed/vrs_winnings.csv")
  for (year in sort(unique(format(match$snapshot_date, "%Y"))))
    save_csv(match[format(match$snapshot_date, "%Y") == year, ], paste0("data/processed/vrs_match_inputs_", year, ".csv.gz"))
  status <- manifest |> transmute(source_id, category, source_path,
    processing_status = case_when(source_id %in% details$detail_source_id ~ "parsed_canonical_detail",
      category == "details" ~ "archived_noncanonical_version_or_duplicate",
      category == "standings" & snapshot_date >= as.Date("2024-01-01") ~ "parsed_standings",
      TRUE ~ "archived_reference"))
  save_csv(status, "data/file_processing_status.csv")
  message("Details: ", nrow(details), "; match contributions: ", nrow(match), "; winnings rows: ", nrow(win))
}
