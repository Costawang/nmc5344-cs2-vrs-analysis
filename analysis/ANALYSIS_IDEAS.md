# Analysis options

Ratings below are design judgments (1–5), not empirical results. The sequence is feasibility / interpretability / visual potential / methodological defensibility / fit for NMC5344.

| Priority | Direction | Ratings | Fit for a 1,000-word report |
| --- | --- | --- | --- |
| 1 | Top 10 persistence | 5 / 5 / 5 / 4 / 5 | Best central question |
| 2 | Rank mobility and volatility | 5 / 5 / 5 / 4 / 5 | Strong supporting comparison |
| 3 | Rise, decline and stability cases | 5 / 5 / 5 / 4 / 5 | One or two illustrative cases |
| 4 | Regional representation | 4 / 5 / 4 / 3 / 4 | Alternative supporting angle |
| 5 | Component structure | 4 / 4 / 4 / 3 / 4 | Useful model-literacy extension |
| 6 | Roster changes and subsequent ranks | 3 / 4 / 5 / 2 / 3 | Exploratory appendix or future project |

## 1. Competitive hierarchy

**Question:** How stable is the elite competitive hierarchy under official VRS?

**Variables:** Observed snapshot dates and official ranks; derived core-lineage IDs, exact-roster signatures and Top 10 indicators.

**Transformation and summary:** Use one invitation global list per month, calculate adjacent-month set intersections, retention rates, entries/exits and consecutive Top 10 runs. Compare core continuity with exact-player-set continuity. Report transitions across model boundaries separately.

**Visuals:** Top 10 membership heatmap, retention bars with exact-roster comparison, selected bump/line charts. **Interpretive value:** Makes elite persistence and openness understandable without complex modelling.

**Limitations:** Stability depends on identity definition, coverage and ranking rules. A Top 10 place is a relative position, not an absolute skill measurement. Strong fit as the main short-report question.

## 2. Team stability and volatility

**Question:** Which observed core lineages fluctuate most in ranking?

**Variables:** Observed ranks and points; derived adjacent-month rank changes, core continuity, method periods and coverage.

**Transformation and summary:** Calculate full-rank SD and mean absolute rank change for lineages with at least six ranked months and three adjacent-month pairs. Retain sample size. Compute points SD only within method periods. Do not assign a numerical last place to absent teams.

**Visuals:** Sorted horizontal volatility bars and small-multiple trajectories. **Interpretive value:** Separates consistently elite, unstable and steadily rising patterns.

**Limitations:** Unequal starting ranks, short histories and selection into the published field affect volatility. A balanced-panel sensitivity analysis can be considered later, but must not silently exclude short-lived lineages. Strong supporting angle.

## 3. Rise and decline

**Question:** What do representative ascents, declines and stable elite trajectories look like?

**Variables:** Observed ranks, dates and roster labels; derived three-calendar-month changes and continuity.

**Transformation and summary:** Select maximum rise and decline among eligible lineages using explicit tie-breaks; select the stable elite case by low average absolute change. Publish the selection table before interpreting the cases.

**Visuals:** Three small-multiple rank trajectories, optional slope chart for the selected start/end dates. **Interpretive value:** Turns aggregate statistics into legible examples.

**Limitations:** Extreme cases are selected examples and cannot establish general causes. Transfers, tournament access and other explanations cannot be established solely from these files. Good fit for one or two short illustrations.

## 4. Regional structure

**Question:** How did Europe, Americas and Asia appear in the global Top 20?

**Variables:** Observed global rank and official region membership; derived Top 20 and regional counts/shares.

**Transformation and summary:** Use a one-to-many regional table for early data. Start mutually exclusive composition charts with July 2025. Summarise counts, shares and changes; treat different eligibility regimes separately.

**Visuals:** Stacked bars or faceted region lines. **Interpretive value:** Connects global competitive structure to Valve's regional invitation framework.

**Limitations:** Historical multi-region eligibility, country reclassification and roster eligibility changes can create apparent regional movement without a corresponding performance change. Global Top 20 representation is not the same as the number of Major invitations. Suitable as an alternative, not an extra full topic.

## 5. VRS component analysis

**Question:** Which published scoring components differ across rank groups within one model period?

**Variables:** Observed starting/final values, H2H adjustments, bounty offered/collected, opponent network and LAN factor. Rank groups are derived.

**Transformation and summary:** Compare medians, IQRs and descriptive Spearman associations within a period or snapshot. Preserve raw and adjusted contributions separately. Repeated snapshots are not independent observations for conventional significance tests.

**Visuals:** Component boxplots, scatterplots, and starting-versus-H2H contribution displays. **Interpretive value:** Explains what the ranking system rewards.

**Limitations:** The components mechanically feed the ranking. Correlation cannot show an independent driver of performance or a causal improvement strategy. Components may be normalised against contemporaneous teams. Useful for communicating methodology, with restrained claims.

## 6. Roster changes

**Question:** Are first-observed lineup changes followed by different rank trajectories over the next one to three monthly snapshots?

**Variables:** Observed player sets and ranks; derived overlap, Jaccard similarity, change class, first-observed date, method period and pre/post ranks.

**Transformation and summary:** Use complete five-player rosters and unambiguous links. Distinguish one-/two-player changes from same-name major replacement candidates. Exclude or flag method-boundary observations. Summarise paths and group medians descriptively; overlapping events and missing follow-up must remain visible.

**Visuals:** Change markers on trajectories, small multiples or aligned pre/post paths. **Interpretive value:** Relates roster continuity to ranking dynamics without an elaborate model.

**Limitations:** Official active-roster displays can lag actual changes, especially after August 2025. Players may change because of prior poor performance. Other contemporaneous events and selection confound the comparison. This release supplies the observations and markers but does not estimate causal effects or construct a transfer database.

## What the archive cannot support on its own

A universal cross-year point scale; causal transfer effects; financial returns; fan sentiment; tactical/playstyle explanations; exact global player identity; a complete match history deduplicated across snapshots; or full official ranking recalculation. Those would require additional authorised data and a revised design.
