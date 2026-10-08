# Official source inventory

This release freezes two official Valve repositories. The exact cutoffs are recorded in [the source lock](../config/source_lock.json), and every archived path/content version is listed in [the manifest](../data/source_manifest.csv).

| Repository | Pinned commit | Material retained |
| --- | --- | --- |
| [Regional standings](https://github.com/ValveSoftware/counter-strike_regional_standings/tree/eec4853d7bcf0f1f7efe7f0d901234bef7e98b75) | `eec4853d7bcf0f1f7efe7f0d901234bef7e98b75` | Standings, roster details, model code, sample inputs, README and model-fit image |
| [Rules and regulations](https://github.com/ValveSoftware/counter-strike_rules_and_regs/tree/621b7d91b0a236044aed62a357fddc863dfaea49) | `621b7d91b0a236044aed62a357fddc863dfaea49` | Tournament operation requirements and exceptions, Major supplemental rulebook, declaration document |

## What “all relevant” means

The collector inspects every mainline commit from 2024-01-01 through the pinned commit, plus the final pre-2024 tree for context. It archives every distinct relevant **path + Git blob** encountered. It does not collect unmerged branches, issues, pull-request discussion or third-party websites. A complete official Git mirror is retained locally as an additional recovery source.

The manifest preserves final and superseded versions, including the September 2026 correction. `first_seen_utc` and `last_seen_utc` refer to the inspected commit trees, not necessarily the original creation date of a file that predates the inspection window. These fields contain ISO 8601 commit timestamps with their recorded offsets; they describe instants, despite the `_utc` field suffix. The collection timestamp itself is UTC.

Only the latest tree's excluded paths are listed in `data/source_exclusions.csv`: Git ignore configuration and tournament item-submission guidelines, which are not ranking inputs or relevant ranking interpretation rules. Unknown detail schemas trigger explicit parser errors. Archived reference files and unselected duplicate/revision details are distinguished in `data/file_processing_status.csv`; they are not silently dropped.

## Standings and publication schedule

The first recovered 2024 publication is 2024-03-04, with three regional lists and no global list. Global lists and linked details begin on 2024-04-22. There is no new January or February 2024 snapshot in the inspected official history. A ranking's look-back inputs can nevertheless precede its snapshot year.

Historical top-level standings and details were overwritten in place. Later files use dated directories. The present `live/YYYY/YYYY-MM-DD/` and `invitation/YYYY/YYYY-MM-DD/` trees begin in August 2024; older publications are recovered from Git history. A dated path's first appearance can be later than its represented date.

The canonical global release has 56 distinct dates. The main analytical panel uses 27 consecutive calendar months of invitation lists, August 2024–October 2026. There are 19 dated live snapshots in 2024, 18 in 2025 and 10 in 2026, plus 10 earlier dates recovered from history (one regional-only). The live series is irregular: it must not be labelled a complete daily or weekly record. `data/snapshot_catalog.csv` is the authoritative detailed inventory.

Invitation lists are the published reference lists for invitations under the applicable tournament rules. Live lists provide additional ranking updates. For this source lock, overlapping published live/invitation data are redundant; both source paths are preserved, but the canonical dataset prefers invitation rows once per date. Do not count their union as two independent populations.

## Details and inputs

Each canonical global entry has a linked detail report. Reports contain a printed final/starting/H2H decomposition, bounty/network/LAN factors, regional assignments, match-contribution rows and selected prize-contribution rows where present. Match contribution columns include local match index, match date, opponent label, W/L, age/event weight, raw and adjusted factors and participating roster.

These are **ranking contribution reports**, not a complete independent match database. The upstream model creates a local match index during input loading. The reports do not supply a permanent shared match key or a full event identity table. Repeated matches across teams and snapshots must not be added as independent matches. An absent reported LAN contribution is not proof of an online event.

Two JSON inputs are archived: the historical `data/matchdata.json` version (22,101,331 bytes) and `data/matchdata_sample_20230829.json` (42,776,418 bytes). They are historical examples/context, not a complete 2024–2026 input feed. The public source model is preserved locally and inspected for definitions; this project does not claim to recompute Valve's full rankings from those samples.

## Attribution and access

Valve reports credit HLTV.org for event data. This project reads only Valve's official public repositories and does not contact or scrape HLTV. The source notices remain in raw files. Public availability is not treated as a blanket license: neither inspected repository exposed a repository-wide license. This project does not relicense upstream code or data.

The public analysis repository excludes raw archives, Git mirrors, caches and dependencies. Pinned official URLs, Git object hashes, SHA-256 checksums and collection code make the archive recoverable without adding thousands of duplicate raw files or using Git LFS.
