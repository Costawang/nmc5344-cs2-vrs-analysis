# VRS changes and analytical boundaries

This log separates changes evidenced in official code/rules from the project's conservative analysis periods. A commit publication date is not proof that every ranking published that day used exactly that code. Keep snapshot dates, match eligibility thresholds and commit timestamps separate.

| Official change | Evidence and consequence | Analysis treatment |
| --- | --- | --- |
| 2024-04-22: ranking model and reporting revision | [Commit 5a5bb43](https://github.com/ValveSoftware/counter-strike_regional_standings/commit/5a5bb43c2d383f32f48836e9125256317653da55): scaled winnings/LAN changes, global lists and detail reports | Start global analysis here; earlier regional lists are retained separately |
| 2024-07-11: match-report filtering | Inspect the July 11 model changes in the archived history | Separate the earlier reporting period; do not interpret missing displayed contributions as missing matches |
| 2024-07-31: multiple-region eligibility | Regional report construction changes in the official model | Preserve a one-to-many region table; avoid mutually exclusive composition shares for this era |
| August 2024: live/invitation and dated directory organisation | Current paths begin on August 6; live/invitation reorganisation appears later in August | Treat represented date and publication date separately; monthly invitation panel begins in August |
| 2025-01-20: ranked-match filtering, with a 2025-01-01 match-date threshold | [Commit c6bb379](https://github.com/ValveSoftware/counter-strike_regional_standings/commit/c6bb3792afa3137ff70c1b5a918b4532e9271483) | Conservatively separate the 2025 eligible-event regime; the threshold is not the commit date |
| 2025-02-24: minimum-match threshold and input handling | [Commit 46f6cd0](https://github.com/ValveSoftware/counter-strike_regional_standings/commit/46f6cd0a366c1fa0faddf2e06c7c39d85659ba6f): minimum matches 10 to 5, forfeits/in-progress events and prize plus club-share handling | Start a new scoring/eligibility period; changing ranked population also affects percentiles |
| 2025-06-16 and June 25: regional assignment | [Single-region change](https://github.com/ValveSoftware/counter-strike_regional_standings/commit/6cc8521091c1b6a6b441ebf8faf8926865694098), [country mapping revision](https://github.com/ValveSoftware/counter-strike_regional_standings/commit/3c9f3e71959f8c3a061b10cfb757888b1d298bef) | Use the first subsequent July 7 snapshot as the regional-composition starting point |
| 2025-08-05: linked tournament-stage prizes and active player display | [Commit 297ee00](https://github.com/ValveSoftware/counter-strike_regional_standings/commit/297ee0099e7b50fb3aa579c35831ab5ae8987128): active-player criterion of at least five of the last ten matches | First subsequent monthly snapshot is September 1; fewer than five displayed active players are preserved without forced transfer inference |
| September 2026 ranking correction | September 7 snapshot revised September 9; [correction commit](https://github.com/ValveSoftware/counter-strike_regional_standings/commit/84ccfa4d751fa3801ae6430097a9a66f104ee131) | Preserve both versions; canonical analysis uses the final published revision |
| 2026-10-06/07: Major regional eligibility and exceptions | [Pinned rule repository](https://github.com/ValveSoftware/counter-strike_rules_and_regs/tree/621b7d91b0a236044aed62a357fddc863dfaea49) | Rule metadata; do not label these as proven scoring-formula changes or apply them retroactively to October 5 |

## Reproducible segmentation

`R/helpers.R::period_for()` implements these broad periods:

| ID | Start date | Interpretation |
| --- | --- | --- |
| P1 | 2024-01-01 | Pre-global reference period; recovered regional snapshot only |
| P2 | 2024-04-22 | New global/reporting model |
| P3 | 2024-07-11 | Revised match display, then multi-region and dated publication era |
| P4 | 2025-01-01 | Conservative boundary for ranked-match eligibility |
| P5 | 2025-02-24 | Lower minimum-match threshold and revised prize/input handling |
| P6 | 2025-07-07 | First observed snapshot after regional reassignment |
| P7 | 2025-09-01 | First monthly snapshot after linked-stage and active-roster changes |

Periods are deliberately broad and do not certify a universal score scale even within a period. The main findings use Top-N retention and rank mobility, report a sensitivity comparison excluding cross-period transitions, and show raw-point lines only within periods. Percentiles standardise rank within a list but cannot remove changed eligibility, field size or regional rules.

The complete inspected commit messages and timestamps are in `data/commit_history.csv`; archived model versions and rules can be located using the manifest. Unrelated repository maintenance is not claimed to be a substantive VRS change.
