# Shared, intentionally small helpers. All paths are relative to the project root.
options(stringsAsFactors = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr)
  library(stringr); library(ggplot2)
})
read_csv_project <- function(path) readr::read_csv(path, show_col_types = FALSE, progress = FALSE,
                                                 guess_max = 100000, name_repair = "minimal")
save_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(x, path, na = "", progress = FALSE)
}
read_utf8 <- function(path) readLines(path, encoding = "UTF-8", warn = FALSE)
hash_text <- function(x) digest::digest(enc2utf8(x), algo = "sha256", serialize = FALSE)
file_hash <- function(path, algo = "sha256") {
  # readBin supports Windows UTF-8 paths; native fopen in digest may not.
  digest::digest(readBin(path, "raw", n = file.info(path)$size), algo = algo, serialize = FALSE)
}
git_blob_hash <- function(path) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  header <- c(charToRaw(paste0("blob ", length(bytes))), as.raw(0))
  digest::digest(c(header, bytes), algo = "sha1", serialize = FALSE)
}
clean_text <- function(x) {
  x <- gsub("<[^>]+>", "", x)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  stringr::str_squish(x)
}
player_set <- function(roster) {
  if (is.na(roster) || !nzchar(trimws(roster))) return(character())
  p <- stringi::stri_trans_nfc(tolower(trimws(strsplit(roster, ",", fixed = TRUE)[[1]])))
  sort(unique(p[nzchar(p)]), method = "radix")
}
roster_signature <- function(roster) hash_text(paste(player_set(roster), collapse = "|"))
numeric_value <- function(x) suppressWarnings(as.numeric(gsub("[^0-9.eE+-]", "", x)))
md_tables <- function(lines) {
  # Preserve empty cells; split only unescaped pipe delimiters.
  ix <- which(grepl("^\\s*\\|", lines))
  if (!length(ix)) return(list())
  blocks <- split(ix, cumsum(c(TRUE, diff(ix) > 1)))
  lapply(blocks, function(ii) {
    rows <- lapply(lines[ii], function(s) {
      s <- sub("^\\s*\\|", "", s); s <- sub("\\|\\s*$", "", s)
      trimws(strsplit(paste0(s, " "), "(?<!\\\\)\\|", perl = TRUE)[[1]])
    })
    if (length(rows) < 2) stop("Markdown table without separator")
    n <- length(rows[[1]])
    if (any(lengths(rows) != n)) stop("Inconsistent Markdown column count")
    body <- rows[-c(1, 2)]
    mat <- if (length(body)) do.call(rbind, body) else matrix(character(), nrow = 0, ncol = n)
    as_tibble(mat, .name_repair = "minimal") |> setNames(make.unique(rows[[1]]))
  })
}
git_lines <- function(repo, args) {
  err <- tempfile(tmpdir = "work", fileext = ".stderr")
  on.exit(unlink(err), add = TRUE)
  out <- system2("git", c("-c", "core.quotepath=false", "-c", "core.autocrlf=false", "-c", "core.eol=lf", shQuote(paste0("--git-dir=", repo)),
                         vapply(args, shQuote, character(1))), stdout = TRUE, stderr = err)
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0)
    stop(paste(read_utf8(err), collapse = "\n"))
  enc2utf8(out)
}
git_tree <- function(repo, sha) {
  lines <- git_lines(repo, c("ls-tree", "-rl", sha))
  m <- stringr::str_match(lines, "^[0-9]+ blob ([a-f0-9]+) +([0-9]+)\\t(.*)$")
  tibble(source_path = m[, 4], blob_sha = m[, 2], size_bytes = as.double(m[, 3])) |>
    filter(!is.na(source_path))
}
snapshot_date_in_file <- function(path, lines = NULL) {
  d <- str_extract(path, "20[0-9]{2}[_-][0-9]{2}[_-][0-9]{2}")
  if (is.na(d) && !is.null(lines)) d <- str_extract(paste(head(lines, 5), collapse = " "),
                                                  "20[0-9]{2}[_-][0-9]{2}[_-][0-9]{2}")
  as.Date(gsub("_", "-", d))
}
period_for <- function(date) {
  starts <- as.Date(c("2024-01-01", "2024-04-22", "2024-07-11", "2025-01-01",
                     "2025-02-24", "2025-07-07", "2025-09-01"))
  paste0("P", findInterval(as.numeric(as.Date(date)), as.numeric(starts)))
}
month_index <- function(date) as.integer(format(as.Date(date), "%Y")) * 12L + as.integer(format(as.Date(date), "%m"))
