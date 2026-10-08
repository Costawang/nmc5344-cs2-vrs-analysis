# Run from the project root: Rscript --vanilla R/00_setup.R
options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 120)
Sys.setenv(RENV_CONFIG_CACHE_ENABLED = "FALSE", RENV_CONFIG_SANDBOX_ENABLED = "FALSE")
dir.create("renv/bootstrap", recursive = TRUE, showWarnings = FALSE)
.libPaths(c(normalizePath("renv/bootstrap", winslash = "/"), .libPaths()))
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (!file.exists("renv/activate.R")) renv::init(bare = TRUE, restart = FALSE)
project_library <- file.path("renv/library", if (.Platform$OS.type == "windows") "windows" else R.version$platform,
                             paste0("R-", R.version$major, ".", strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1]),
                             R.version$platform)
dir.create(project_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(normalizePath(project_library, winslash = "/"), .libPaths()))
if (file.exists("renv.lock")) {
  renv::restore(library = normalizePath(project_library, winslash = "/"), prompt = FALSE)
  message("Recorded project dependencies restored.")
  quit(save = "no", status = 0)
}
packages <- c("dplyr", "tidyr", "readr", "purrr", "stringr", "ggplot2",
              "jsonlite", "digest", "testthat")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, lib = project_library,
  type = if (.Platform$OS.type == "windows") "binary" else "source")
if (!all(vapply(packages, requireNamespace, logical(1), quietly = TRUE))) stop("Missing required packages")
renv::snapshot(library = normalizePath(project_library, winslash = "/"), packages = c(packages, "renv"), prompt = FALSE)
message("Project dependencies ready.")
