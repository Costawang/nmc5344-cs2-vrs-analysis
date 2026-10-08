source("R/helpers.R")
feature_engineering <- function() {
  x <- read_csv_project("data/processed/vrs_monthly_panel.csv")
  x <- x |> group_by(snapshot_date) |> mutate(n_ranked = n(), rank_percentile = 1 - (rank - 1) / (n() - 1)) |>
    ungroup() |> group_by(lineage_id) |> arrange(snapshot_date, .by_group = TRUE) |>
    mutate(top_5 = rank <= 5, top_10 = rank <= 10, top_20 = rank <= 20,
      previous_rank = lag(rank), previous_points = lag(points), previous_date = lag(snapshot_date),
      gap_days = as.integer(snapshot_date - previous_date), consecutive_month = month_index(snapshot_date) - lag(month_index(snapshot_date)) == 1,
      across_model_boundary = model_period != lag(model_period),
      rank_improvement = if_else(consecutive_month, previous_rank - rank, NA_integer_),
      point_change = if_else(consecutive_month & !across_model_boundary, points - previous_points, NA_real_)) |>
    ungroup()
  x$consecutive_top10_snapshots <- 0L
  for (id in unique(x$lineage_id)) {
    ii <- which(x$lineage_id == id); run <- 0L
    for (j in seq_along(ii)) {
      k <- ii[j]
      run <- if (!x$top_10[k]) 0L else if (j > 1 && isTRUE(x$consecutive_month[k])) run + 1L else 1L
      x$consecutive_top10_snapshots[k] <- run
    }
  }
  x <- x |> arrange(snapshot_date, rank)
  dates <- sort(unique(x$snapshot_date)); transitions <- list()
  for (i in 2:length(dates)) {
    a <- x |> filter(snapshot_date == dates[i - 1], top_10)
    b <- x |> filter(snapshot_date == dates[i], top_10)
    # Unresolved complete/partial roster identity affecting either top-ten set invalidates this estimate.
    unresolved <- any(c(a$identity_status, b$identity_status) %in% c("ambiguous_core_match", "incomplete_roster"))
    if (any(x$snapshot_date == dates[i] & x$identity_status == "ambiguous_core_match")) {
      links <- read_csv_project("data/processed/vrs_identity_links.csv")
      unresolved <- unresolved || any(links$sequence == "monthly" & links$current_date == dates[i] & links$previous_entry_id %in% a$entry_id & links$status == "ambiguous_core_match")
    }
    retained <- length(intersect(a$lineage_id, b$lineage_id))
    exact <- if (any(c(a$roster_size, b$roster_size) != 5)) NA_integer_ else length(intersect(a$roster_signature, b$roster_signature))
    transitions[[i - 1]] <- tibble(previous_date = dates[i - 1], snapshot_date = dates[i],
      retained_core = if (unresolved) NA_integer_ else retained, retention_rate = if (unresolved) NA_real_ else retained / 10,
      entrants = if (unresolved) NA_integer_ else 10L - retained,
      retained_exact_roster = exact, exact_roster_retention_rate = exact / 10,
      across_model_boundary = unique(a$model_period) != unique(b$model_period), identity_unresolved = unresolved)
  }
  trans <- bind_rows(transitions)
  membership <- expand_grid(lineage_id = unique(x$lineage_id), snapshot_date = dates) |>
    left_join(x |> select(lineage_id, snapshot_date, top_10), by = c("lineage_id", "snapshot_date")) |>
    mutate(top_10 = coalesce(top_10, FALSE)) |> group_by(lineage_id) |> arrange(snapshot_date, .by_group = TRUE) |>
    summarise(top10_entries = sum(top_10 & !lag(top_10), na.rm = TRUE),
              top10_exits = sum(!top_10 & lag(top_10), na.rm = TRUE), .groups = "drop")
  coverage <- x |> group_by(lineage_id) |> summarise(team_labels = paste(unique(team), collapse = " / "),
    display_team = last(team), first_date = min(snapshot_date), last_date = max(snapshot_date), observed_months = n(),
    months_top10 = sum(top_10), months_top20 = sum(top_20), longest_top10_run = max(consecutive_top10_snapshots),
    mean_rank = mean(rank), rank_sd = if (n() > 1) sd(rank) else NA_real_,
    average_absolute_rank_change = if (all(is.na(rank_improvement))) NA_real_ else mean(abs(rank_improvement), na.rm = TRUE),
    consecutive_pairs = sum(!is.na(rank_improvement)),
    monthly_coverage = n() / length(dates), .groups = "drop") |>
    mutate(volatility_eligible = observed_months >= 6 & consecutive_pairs >= 3) |>
    left_join(membership, by = "lineage_id") |> arrange(desc(months_top10), mean_rank)
  points_vol <- x |> group_by(lineage_id, model_period) |>
    summarise(observed_months = n(), points_sd = if (n() >= 3) sd(points) else NA_real_, .groups = "drop")
  # Three-calendar-month changes, not three arbitrarily spaced observations.
  prior <- x |> transmute(lineage_id, month = month_index(snapshot_date) + 3L, start_date = snapshot_date, start_rank = rank)
  changes <- x |> mutate(month = month_index(snapshot_date)) |> inner_join(prior, by = c("lineage_id", "month")) |>
    mutate(three_month_improvement = start_rank - rank) |> inner_join(coverage |> filter(volatility_eligible) |> select(lineage_id, observed_months, mean_rank), by = "lineage_id")
  rise <- changes |> arrange(desc(three_month_improvement), desc(observed_months), mean_rank, team) |> slice_head(n = 1) |> mutate(case = "Largest three-month rise")
  decline <- changes |> arrange(three_month_improvement, desc(observed_months), mean_rank, team) |> slice_head(n = 1) |> mutate(case = "Largest three-month decline")
  stable_id <- coverage |> filter(volatility_eligible, months_top10 > 0) |> arrange(average_absolute_rank_change, desc(observed_months), mean_rank, display_team) |> slice_head(n = 1) |> pull(lineage_id)
  stable <- x |> filter(lineage_id == stable_id) |> slice_tail(n = 1) |> mutate(case = "Most stable eligible elite lineage")
  cases <- bind_rows(rise, decline, stable)
  regions <- read_csv_project("data/processed/vrs_regions.csv")
  composition <- x |> filter(top_20, snapshot_date >= as.Date("2025-07-07")) |>
    select(entry_id, snapshot_date) |> left_join(regions |> select(-snapshot_date), by = "entry_id", relationship = "one-to-many") |>
    count(snapshot_date, region, name = "teams") |> mutate(share_of_top20 = teams / 20)
  comp <- x |> mutate(rank_group = cut(rank, breaks = c(0,10,20,50,Inf), labels = c("1-10","11-20","21-50","51+"))) |>
    pivot_longer(c(bounty_offered, bounty_collected, opponent_network, lan_wins_factor), names_to = "component", values_to = "value") |>
    group_by(model_period, rank_group, component) |> summarise(median = median(value), q25 = quantile(value, .25), q75 = quantile(value, .75), n = n(), .groups = "drop")
  save_csv(x, "data/processed/vrs_monthly_panel.csv")
  save_csv(trans, "output/tables/top10_transitions.csv")
  save_csv(coverage, "output/tables/lineage_summary.csv")
  save_csv(points_vol, "output/tables/points_volatility_by_period.csv")
  save_csv(cases |> select(case, lineage_id, team, snapshot_date, rank, any_of(c("start_date", "start_rank", "three_month_improvement"))), "output/tables/selected_cases.csv")
  save_csv(composition, "output/tables/regional_top20.csv")
  save_csv(comp, "output/tables/component_summary.csv")
  save_csv(x |> filter(!is.na(number_players_changed), number_players_changed > 0) |>
    select(entry_id, lineage_id, snapshot_date, team, rank, number_players_changed, roster_change, rank_improvement, across_model_boundary),
    "output/tables/roster_change_observations.csv")
}
