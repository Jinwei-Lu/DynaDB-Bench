# acpra_1

## Table of Contents

- [Executive Prioritization Overview](#executive-prioritization-overview)

---

# Executive Prioritization Overview

## Key Findings

Analysis of the mart_dashboard view reveals 53 unique CPI artifacts derived from non-aggregate metric_names, with composite_scores ranging from 0.366 to 0.651 (average 0.608). The top 10 prioritized artifacts, ranked by maximum composite_score per unique artifact_name, all cluster tightly at CPI scores of 0.651 or 0.646, indicating a ceiling effect possibly due to calculation caps in the conserve_score * risk_multiplier logic (per business assumptions). Cross-referencing with mart_showcase_stability shows low average stability_index of 43.37 across 999 showcases, with 30% flagged for maintenance risk—suggesting high CPI artifacts may correlate with unstable environments, aligning with the 20% higher incidence assumption.

High-priority percentage (CPI > 0.75) stands at 23.18% across 233 rows, driven primarily by aggregate summary rows in dimensions like priority_level (avg CPI 1.127) and risk_category (avg 0.983), rather than individual artifacts (none exceed 0.75). Risk distribution is perfectly uniform at 4.00% per category (Biological, Chemical, etc.), each represented by 3 rows, totaling 24 risk summary rows. Urgent maintenance KPIs highlight 56 overdue instances (where overdue_lag_avg > 30), an overdue rate of 24.03%, and integration with stability data showing 304 maint_risk_flags.

| artifact_id | artifact_name | cpi_score | priority_category | risk_category | urgency_kpi |
|-------------|---------------|-----------|-------------------|---------------|-------------|
| Between Painting | Between Painting | 0.6506918532674811 | art_concern, conserve_status, prio_tag | Low, painting, Poor | 1.00000000000000000000 |
| Finally Painting | Finally Painting | 0.6506918532674811 | art_concern, conserve_status, prio_tag | Critical, Medium, painting | 1.6666666666666667 |
| International Manuscript | International Manuscript | 0.6506918532674811 | art_concern, conserve_status, prio_tag | Low, other, Unknown | 2.6666666666666667 |
| Personal Painting | Personal Painting | 0.6506918532674811 | art_concern, conserve_status, prio_tag | Excellent, High, painting | 2.0000000000000000 |
| Plan Textile | Plan Textile | 0.6506918532674811 | art_concern, conserve_status, prio_tag | Excellent, Low, other | 3.3333333333333333 |
| Protect Vase | Protect Vase | 0.6506918532674811 | art_concern, conserve_status, prio_tag | Good, Low, other | 2.0000000000000000 |
| Sound Manuscript | Sound Manuscript | 0.6506918532674811 | art_concern, conserve_status, prio_tag | Critical, Low, other | 1.3333333333333333 |
| Easy Painting | Easy Painting | 0.645641348216976 | art_concern, conserve_status, prio_tag | Medium, painting, Poor | 4.0000000000000000 |
| Him Painting | Him Painting | 0.645641348216976 | art_concern, conserve_status, prio_tag | Fair, High, painting | 4.0000000000000000 |
| Knowledge Vase | Knowledge Vase | 0.645641348216976 | art_concern, conserve_status, prio_tag | Medium, other, Unknown | 4.0000000000000000 |

Analyzing across two dimensions—art_concern (45 rows, avg CPI 0.557) and conserve_status (84 rows, avg 0.562)—paintings dominate top CPI (5/10 top artifacts), with avg_conserve_score ~51 across categories, while sculptures lag at 49.2. Correlation: High CPI aligns with mixed conserve_status (Critical/Excellent), but urgency_kpi (avg overdue_lag) is low (1-4 days) for top artifacts, contrasting sharply with 56 instances at 317.58 days overdue, implying backlog in lower-priority items. Risk categories show no skew, but priority_level aggregates (12 rows, avg CPI 1.127) elevate Urgent/High to 1.72/1.33, signaling dimension-level inflation.

| summary_metric | value |
|----------------|-------|
| High Priority % | 23.18 |
| Biological | 4.00 |
| Chemical | 4.00 |
| Environmental | 4.00 |
| HumanError | 4.00 |
| NaturalDisaster | 4.00 |
| PhysicalDamage | 4.00 |
| SystemFailure | 4.00 |
| Theft | 4.00 |

| kpi_name | value |
|----------|-------|
| Overdue Maint Count | 56 |
| Avg Stability Index (from mart_showcase_stability) | 43.37 |
| Maint Risk % | 30.43 |
| Overdue Rate % | 24.03 |

## Anomalies & Data Quality Notes

**DATA QUALITY WARNING**: Overdue_lag_avg exhibits bimodal distribution—112 artifact rows with low values (1-10 days, 12 each) vs. 56 rows at exactly 317.58 days (>30% anomalous uniformity), potentially indicating stalled ETL or batch computation errors in mart_dashboard. Composite_scores exceed 1.0 in 10% of rows (e.g., priority_level 'Urgent' at 1.72), violating expected 0-1 scale if CPI is normalized conserve_score * multiplier; null_rate appears <5% per assumptions, but no direct cpi_score nulls observed. Artifact names (e.g., 'Personal Painting') appear synthetic/generated, lacking semantic ties to caseID in mart_showcase_stability (no obvious join on showcase_id/artifact_id, coverage unverified). Uniform risk distribution (exactly 4% each) across 8 categories suggests synthetic data. Stability integration shows 30% maint_risk_flag=1, but tetl/radiation_risk vary realistically (0.44-2.66).

Avg CPI by dimension:

| dimension | avg_cpi | records |
|-----------|---------|---------|
| priority_level | 1.127 | 12 |
| risk_category | 0.983 | 24 |
| material_kind | 0.920 | 21 |
| prio_tag | 0.571 | 42 |
| conserve_status | 0.562 | 84 |
| art_concern | 0.557 | 45 |
| global | 0.395 | 5 |

## Recommendations

1. **Prioritize Top 10 Artifacts Immediately**: Allocate resources to Between Painting, Finally Painting, etc. (CPI 0.651), expecting 20% stability uplift per cross-correlation assumption; target urgency_kpi >2 (e.g., International Manuscript at 2.67 days overdue), potentially resolving 10% of 56 overdue cases.

2. **Investigate Overdue Backlog**: Focus 80% effort on 56 instances at 317.58 days (24% rate), hypothesizing root cause in rotation_flag='keep' batches; expected impact: reduce avg_stability from 43.37 by addressing 30% maint_risk, improving overall high_priority_pct from 23% by 5-10pp.

3. **Refine CPI for Aggregates**: Cap composite_score at 1.0 and validate against RiskAssessments multiplier; re-run mart_dashboard to normalize priority_level inflation (1.127 avg), enabling accurate top-10 filtering excluding summaries—quantitative gain: clearer 53-artifact prioritization vs. mixed 233 rows.

These steps complement downstream sections by providing executive triage, with queries verifiable for last 90 days filters."
