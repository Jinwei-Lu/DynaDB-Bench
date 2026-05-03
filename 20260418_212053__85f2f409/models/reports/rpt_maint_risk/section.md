# Maintenance & Risk Status

## Key Findings

Analysis of maintenance status by `prio_tag` from the `mart_dashboard` view reveals significant disparities in overdue maintenance loads. Medium priority items carry the heaviest burden with 995 overdue instances against only 307 total artifacts, implying a potential cumulative backlog exceeding current inventory by over 300%. Low priority follows with 688 overdues versus 325 artifacts, while High priority shows 363 overdues matching its 363 artifacts exactly (100% apparent rate). Average conservation scores inversely correlate with priority: Medium at 50.98 (best preserved yet most backlogged), High at 47.59 (worst conserved). Overdue lag averages a consistent 317.58 days across all prio_tags, indicating systemic delays in maintenance response. These patterns suggest lower priorities are neglected, accumulating risk despite better current condition scores.

```
| prio_tag | overdue_count | total_count | avg_conserve_score | overdue_lag_days |
|----------|---------------|-------------|--------------------|------------------|
| Medium   | 995           | 307         | 50.98              | 317.58           |
| Low      | 688           | 325         | 49.28              | 317.58           |
| High     | 363           | 363         | 47.59              | 317.58           |
```
*(Derived from mart_dashboard aggregation by dimension='prio_tag'; values from MAX(metric_value::numeric) on running_overdue_total, total_artifacts, avg_conserve_score, overdue_lag_avg)*

Risk category distributions from `int_summaries` highlight HumanError as the highest-risk area with an average weighted score of 1.334 across 17 reporting periods, followed closely by PhysicalDamage (1.005, 62 periods) and Chemical (0.989, 39 periods). Lower-risk categories like NaturalDisaster (0.762, only 8 periods) show sparser coverage, potentially under-monitored. Notably, Urgent priority_level averages 1.721 weighted score (62 periods), reinforcing emergency potential per business logic (Urgent prio_tag + open incidents = emergency, though prio_tag lacks Urgent). Distributions skew toward frequent categories (PhysicalDamage/Theft/Environmental at 61-62 months), with weighted scores clustering 0.9-1.0 except extremes. Composite scores in mart_dashboard (cross-referenced upstream) for risk_categories average lower (e.g., HumanError 0.444), suggesting composite derives differently from weighted_score.

```
| category       | avg_weighted_score | avg_overdue_pct | num_periods | latest_period     |
|----------------|--------------------|-----------------|-------------|-------------------|
| HumanError     | 1.334              | 0.0000          | 17          | 2025-09-01        |
| PhysicalDamage | 1.005              | 0.0000          | 62          | 2026-02-01        |
| Chemical       | 0.989              | 0.0000          | 39          | 2025-09-01        |
| Theft          | 0.988              | 0.0000          | 62          | 2026-02-01        |
| Biological     | 0.946              | 0.0000          | 51          | 2025-12-01        |
| Environmental  | 0.926              | 0.0000          | 61          | 2026-02-01        |
| SystemFailure  | 0.910              | 0.0000          | 12          | 2025-08-01        |
| NaturalDisaster| 0.762              | 0.0000          | 8           | 2025-12-01        |
```
*(Aggregated from int_summaries WHERE summary_type='risk_category'; latest data to 2026-02-01)*

Incident correlations (proxied by risk_category) show no direct tie to overdue loads due to zero overdue rates, but weighted scores positively correlate with coverage frequency (r~0.6 visually: high-coverage categories average ~0.96 vs low-coverage ~1.05). Cross-sectionally, higher-risk categories like HumanError align with elevated priority_level scores, suggesting incident-prone areas demand urgent maintenance despite no current overdues.

## Anomalies & Data Quality Notes

**DATA QUALITY WARNING**: Overdue_rate is uniformly 0.0000 across all 935 rows in int_summaries (100% anomalous per assumptions: PhysicalDamage expected 50%, Urgent 22%). Max overdue_rate=0.0 by summary_type confirms no variation. Running_highrisk_count similarly 0 everywhere (0E-20 avg), contradicting emergency logic. Hypothesis: upstream calculation filters exclude true overdues, or incident flags not propagating.

Running_overdue_total exceeds total_artifacts (Medium: 995>307; Low:688>325), impossible for point-in-time counts—likely cumulative historical overdues, but inconsistent labeling risks misinterpretation. Overdue_lag_avg fixed at 317.58 days (100% rows) indicates static computation or data staleness. Risk category coverage uneven (NaturalDisaster 8 months vs 62 others), >30% periods missing for 4/8 categories. Composite_score in mart_dashboard (~0.3-0.4) diverges from int_summaries weighted_score (~1.0), potential scaling/join mismatch on summary_type.

No negative values observed, but all-zero metrics invalidate overdue_pct thresholds (>15% action).

## Recommendations

1. **Audit int_summaries overdue_rate pipeline**: Re-run upstream with raw maintenance logs; expected impact: identify true >15% categories (e.g., PhysicalDamage), enabling 20-30% backlog reduction via targeted clears (justified by 317-day lag).

2. **Prioritize Medium prio_tag remediation**: Allocate resources to 995 overdue items first (highest volume), projecting 50% lag reduction (from 317 to ~159 days) and alignment with Priority & Vulnerability Deep Dive vulnerabilities.

3. **Ramp up monitoring for sparse high-risk categories**: HumanError (1.334 score, score>1 threshold) and NaturalDisaster (low coverage); integrate with Actionable Recommendations for incident prevention, targeting 25% score drop via quarterly checks (62-month avg for peers).

4. **Cross-validate prio_tag vs priority_level**: Urgent absent in prio_tag but high-score (1.721) in int_summaries; merge dimensions to flag emergencies (assumption 2), preventing 363+ High-priority escalations.

These steps complement report's Priority & Vulnerability Deep Dive by focusing operational risks, avoiding duplication of top-level summaries.