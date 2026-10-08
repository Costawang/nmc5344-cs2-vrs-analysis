source("R/helpers.R")

link_sequence <- function(g, sequence_name) {
  g <- g |> arrange(snapshot_date, rank)
  g$lineage_id <- NA_character_; g$identity_status <- NA_character_
  g$previous_entry_id <- NA_character_; g$number_players_changed <- NA_integer_
  g$roster_similarity <- NA_real_; g$roster_change <- NA_character_
  links <- list(); dates <- sort(unique(g$snapshot_date))
  overrides <- readr::read_csv("config/identity_overrides.csv", col_types = "ccccc", show_col_types = FALSE)
  for (d in seq_along(dates)) {
    ci <- which(g$snapshot_date == dates[d]); curr <- lapply(g$roster[ci], player_set)
    g$lineage_id[ci] <- paste0(sequence_name, "_", g$entry_id[ci])
    g$identity_status[ci] <- ifelse(lengths(curr) == 5, if (d == 1) "baseline" else "new_lineage", "incomplete_roster")
    if (d == 1) next
    pi <- which(g$snapshot_date == dates[d - 1]); prev <- lapply(g$roster[pi], player_set)
    # Inverted player index avoids comparing every nickname against every pair.
    pindex <- split(rep(seq_along(prev), lengths(prev)), unlist(prev, use.names = FALSE))
    overlap <- matrix(0L, length(prev), length(curr))
    for (j in seq_along(curr)) {
      hits <- table(unlist(pindex[intersect(curr[[j]], names(pindex))], use.names = FALSE))
      if (length(hits)) overlap[as.integer(names(hits)), j] <- as.integer(hits)
    }
    eligible <- overlap
    eligible[lengths(prev) != 5, ] <- 0L; eligible[, lengths(curr) != 5] <- 0L
    for (j in seq_along(curr)) {
      best <- max(eligible[, j]); candidates <- which(eligible[, j] == best)
      chosen <- NA_integer_; method <- "no_core_match"
      if (best >= 3) {
        if (length(candidates) == 1 && sum(eligible[candidates, ] == max(eligible[candidates, ])) == 1 && best == max(eligible[candidates, ])) {
          chosen <- candidates; method <- "mutual_unique_core"
        } else g$identity_status[ci[j]] <- "ambiguous_core_match"
      }
      ov <- overrides |> filter(current_entry_id == g$entry_id[ci[j]], previous_entry_id %in% g$entry_id[pi])
      if (nrow(ov)) {
        if (nrow(ov) != 1 || !ov$action %in% c("link", "break") || !nzchar(ov$evidence_url)) stop("Invalid identity override")
        if (ov$action == "link") { chosen <- match(ov$previous_entry_id, g$entry_id[pi]); method <- "documented_override" }
        else { chosen <- NA_integer_; method <- "documented_break" }
      }
      name_candidates <- which(tolower(g$team[pi]) == tolower(g$team[ci[j]]))
      if (!is.na(chosen)) {
        p <- pi[chosen]; c <- ci[j]; n <- overlap[chosen, j]
        g$lineage_id[c] <- g$lineage_id[p]; g$previous_entry_id[c] <- g$entry_id[p]
        g$identity_status[c] <- method; g$number_players_changed[c] <- 5L - n
        g$roster_similarity[c] <- n / (10L - n)
        g$roster_change[c] <- c("unchanged", "one_player", "two_players", "major_replacement", "major_replacement", "major_replacement")[6L - n]
      } else if (length(name_candidates) == 1 && lengths(curr)[j] == 5 && lengths(prev)[name_candidates] == 5 && overlap[name_candidates, j] <= 2) {
        g$roster_change[ci[j]] <- "major_replacement_candidate"
        g$number_players_changed[ci[j]] <- 5L - overlap[name_candidates, j]
        g$roster_similarity[ci[j]] <- overlap[name_candidates, j] / (10L - overlap[name_candidates, j])
      }
      # Record candidates with >=3 shared players, plus same-name replacement candidates.
      keep <- union(which(overlap[, j] >= 3), name_candidates)
      if (length(keep)) links[[length(links) + 1L]] <- tibble(sequence = sequence_name,
        previous_entry_id = g$entry_id[pi[keep]], current_entry_id = g$entry_id[ci[j]],
        previous_date = dates[d - 1], current_date = dates[d], shared_players = overlap[keep, j],
        jaccard_similarity = overlap[keep, j] / (lengths(prev)[keep] + lengths(curr)[j] - overlap[keep, j]),
        both_complete = lengths(prev)[keep] == 5 & lengths(curr)[j] == 5,
        accepted = !is.na(chosen) & keep == chosen,
        status = g$identity_status[ci[j]], team_label_changed = g$team[pi[keep]] != g$team[ci[j]])
    }
    accepted_ids <- na.omit(g$previous_entry_id[ci])
    if (anyDuplicated(accepted_ids)) stop("An identity override created a many-to-one lineage")
  }
  list(data = g, links = bind_rows(links))
}

clean_join <- function() {
  g <- read_csv_project("data/processed/vrs_global_snapshots.csv")
  details <- read_csv_project("data/processed/vrs_team_details.csv")
  g <- g |> left_join(details |> select(-snapshot_date), by = "entry_id", relationship = "one-to-one")
  all_linked <- link_sequence(g, "all")
  monthly <- link_sequence(g |> filter(series == "invitation"), "monthly")
  save_csv(all_linked$data, "data/processed/vrs_global_snapshots.csv")
  save_csv(monthly$data, "data/processed/vrs_monthly_panel.csv")
  save_csv(bind_rows(all_linked$links, monthly$links), "data/processed/vrs_identity_links.csv")
  rosters <- g |> select(entry_id, snapshot_date, team, roster, roster_signature, roster_size) |>
    mutate(player = strsplit(roster, ",", fixed = TRUE)) |> unnest_longer(player) |>
    mutate(player = trimws(player), player_normalized = stringi::stri_trans_nfc(tolower(player))) |>
    group_by(entry_id) |> mutate(roster_slot = row_number()) |> ungroup() |> select(-roster)
  save_csv(rosters, "data/processed/vrs_rosters.csv")
  save_csv(monthly$data |> filter(identity_status %in% c("ambiguous_core_match", "incomplete_roster")) |>
             select(entry_id, snapshot_date, team, rank, roster, identity_status), "output/validation/identity_review.csv")
}
