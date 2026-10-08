source("R/helpers.R")
make_figures <- function() {
  previous_time_locale <- Sys.getlocale("LC_TIME")
  Sys.setlocale("LC_TIME", "C")
  on.exit(Sys.setlocale("LC_TIME", previous_time_locale), add = TRUE)
  x <- read_csv_project("data/processed/vrs_monthly_panel.csv")
  summaries <- read_csv_project("output/tables/lineage_summary.csv")
  transitions <- read_csv_project("output/tables/top10_transitions.csv")
  cases <- read_csv_project("output/tables/selected_cases.csv")
  cols <- c("#146C94", "#D66B37", "#679436", "#7B5EA7", "#2E8B83", "#A04E70")
  theme_set(theme_minimal(base_size = 11, base_family = "sans") +
    theme(plot.title = element_text(face = "bold", size = 16, colour = "#182B3A"),
          plot.subtitle = element_text(colour = "#496271", margin = margin(b = 12)),
          plot.caption = element_text(colour = "#607481", hjust = 0, size = 8),
          panel.grid.minor = element_blank(), legend.position = "bottom",
          plot.margin = margin(16, 18, 14, 14)))
  note <- "Source: Valve official monthly invitation standings. Analytical core lineages; descriptive comparisons."
  save_plot <- function(p, name, width = 11, height = 6) {
    ggsave(paste0("figures/", name, ".png"), p, width = width, height = height, dpi = 180, bg = "white")
    ggsave(paste0("figures/", name, ".pdf"), p, width = width, height = height, device = grDevices::cairo_pdf, bg = "white")
  }
  leaders <- summaries |> filter(months_top10 > 0) |> arrange(desc(months_top10), mean_rank) |> slice_head(n = 18)
  labels <- setNames(make.unique(paste0(leaders$team_labels, " (", leaders$months_top10, ")")), leaders$lineage_id)
  heat <- expand_grid(snapshot_date = sort(unique(x$snapshot_date)), lineage_id = leaders$lineage_id) |>
    left_join(x |> select(snapshot_date, lineage_id, rank), by = c("snapshot_date", "lineage_id")) |>
    mutate(top10_rank = ifelse(rank <= 10, rank, NA), label = factor(labels[lineage_id], levels = rev(unname(labels))))
  p <- ggplot(heat, aes(snapshot_date, label, fill = top10_rank)) +
    geom_tile(width = 25, height = .82) + scale_fill_gradient(low = "#146C94", high = "#BDE2E2", na.value = "#F0F2F4", breaks = c(1, 5, 10), name = "Top 10 rank") +
    scale_x_date(date_breaks = "3 months", date_labels = "%b\n%Y", expand = expansion(add = 18)) +
    labs(title = "Who stays in the CS2 top ten?", subtitle = "The 18 core lineages with the most Top 10 months; parentheses show total months",
         x = NULL, y = NULL, caption = paste(note, "Grey: outside Top 10 or not ranked.", sep = "\n")) + theme(panel.grid = element_blank())
  save_plot(p, "01_top10_membership", height = 8)
  p <- ggplot(transitions, aes(snapshot_date, retention_rate)) +
    geom_col(data = transitions |> filter(!is.na(retention_rate)), fill = cols[1], width = 22) +
    geom_point(aes(y = exact_roster_retention_rate), colour = cols[2], size = 2.3, na.rm = TRUE) +
    geom_text(data = transitions |> filter(is.na(retention_rate)), aes(y = .12, label = "N/A"), colour = "#607481", size = 3) +
    scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
    scale_x_date(date_breaks = "3 months", date_labels = "%b\n%Y") +
    labs(title = "Monthly continuity of the Top 10", subtitle = "Bars: core-lineage retention. Orange dots: exactly the same five-player roster.",
      x = NULL, y = "Share of previous month's Top 10 retained", caption = paste(note, "N/A: core identity unresolved; no zero retention is imputed.", sep = "\n"))
  save_plot(p, "02_top10_retention")
  selected <- x |> filter(lineage_id %in% cases$lineage_id) |> left_join(cases |> select(lineage_id, case) |> distinct(), by = "lineage_id", relationship = "many-to-many")
  selected <- selected |> mutate(case = paste0(case, ": ", summaries$team_labels[match(lineage_id, summaries$lineage_id)]))
  p <- ggplot(selected, aes(snapshot_date, rank, group = lineage_id)) + geom_line(colour = cols[1], linewidth = .8) +
    geom_point(colour = cols[1], size = 1.6) + geom_point(data = selected |> filter(number_players_changed > 0), shape = 21, fill = cols[2], colour = "white", size = 3) +
    scale_y_reverse() + scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") + facet_wrap(~case, scales = "free_y", ncol = 1) +
    labs(title = "Three reproducibly selected ranking trajectories", subtitle = "Orange markers: first observed roster changes. Rank 1 is at the top.",
         x = NULL, y = "Official global rank", caption = paste(note, paste(unique(selected$team), collapse = ", "), sep = "\n"))
  save_plot(p, "03_selected_trajectories", height = 9)
  vol <- summaries |> filter(volatility_eligible, months_top10 > 0) |> arrange(desc(average_absolute_rank_change)) |> slice_head(n = 16) |>
    mutate(label = paste0(team_labels, " (n=", observed_months, ")"))
  p <- ggplot(vol, aes(average_absolute_rank_change, reorder(label, average_absolute_rank_change))) + geom_col(fill = cols[1], width = .7) +
    labs(title = "Ranking volatility among lineages that reached the Top 10", subtitle = "At least six ranked months and three consecutive-month comparisons; n is ranked months",
         x = "Mean absolute monthly rank change", y = NULL, caption = paste(note, "Includes full observed ranks, not ranks truncated at 10.", sep = "\n"))
  save_plot(p, "04_rank_volatility", height = 7)
  regions <- read_csv_project("output/tables/regional_top20.csv")
  p <- ggplot(regions, aes(snapshot_date, teams, fill = region)) + geom_col(width = 23) +
    scale_fill_manual(values = c(americas = cols[2], asia = cols[3], europe = cols[1]), labels = c(americas = "Americas", asia = "Asia", europe = "Europe")) +
    scale_x_date(date_breaks = "3 months", date_labels = "%b\n%Y") +
    labs(title = "Regional representation in the global Top 20", subtitle = "Starts with July 2025, after the switch to one regional list per roster",
         x = NULL, y = "Top 20 entries", fill = NULL, caption = note)
  save_plot(p, "05_regional_composition")
  focus <- summaries |> filter(months_top10 > 0) |> slice_head(n = 6) |> pull(lineage_id)
  comp <- x |> filter(lineage_id %in% focus) |> mutate(team_label = summaries$team_labels[match(lineage_id, summaries$lineage_id)])
  periods <- comp |> group_by(model_period) |> summarise(label = paste0(first(model_period), ": ", format(min(snapshot_date), "%b %Y"), " - ", format(max(snapshot_date), "%b %Y")), .groups = "drop")
  period_labels <- setNames(periods$label, periods$model_period)
  p <- ggplot(comp, aes(snapshot_date, points, colour = team_label, group = interaction(lineage_id, model_period))) +
    geom_line(linewidth = .6) + geom_point(size = 1.2) + facet_wrap(~model_period, scales = "free_x", ncol = 2, labeller = as_labeller(period_labels)) +
    scale_colour_manual(values = cols) + scale_x_date(date_breaks = "3 months", date_labels = "%b %y") +
    labs(title = "Published VRS points within model periods", subtitle = "Six lineages with the most Top 10 months. No line crosses a model-period boundary.",
         x = NULL, y = "Published points", colour = NULL, caption = paste(note, "Panels do not establish score comparability across periods.", sep = "\n"))
  save_plot(p, "06_points_by_period", height = 8)
  comp <- x |> filter(model_period == max(model_period)) |>
    mutate(rank_group = factor(ifelse(rank <= 10, "Top 10", ifelse(rank <= 20, "11-20", "21+")), levels = c("Top 10", "11-20", "21+"))) |>
    pivot_longer(c(bounty_offered, bounty_collected, opponent_network, lan_wins_factor), names_to = "component", values_to = "value")
  p <- ggplot(comp, aes(rank_group, value, fill = rank_group)) + geom_boxplot(outlier.alpha = .15, width = .55) +
    facet_wrap(~component, ncol = 2, labeller = as_labeller(c(bounty_offered = "Bounty Offered", bounty_collected = "Bounty Collected", opponent_network = "Opponent Network", lan_wins_factor = "LAN Wins factor"))) + scale_fill_manual(values = cols[1:3]) +
    labs(title = "VRS component distributions by rank group", subtitle = "Latest model period only; repeated roster snapshots are descriptive observations",
         x = NULL, y = "Published component value", caption = "Components are inputs to VRS itself. Separation is not an independent causal explanation of rank.") + theme(legend.position = "none")
  save_plot(p, "07_component_distributions", height = 7)
}
