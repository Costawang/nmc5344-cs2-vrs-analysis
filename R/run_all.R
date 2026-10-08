# Run from the project root. renv activates via .Rprofile.
args <- commandArgs(trailingOnly = TRUE)
if ("--figures-only" %in% args) {
  source("R/06_visualisation.R"); make_figures()
} else {
  if (!"--skip-collect" %in% args) {
    source("R/01_collect_data.R"); collect_data(update = "--update" %in% args)
  }
  source("R/02_parse_standings.R"); parse_standings()
  source("R/03_parse_details.R"); parse_details()
  source("R/04_clean_join.R"); clean_join()
  source("R/05_feature_engineering.R"); feature_engineering()
  source("R/07_validate.R"); validate_project()
  testthat::test_dir("tests", reporter = "summary")
  source("R/06_visualisation.R"); make_figures()
  source("R/08_write_findings.R"); write_findings()
}
