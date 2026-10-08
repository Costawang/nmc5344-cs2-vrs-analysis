source("R/helpers.R")
write_findings <- function() {
  x <- read_csv_project("data/processed/vrs_monthly_panel.csv")
  g <- read_csv_project("data/processed/vrs_global_snapshots.csv")
  manifest <- read_csv_project("data/source_manifest.csv")
  transitions <- read_csv_project("output/tables/top10_transitions.csv")
  summary <- read_csv_project("output/tables/lineage_summary.csv")
  cases <- read_csv_project("output/tables/selected_cases.csv")
  regions <- read_csv_project("output/tables/regional_top20.csv")
  checks <- read_csv_project("output/validation/checks.csv")
  top <- head(summary, 5)
  latest_date <- max(x$snapshot_date); latest <- x |> filter(snapshot_date == latest_date) |> arrange(rank) |> slice_head(n = 10)
  full <- mean(transitions$retention_rate, na.rm = TRUE)
  exact <- mean(transitions$exact_roster_retention_rate[!is.na(transitions$retention_rate)], na.rm = TRUE)
  exact_all <- mean(transitions$exact_roster_retention_rate, na.rm = TRUE)
  within <- mean(transitions$retention_rate[!transitions$across_model_boundary], na.rm = TRUE)
  table_md <- function(headers, rows) c(paste0("| ", paste(headers, collapse = " | "), " |"),
     paste0("| ", paste(rep("---", length(headers)), collapse = " | "), " |"),
     apply(as.matrix(rows), 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
  top_table <- table_md(c("Lineage labels", "Top 10 months", "Longest run", "Ranked months"),
    top |> select(team_labels, months_top10, longest_top10_run, observed_months))
  latest_table <- table_md(c("Rank", "Team", "Points", "Roster"), latest |> select(rank, team, points, roster))
  case_table <- table_md(c("Selection", "Team", "Start rank", "End rank", "Three-month improvement"),
    cases |> transmute(case, team, start_rank = ifelse(is.na(start_rank), "n/a", start_rank), rank,
                      three_month_improvement = ifelse(is.na(three_month_improvement), "n/a", three_month_improvement)))
  dates_text <- paste0(min(x$snapshot_date), " to ", max(x$snapshot_date))
  en <- c("# Exploratory findings", "", paste0("Official monthly invitation standings: **", dates_text, "**. This is an exploratory research note, not a finished course report."), "",
    "## What was actually collected", "",
    sprintf("The archive contains %s distinct source path/blob versions. The canonical global dataset contains %s roster-snapshot observations across %s dates; the primary monthly panel contains %s observations across %s months.",
      format(nrow(manifest), big.mark = ","), format(nrow(g), big.mark = ","), n_distinct(g$snapshot_date), format(nrow(x), big.mark = ","), n_distinct(x$snapshot_date)), "",
    "The earliest regional snapshot recovered is 2024-03-04. The global panel begins on 2024-04-22. No January or February 2024 ranking observation has been invented. Raw files and historical revisions are preserved locally; the public repository contains provenance and retrieval scripts.", "",
    "## 1. How persistent is the Top 10?", "",
    sprintf("Across %s evaluable consecutive-month transitions, the mean Top 10 core-lineage retention rate is **%.1f%%**. The exact-roster retention rate is **%.1f%%**. Core continuity tolerates one- or two-player changes under the documented mutual-match rule; the exact-roster comparison requires an unchanged displayed player set.",
      sum(!is.na(transitions$retention_rate)), full * 100, exact * 100), "",
    sprintf("Excluding transitions across the project's broad model-period boundaries, mean core retention is **%.1f%%**. This is a sensitivity comparison, not a claim that all remaining observations are perfectly comparable.", within * 100), "",
    sprintf("Both headline rates use the same evaluable transitions. %s of %s transitions have unresolved core identity and are excluded. Across all transitions with complete displayed rosters, exact-roster retention is %.1f%%. Missing core estimates are not zero retention.", sum(is.na(transitions$retention_rate)), nrow(transitions), exact_all * 100), "",
    "The gap between the two measures shows why roster identity changes the interpretation of 'stability'. A change in a displayed lineup does not necessarily mean a new organisation or a departure from the elite tier. Labels such as HEROIC / Falcons refer to a linked player core across organisations, not one club's uninterrupted history.", "",
    top_table, "", "![Top 10 membership](../figures/01_top10_membership.png)", "",
    "## 2. Ranking mobility and selected cases", "",
    "Volatility uses the full published rank, not a Top-10-censored rank. Eligibility requires six ranked months and at least three adjacent-month comparisons. The denominator and observation count accompany every summary. A missing ranking is not assigned zero or a synthetic last place.", "",
    case_table, "",
    "The rise and decline cases are selected by three-calendar-month rank changes among eligible lineages. The stable case is selected from lineages that reached the Top 10. Different starting ranks and unequal coverage limit direct comparisons; these are illustrations, not population-wide causal findings.", "",
    "![Rank volatility](../figures/04_rank_volatility.png)", "",
    "## 3. Regional representation and components", "",
    "Regional Top 20 charts start in July 2025, after the change to one regional assignment. Earlier multi-region eligibility remains in the underlying tables, but is not summed into an apparently mutually exclusive regional composition.", "",
    "Component distributions are restricted to the latest model period. Bounty, network and LAN components are inputs to the ranking formula itself. Their association with rank is a description of the model's construction, not independent evidence that increasing one component causes a particular ranking improvement.", "",
    "## Latest published Top 10", "", paste0("Snapshot: ", latest_date, ". Points are displayed for this date only."), "", latest_table, "",
    "## What these data cannot establish", "",
    "- The causal effect of a transfer, coaching decision, organisational budget or tournament access.",
    "- A complete independent match-results archive: detail rows repeat across snapshots, and Match ID is local to each calculation.",
    "- A common absolute skill scale for raw points across model changes.",
    "- True transfer dates: roster-change markers indicate the first observed published change.",
    "- Exact replication of Valve's full ranking computation without its complete underlying input data.", "",
    "## Best short-report route", "",
    "Use Top 10 persistence as the central question, ranking mobility as the supporting comparison, and one or two automatically selected trajectories as illustrations. Keep regional composition or component analysis as a substitute extension rather than adding every topic to a 1,000-word report.", "",
    "These preliminary interpretations were generated with coding-assistant support. The student should check the evidence and rewrite the final course interpretation in their own words. Numerical results are reproduced by R/08_write_findings.R.")
  zh <- c("# 探索性解读", "", paste0("主分析区间：", dates_text, "，采用官方月度 invitation 全球榜。本文件是初步研究笔记，不是完整课程报告。"), "",
    sprintf("已归档 %s 个不同源路径／内容版本。全球主表含 %s 行、%s 个日期；月度面板含 %s 行、%s 个月。", format(nrow(manifest), big.mark = ","), format(nrow(g), big.mark = ","), n_distinct(g$snapshot_date), format(nrow(x), big.mark = ","), n_distinct(x$snapshot_date)), "",
    "## 最值得写的发现", "",
    sprintf("相邻月份的 Top 10 核心阵容平均保留率为 **%.1f%%**；如果必须保持完全相同的公布名单，保留率为 **%.1f%%**。二者衡量不同层次的稳定性：一两名选手改变后，队伍仍可能延续在精英层。", full * 100, exact * 100), "",
    sprintf("排除本项目划分的方法时期断点后，核心阵容平均保留率为 **%.1f%%**。这个比较用来检查结论对规则变化是否敏感，不代表其余时期完全没有口径问题。", within * 100), "", top_table, "",
    sprintf("上述两个保留率使用相同的 %s 组可判断比较；另有 %s 组因核心身份存在歧义而排除。所有完整名单比较的严格名单保留率为 %.1f%%。HEROIC / Falcons 等合并标签表示选手核心的延续，不等同于俱乐部历史。", sum(!is.na(transitions$retention_rate)), sum(is.na(transitions$retention_rate)), exact_all * 100), "",
    "![Top 10 时间线](../figures/01_top10_membership.png)", "",
    "## 如何读波动和轨迹", "",
    "波动使用全部实际名次，不把第十名以外的排名截断。至少上榜六个月、具有三组相邻月份比较的阵容才进入波动排序；每个结果同时给出观测月份数。未上榜不能当作零分、最后一名或解散。", "", case_table, "",
    "上升与下降案例按三个月名次变化自动筛选；稳定案例从曾进入 Top 10 的阵容中选择。这些案例用于说明总体格局，不用于证明换人、管理或训练产生了因果效果。橙色阵容变化标记只是首次在榜单中观察到变化的时间。", "",
    "地区构成图从 2025 年 7 月开始，避免把此前可同时归属多个地区的队伍重复算入互斥比例。分项图只比较最新模型时期；分项本来就参与积分公式，相关性不能被写成独立的成功原因。", "",
    "## 适合课程短报告的组织方式", "",
    "1. 用 Top 10 稳定性提出核心问题。", "2. 用名次波动解释不同阵容的差异。", "3. 用一至两个可复现筛选的上升、下降或稳定案例帮助读者理解。", "",
    "不要把全部六个分析方向塞进约 1000 词报告。地区或分项分析可以替换其中一个补充角度。", "",
    "## 必须保留的限制", "",
    "2024 年 1–2 月缺少新的官方快照；最早全球榜为 4 月 22 日。原始积分不能跨模型版本直接当作同一绝对能力尺度。Match ID 不是跨快照永久编号，同场比赛的贡献会重复出现。2025 年 8 月后不足五人的公布名单不能自动解释成转会。", "",
    "这些解读由真实数据与脚本生成，属于辅助研究笔记；后续课程写作应由你核对证据并形成自己的表述。")
  writeLines(enc2utf8(en), "analysis/FINDINGS.md", useBytes = TRUE)
  writeLines(enc2utf8(zh), "analysis/FINDINGS.zh-CN.md", useBytes = TRUE)
  jsonlite::write_json(list(source_versions = nrow(manifest), global_rows = nrow(g), global_dates = n_distinct(g$snapshot_date),
    monthly_rows = nrow(x), monthly_dates = n_distinct(x$snapshot_date), latest_date = as.character(latest_date),
    mean_core_retention = full, mean_exact_retention_same_transitions = exact, mean_exact_retention_all_complete_transitions = exact_all,
    evaluable_core_transitions = sum(!is.na(transitions$retention_rate)), excluded_core_transitions = sum(is.na(transitions$retention_rate)), within_period_core_retention = within,
    validation_checks = nrow(checks), all_checks_passed = all(checks$passed)), "output/tables/project_summary.json", auto_unbox = TRUE, pretty = TRUE)
}
