# Data dictionary

All CSV text is UTF-8; `.csv.gz` files are standard gzip-compressed CSV and can be read directly with `readr::read_csv()`. Blank cells mean missing/not applicable, never an automatic numeric zero. Dates are ISO `YYYY-MM-DD`; booleans are `TRUE`/`FALSE`. Numeric counts/ranks are integral even when R imports them as doubles. IDs are character strings.

**Observed** means transcribed from an official publication. **Derived** means computed by this project. **Provenance** means source or collection metadata. Units and identity conventions matter more than physical CSV storage types.

## Tables, units and keys

| Dataset | Row unit | Unique key and relationships |
| --- | --- | --- |
| `vrs_standings_long.csv` | Entry in one archived standings-file version | `source_id + rank`; includes global/regional, live/invitation and revisions |
| `vrs_global_snapshots.csv` | Canonical global entry on a date | `entry_id`; equivalent to `snapshot_id + rank` within this release |
| `vrs_monthly_panel.csv` | Canonical monthly invitation entry | `entry_id`; also `snapshot_date + lineage_id`; a subset of global entries with independently calculated monthly lineages |
| `vrs_rosters.csv` | One displayed player in a global entry | `entry_id + roster_slot`; `entry_id` references global entries |
| `vrs_regions.csv` | One official region assignment | `entry_id + region`; historic entries may have multiple regions |
| `vrs_team_details.csv` | Published scoring summary for a global entry | `entry_id`; `detail_source_id` references the manifest |
| `vrs_match_inputs_YYYY.csv.gz` | One displayed match contribution for a roster in a ranking snapshot | `entry_id + contribution_row`; files partition by **snapshot year**, not match year |
| `vrs_winnings.csv` | One selected prize contribution | `entry_id + winnings_row`; not a permanent event key |
| `vrs_identity_links.csv` | Candidate continuity link between sampled snapshots | `sequence + previous_entry_id + current_entry_id` |
| `source_manifest.csv` | Distinct source repository/path/blob version | `source_id`; two source paths can have identical bytes |

`entry_id` and snapshot IDs are reproducible within a source release, but can change when a corrected source version is selected. Neither these IDs nor the project's lineages are Valve-issued identifiers. The long source table must not be joined to other tables on team name alone.

## Standings and common identifiers

| Variables | Origin / type | Meaning |
| --- | --- | --- |
| `snapshot_date` | Observed / date | Date represented by the list, distinct from publication/collection |
| `rank` | Observed / integer | Position in the specified list; globally ranked in global/monthly tables |
| `points` | Observed / numeric | Published integer VRS points; do not assume cross-model comparability |
| `team` | Observed / text | Published team label, after display-markup cleanup |
| `roster` | Observed / text | Displayed comma-separated handles; can contain fewer than five players |
| `list_region` | Observed / text | `global`, `europe`, `americas` or `asia`, determined from the official list |
| `series` | Provenance / text | `invitation`, `live` or `legacy` according to publication path |
| `source_id` | Derived provenance / text | SHA-256 of repository, original path and Git blob identity |
| `snapshot_id` | Derived / text | Date plus a prefix of the selected global source ID |
| `entry_id` | Derived / text | Snapshot ID plus zero-padded published global rank |
| `roster_signature` | Derived / text | SHA-256 of sorted unique normalised player handles, joined by `|`; deterministic UTF-8 byte ordering |
| `roster_size` | Derived / integer | Number of unique normalised handles in the displayed roster |
| `detail_relative_link` | Observed provenance / text | Relative link published in the standings row |
| `commit_sha`, `source_path`, `source_local_path` | Provenance / text | Commit tree, original repository path and project-relative archived path |
| `first_seen_utc`, `last_seen_utc` | Provenance / timestamp | First/last inspected commit containing this path/blob; manifest retains original ISO offsets |
| `is_latest_revision` | Derived / boolean | Selected final version within date, series and list region |
| `canonical_global_source` | Derived / boolean | Whether this source is the canonical global source for its date |
| `model_period` | Derived / text | P1–P7 conservative analytical period; see methodology change log |

`region` and `regional_rank` in the separate regions table are observed official assignments and within-region positions. They are not inferred from player nationality or club headquarters. `player` in the roster table retains display spelling; `player_normalized` uses NFC, lowercase and trimming. `roster_slot` preserves display order, which has **no claimed gameplay-role meaning**.

## Detail summary

| Variables | Origin / type | Meaning |
| --- | --- | --- |
| `detail_source_id` | Provenance / text | Archived detail file used, resolved against the standings' exact Git tree |
| `final_rank_value` | Observed / numeric | Published one-decimal detailed rank value, distinct from rounded standings points |
| `starting_rank_value` | Observed / numeric | Published pre-head-to-head starting value |
| `h2h_adjustment` | Observed / numeric | Head-to-head adjustment; summary-level total here, per-row contribution in match tables |
| `bounty_offered` | Observed / numeric | Published Bounty Offered factor, not a monetary amount |
| `bounty_collected` | Observed / numeric | Published Bounty Collected factor |
| `opponent_network` | Observed / numeric | Published Opponent Network factor |
| `lan_wins_factor` | Observed / numeric | Published LAN Wins factor, **not a simple count of all LAN wins** |
| `detail_team`, `detail_roster`, `detail_global_rank` | Observed / text or integer | Independent detail-report fields retained to validate agreement with standings |

The global/monthly tables include these detail fields after a one-to-one join. The published relationship `final = starting + H2H` is checked within printed precision. Normalised component scales and ranking population can change over time.

## Match contribution and winnings tables

| Variables | Origin / type | Meaning |
| --- | --- | --- |
| `contribution_row` | Derived / integer | Row ordinal within a detail report; part of the project key |
| `match_id_local` | Observed / integer | Upstream calculation-local index; **not a stable cross-snapshot match ID** |
| `match_played` | Observed / integer | Published match-played ordinal in the roster report |
| `match_date` | Observed / date | Printed match date; upstream date formatting can use America/Los_Angeles |
| `opponent` | Observed / text | Displayed opponent label, not a permanent opponent-roster ID |
| `result` | Observed / text | `W` or `L`, from this roster's perspective |
| `age_weight`, `event_weight` | Observed / numeric | Printed contribution weights; `-` event weights become missing |
| `match_roster` | Observed / text | Participating roster listed for that match |
| `bounty_collected_raw`, `opponent_network_raw`, `lan_wins_raw` | Observed / numeric | Value outside parentheses in a displayed contribution cell |
| `bounty_collected_adjusted`, `opponent_network_adjusted`, `lan_wins_adjusted` | Observed / numeric | Corresponding value inside parentheses |
| `bounty_collected_reported`, `opponent_network_reported`, `lan_wins_reported` | Derived / boolean | Whether the source cell reports a contribution, rather than `-` |
| `winnings_row` | Derived / integer | Row ordinal in the selected winnings table |
| `event_date` | Observed / date | Printed event date, insufficient on its own to identify an event |
| `prize_winnings` | Observed / numeric | Printed dollar-denominated Prize Winnings amount with currency formatting removed; not total audited club revenue |
| `scaled_winnings` | Observed / numeric | Published scaled prize contribution |

These tables are inputs as displayed for ranking calculations. They repeat observations across snapshots and can include pre-2024 matches/events. A `-` contribution is missing/not selected, not necessarily zero or proof of an online match. Do not sum the full table as unique match totals or total team earnings.

## Identity and change measures

| Variables | Origin / type | Meaning |
| --- | --- | --- |
| `lineage_id` | Derived / text | Analytical core continuity, built separately for all snapshots and monthly sampling |
| `identity_status` | Derived / category | `baseline`, `new_lineage`, `mutual_unique_core`, `ambiguous_core_match`, `incomplete_roster`, or a documented override status |
| `previous_entry_id` | Derived / text | Accepted predecessor in the immediately previous sampled snapshot; missing when no link is accepted |
| `number_players_changed` | Derived / integer | Five minus shared players for complete rosters; same-name major replacements are candidates, not accepted continuity |
| `roster_similarity` | Derived / numeric | Jaccard shared/union player-set similarity for linked or same-name candidate pairs |
| `roster_change` | Derived / category | `unchanged`, `one_player`, `two_players`, `major_replacement_candidate`, or override-supported `major_replacement`; blank when not established |
| `sequence` | Derived / text | `all` or `monthly` linking procedure |
| `current_entry_id`, `previous_entry_id` | Derived / text | Candidate endpoints in the identity-link table |
| `current_date`, `previous_date` | Observed / date | Dates of candidate endpoints |
| `shared_players`, `jaccard_similarity` | Derived / integer or numeric | Candidate overlap count and overlap/union ratio |
| `both_complete` | Derived / boolean | Both candidate rosters contain five distinct handles |
| `accepted` | Derived / boolean | Candidate is the selected link |
| `status` | Derived / text | Current entry's identity status, including ambiguity |
| `team_label_changed` | Derived / boolean | Published organisation/team label differs across the candidate |

Unchanged exact player sets and continued three-player cores are different definitions of stability. A same-name major replacement starts a new lineage. A changed team label does not necessarily end a continuing player core. Incomplete and ambiguous rosters are not forced into links.

## Monthly panel features and summary tables

| Variables | Origin / type | Definition |
| --- | --- | --- |
| `n_ranked` | Derived / integer | Number of ranked global entries in that monthly snapshot |
| `rank_percentile` | Derived / numeric | `1 - (rank - 1)/(n_ranked - 1)`; best = 1, worst = 0 |
| `top_5`, `top_10`, `top_20` | Derived / boolean | Published global rank within each cutoff |
| `previous_rank`, `previous_points`, `previous_date` | Derived / numeric/date | Previous observation within the monthly lineage |
| `gap_days` | Derived / integer | Calendar-day separation of those observations |
| `consecutive_month` | Derived / boolean | Observations belong to adjacent calendar months |
| `across_model_boundary` | Derived / boolean | Prior/current model periods differ |
| `rank_improvement` | Derived / integer | Previous rank minus current rank; positive is improvement; adjacent months only |
| `point_change` | Derived / numeric | Current minus previous points; adjacent months within one period only |
| `consecutive_top10_snapshots` | Derived / integer | Current consecutive observed monthly Top 10 run, zero outside Top 10 |

`output/tables/top10_transitions.csv` records retained core members, retention rate (`retained_core / 10`), entrants (`10 - retained_core`), exact-roster retention and identity uncertainty. An unresolved relevant core produces missing core estimates. The headline core-versus-exact comparison uses the same evaluable transitions.

`lineage_summary.csv` records labels, date coverage, observed months, Top 10/20 months, longest run, mean/SD of full observed rank, mean absolute adjacent-month rank change, number of pairs and fraction of sampled months observed. Volatility eligibility requires six observed months and three adjacent pairs. Top 10 entry/exit counts are changes in observed membership; the first snapshot is left-censored. Missing ranks are never imputed. `points_volatility_by_period.csv` reports point SD only with at least three observations in one model period.

`selected_cases.csv` identifies maximum three-calendar-month rise/decline among volatility-eligible lineages and minimum mean absolute monthly change among eligible lineages that reached Top 10. `regional_top20.csv` contains mutually exclusive region counts and shares from July 2025. `component_summary.csv` contains medians, quartiles and observation counts by period/rank group/component. `roster_change_observations.csv` lists first observed changes and contemporaneous rank changes without causal claims.

## Provenance and validation metadata

The manifest additionally contains `repository`, `raw_url`, `file_type`, `category`, `series`, `collection_utc`, `commit_sha`, `blob_sha` (Git SHA-1 object ID), `sha256` (raw-file checksum), `size_bytes`, `local_path`, `in_pinned_tree`, `baseline_only`, `first_seen_commit`, `schema_version`, `collection_status` and `notes`. Paths are project-relative. `baseline_only` describes collection from the final pre-period baseline tree, not an observation to include in the 2024 analytical panel.

The snapshot catalog counts rows for each date/series/region/source version and records revision/canonical selection. `commit_history.csv` records inspected repository history; `file_processing_status.csv` records parsed versus archived reference/duplicate versions. Validation reports list each check, pass/fail and observed value; separate parser-error and identity-review files preserve issues explicitly.
