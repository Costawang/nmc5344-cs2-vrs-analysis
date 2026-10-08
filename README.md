# CS2 Valve Regional Standings: a longitudinal exploration

An R-based NUS NMC5344 *Coding for Communicators* project using official Valve publications. The project archives available 2024–2026 standings, builds tidy datasets, and explores elite persistence, ranking mobility and roster continuity.

Start with [exploratory findings](analysis/FINDINGS.md), [Chinese interpretation](analysis/FINDINGS.zh-CN.md), and the [analysis options](analysis/ANALYSIS_IDEAS.md). This repository provides research materials and preliminary interpretation, not a finished course report.

## Sources and coverage

- [Valve regional standings](https://github.com/ValveSoftware/counter-strike_regional_standings): live/invitation rankings, roster details, model code and historical versions.
- [Valve rules and regulations](https://github.com/ValveSoftware/counter-strike_rules_and_regs): tournament operation requirements, Major rules and exceptions.

The investigated release ends on **2026-10-05**. The first recoverable 2024 regional snapshot is **2024-03-04**; the first global snapshot with details is **2024-04-22**. The primary panel uses **27 monthly invitation snapshots from 2024-08-06 through 2026-10-05**. Additional live and historical snapshots are retained separately. January and February 2024 are not filled with invented observations.

The exact source revisions and collection timestamp are in [`config/source_lock.json`](config/source_lock.json). Reproduction uses these fixed commits, not a moving `main` branch. Coverage is recorded in [`data/snapshot_catalog.csv`](data/snapshot_catalog.csv).

## Main datasets

| File in `data/processed/` | Unit of observation |
| --- | --- |
| `vrs_standings_long.csv` | A row in an official list and archived file version, including revisions and live/invitation duplicates |
| `vrs_global_snapshots.csv` | One canonical global ranking entry per snapshot |
| `vrs_monthly_panel.csv` | One monthly invitation entry with analytical core-lineage links and derived variables |
| `vrs_rosters.csv` | One displayed player in a canonical global entry |
| `vrs_regions.csv` | One official regional assignment of a canonical entry; historical membership can be multiple |
| `vrs_team_details.csv` | One entry's published scoring components |
| `vrs_match_inputs_YYYY.csv.gz` | A match contribution as shown for one roster in one ranking snapshot |
| `vrs_winnings.csv` | One displayed prize contribution row, without an invented permanent event ID |
| `vrs_identity_links.csv` | A candidate or accepted link between consecutive snapshots |

See the [data dictionary](analysis/DATA_DICTIONARY.md). Direct observations are distinguished from derived variables. A `Match ID` is local to a calculation, not a permanent match identifier. A roster signature is created by this project, not assigned by Valve.

## Reproduce

Requirements: R (the recorded environment uses 4.6.1), Git on PATH, and access to GitHub and CRAN. Open the `.Rproj` or run commands from the project root.

```r
# In a new clone, install/restore the recorded R environment:
install.packages("renv", repos = "https://cloud.r-project.org")
renv::restore(prompt = FALSE)
```

```sh
# Download official Git history at the locked commits, archive source bytes,
# parse, link, validate, test, plot and regenerate findings:
Rscript R/run_all.R

# Re-run using the already collected local raw files and Git mirrors:
Rscript R/run_all.R --skip-collect

# Regenerate only figures from the published processed data:
Rscript R/run_all.R --figures-only

# Optional: after a successful full run, re-parse and verify byte-identical
# observed detail/match tables in a fresh session, then rebuild analysis:
Rscript R/09_check_reproduction.R
```

`Rscript --vanilla R/00_setup.R` is an alternative first-time dependency bootstrap that restores an existing lockfile. `renv.lock` is authoritative for reproducing this release. The Windows workflow uses binary CRAN packages. The project disables renv's package-library sandbox and shared cache to keep dependencies in the project; this does not change operating-system security settings.

To intentionally update the source release, run `Rscript R/run_all.R --update`. This refreshes official refs and rewrites the source lock and derived results. Review resulting changes before publishing. Merely reproducing does not update the source cutoff.

## Files and provenance

`R/` contains the pipeline, `config/` its source lock and identity overrides, `data/` the manifest and processed tables, `analysis/` the research interpretation, `figures/` PNG/PDF plots, and `output/` numerical summaries and validation results. `docs/` records source and methodology history.

Raw files live locally under `data/raw/`; official Git mirrors and temporary extraction files live under `work/`. These directories are deliberately excluded from Git. The [manifest](data/source_manifest.csv) identifies each distinct path/blob version, pinned raw URL, commit, first/last observation in the inspected history, file size, SHA-256 and relative local path. The retrieval script reconstructs them. Multiple paths can contain identical official bytes.

The public repository includes processed data, provenance, scripts, figures and documentation. It uses compressed CSV for match-contribution tables and does not require Git LFS. All code uses relative project paths; no access tokens or local machine paths belong in the repository.

## Research questions and limitations

The main questions are how persistent the Top 10 is, which core lineages have stable or volatile ranks, and which representative trajectories illustrate mobility. [Methodology notes](analysis/METHODOLOGY_NOTES.md) explain sample selection, identity matching, missing data and validation.

Important changes include the April 2024 ranking revision, ranked-event filtering from 2025, the February 2025 eligibility/prize changes, June 2025 regional reassignment, and August 2025 prize-stage/active-roster changes. See the [change log](docs/METHODOLOGY_CHANGELOG.md).

Raw points are not assumed to be comparable across those changes. Published rank and Top-N membership remain relative measures, and can also be affected by rules and field size. Roster-change observations are descriptive associations, not causal effects. Missing rankings are not zero scores or evidence of a team disbanding. Incomplete active rosters are preserved and excluded from forced identity matching.

## Ethics, attribution and reuse

Collection is programmatic retrieval of public official Git repository contents, not scraping HLTV or other third-party websites. Valve's reports attribute event data to HLTV.org; this attribution is retained in local raw files and source notes. Only public esports results and published handles are used. No private profile enrichment is performed.

The upstream repositories did not expose a repository-wide license in the inspected metadata. Upstream code and data are not relicensed by this project. Raw archives remain local; consult the upstream sources and applicable terms for reuse. These preliminary interpretations were prepared with coding-assistant support and should be checked and rewritten by the student for assessed coursework.

## Validation

[`output/validation/checks.csv`](output/validation/checks.csv) reports data-contract, cross-table and raw-integrity checks. Parser failures are never silently discarded. Identity ambiguities appear in `output/validation/identity_review.csv`. Tests exercise roster continuity, ambiguous cores, missing contribution cells and method-period boundaries.
