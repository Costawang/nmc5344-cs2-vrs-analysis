withr::local_dir("..")
source("R/helpers.R")
source("R/04_clean_join.R")

testthat::test_that("Markdown preserves missing contributions and empty trailing cells", {
  t <- md_tables(c("| A | B | |", "| :- | -: | :- |", "| alpha | - | |"))[[1]]
  testthat::expect_equal(ncol(t), 3)
  testthat::expect_equal(t[[2]], "-")
  testthat::expect_equal(t[[3]], "")
  testthat::expect_error(md_tables(c("| A | B |", "| :- | -: |", "| a | b | c |")), "column")
})

testthat::test_that("roster signatures ignore ordering and case, not punctuation", {
  testthat::expect_equal(roster_signature("NiKo, Snax, a, b, c"), roster_signature("c, a, b, SNAX, niko"))
  testthat::expect_false(roster_signature("a-, b, c, d, e") == roster_signature("a, b, c, d, e"))
  testthat::expect_equal(length(player_set("a, b, c")), 3)
})

testthat::test_that("identity links distinguish unchanged, minor, major and partial rosters", {
  g <- tibble(snapshot_date = rep(as.Date(c("2025-01-06", "2025-02-03")), each = 4),
    rank = rep(1:4, 2), entry_id = paste0("e", 1:8), team = rep(c("A", "B", "C", "D"), 2),
    roster = c("a,b,c,d,e", "f,g,h,i,j", "k,l,m,n,o", "p,q,r,s,t",
               "e,d,c,b,a", "f,g,h,i,x", "u,v,w,y,z", "p,q,r,s"))
  y <- link_sequence(g, "test")$data
  testthat::expect_equal(y$lineage_id[1], y$lineage_id[5])
  testthat::expect_equal(y$number_players_changed[6], 1L)
  testthat::expect_equal(y$roster_change[7], "major_replacement_candidate")
  testthat::expect_false(y$lineage_id[3] == y$lineage_id[7])
  testthat::expect_equal(y$identity_status[8], "incomplete_roster")
  testthat::expect_true(is.na(y$number_players_changed[8]))
})

testthat::test_that("ambiguous cores are not forcibly linked", {
  g <- tibble(snapshot_date = as.Date(c("2025-01-06", "2025-01-06", "2025-02-03")),
    rank = c(1L, 2L, 1L), entry_id = c("p1", "p2", "c1"), team = c("A", "B", "C"),
    roster = c("a,b,c,d,e", "a,b,c,f,g", "a,b,c,x,y"))
  y <- link_sequence(g, "test")$data
  testthat::expect_equal(y$identity_status[3], "ambiguous_core_match")
  testthat::expect_true(is.na(y$previous_entry_id[3]))
})

testthat::test_that("model periods separate known changes and dates stay real", {
  testthat::expect_false(period_for("2025-02-03") == period_for("2025-03-03"))
  testthat::expect_equal(month_index(as.Date("2026-01-05")) - month_index(as.Date("2025-12-01")), 1L)
  testthat::expect_equal(snapshot_date_in_file("standings_global_2026_10_05.md"), as.Date("2026-10-05"))
})
