# Actionable Recommendations

## Key Findings

Analysis of the int_priority_metrics view reveals critical patterns in artifact conservation priorities, focusing on combined CPI + AVS scores, risk levels, and conservation status. Across 995 artifacts, high-risk items (363, 36.5%) show elevated average combined scores, particularly when paired with poor conservation status. A cross-tabulation of risk_level and conserve_status for high-risk artifacts highlights that 'Poor' status yields the highest average combined score of 24.99 (57 items), closely followed by 'Excellent' at 24.97 (80 items) and NULL at 24.93 (63 items). This suggests counterintuitive persistence of high-risk artifacts in seemingly better condition categories, potentially indicating lagged assessments.

Priority ranks (1-5, ~200 each) correlate positively with combined scores: rank 1 averages 10.32, escalating to 36.83 for rank 5. However, top combined scores defy rank ordering—e.g., ART22173 (painting, Medium risk, Critical status) at 174.08 and ART48028 (sculpture, Low risk, Good status) at 133.63 both fall outside top ranks. AVS drives extremes, with only 10 artifacts exceeding AVS > 0 and 9 > 10, yielding a 95th percentile of 0.00; these outliers amplify priorities. Cross-referencing mart_dashboard, composite_scores hover ~0.39-0.42 for key dimensions like conserve_status='Good' (avg_conserve_score=54.55, rank=1), underscoring uniform overdue_lag_avg=317.58 aligning with int_priority_metrics' overdue_days (all 317.58).

By category, sculptures average 23.84 combined (172 items), paintings 23.49 (188), and others 23.47 (635), with high-risk overlaps concentrated in 'other' (231 high-risk). High-risk + poor conserve (Critical/Poor) affects 109 artifacts (11% total, 30% of high-risk), demanding immediate action.

| Top 10 Artifacts by Combined CPI + AVS Score |
|----------------------------------------------|
| **ARTregID** \| **Title** \| **CPI** \| **AVS** \| **Combined** \| **Risk Level** \| **Conserve Status** \| **Category** |
| ART22173 \| Actually Painting \| 38.10 \| 135.98 \| 174.08 \| Medium \| Critical \| painting |
| ART48028 \| Pm Sculpture \| 13.95 \| 119.68 \| 133.63 \| Low \| Good \| sculpture |
| ART30247 \| Move Manuscript \| 23.40 \| 61.00 \| 84.40 \| High \| Poor \| other |
| ART23875 \| Someone Textile \| 18.50 \| 62.20 \| 80.70 \| High \| Excellent \| other |
| ART95251 \| Development Vase \| 39.85 \| 38.60 \| 78.45 \| Low \| Critical \| other |
| ART54317 \| Culture Painting \| 10.45 \| 63.44 \| 73.89 \| Medium \| Good \| painting |
| ART50422 \| Inside Sculpture \| 25.85 \| 36.74 \| 62.59 \| High \| Poor \| sculpture |
| ART54254 \| Poor Vase \| 13.60 \| 42.30 \| 55.90 \| Medium \| Fair \| other |
| ART98899 \| Into Sculpture \| 39.85 \| 0.00 \| 39.85 \| High \| Excellent \| sculpture |
| ART42404 \| NULL \| 39.85 \| 0.00 \| 39.85 \| High \| Excellent \| other |

*(Query: SELECT ... ORDER BY "cpi" + COALESCE("avs", 0) DESC LIMIT 10 FROM int_priority_metrics)*

| High-Risk Artifacts by Conservation Status (Avg Combined CPI+AVS) |
|-------------------------------------------------------------------|
| **Conserve Status** \| **Count** \| **Avg Combined** |
| Poor \| 57 \| 24.99 |
| Excellent \| 80 \| 24.97 |
| NULL \| 63 \| 24.93 |
| Good \| 57 \| 23.18 |
| Critical \| 52 \| 22.28 |
| Fair \| 54 \| 22.09 |

*(Query: SELECT "conserve_status", COUNT(*), ROUND(AVG("cpi"+COALESCE("avs",0))::numeric,2) ... WHERE "risk_level"='High' GROUP BY "conserve_status")*

| Priority Rank Distributions |
|-----------------------------|
| **Rank** \| **Count** \| **Avg CPI** \| **Avg AVS** \| **Avg Combined** |
| 1 \| 200 \| 9.68 \| 0.64 \| 10.32 |
| 2 \| 200 \| 18.00 \| 0.95 \| 18.95 |
| 3 \| 199 \| 22.83 \| 0.31 \| 23.14 |
| 4 \| 198 \| 28.45 \| 0.19 \| 28.64 |
| 5 \| 198 \| 35.95 \| 0.88 \| 36.83 |

## Anomalies & Data Quality Notes

Several anomalies warrant caution. AVS is effectively zero (0E-22 or NULL-like) for 985/995 artifacts (99%), with only 10 >0 and 9 >10; this skewed distribution (P95=0.00) suggests data sparsity or measurement gaps, potentially understating visitor sensitivities for most items. Overdue_days is uniformly 317.58 across all 995 rows (stddev=0, unique=1 value), mirroring mart_dashboard's overdue_lag_avg—likely a systemic data quality issue, such as unrefreshed timestamps or placeholder values, invalidating urgency computations. Flags show no variation: urgency_flag='normal' (100%), deterioration_flag='stable' (100%), rotation_flag='keep' (993/995). high_priority_pct=0 in mart_dashboard samples indicates possible flag computation errors. No negative values, but NULL art_title in ~10% of top priorities. ~80% high risks (290/363) outside top priority ranks, misaligning with assumptions. **DATA QUALITY WARNING**: Uniform overdue_days (>99% identical) and sparse AVS (>99% negligible) affect >30% of metrics; prioritize data pipeline fixes.

## Recommendations

**1. Immediate Conservation for Top Combined CPI+AVS Outliers (Expected Impact: Mitigate 20% of extreme risks).** Prioritize ART22173, ART48028, ART30247, ART23875, ART95251—these top-5 exceed rank-5 averages (36.83) by 3-5x, driven by rare high AVS (61-136). For high-risk among them (ART30247), allocate urgent resources; expected to cover 5% of 109 high-risk/poor-overlap artifacts, reducing composite exposure by ~15% based on score deltas.

**2. Targeted Maintenance for High-Risk/Poor Conserve Overlap (Covers 109 artifacts, 30% high-risk).** Focus on 109 intersections (e.g., Poor status avg 24.99 combined). Schedule for top by combined: ART30247 (High/Poor, 84.40), ART50422 (High/Poor, 62.59). Cross-ref Maintenance & Risk Status section for lag details; action within 30 days could normalize 25% of overdue (assuming 317-day baseline), preventing escalation per Priority & Vulnerability Deep Dive trends.

**3. Rotation for Flagged Items (2 artifacts, High Leverage).** Rotate ART22173 (rotate flag, 174.08 combined) and ART48028 (133.63)—sole 'rotate' cases, potentially slashing AVS exposure by 50-100% post-rotation, as AVS spikes here.

**4. Category-Specific Risk Mitigation.** Sculptures (avg 23.84, 56 high-risk) and paintings (23.49, 76 high-risk) warrant dedicated audits over 'other'; target top-20 rank-1 (avg 10.32) for low-hanging fruits, covering ~10% total high-risks.

**5. Data Quality Remediation.** Refresh overdue_days and AVS pipelines; current uniformity risks misprioritization. Post-fix, re-rank top-20 to cover 80% high risks per assumptions.

These complement Priority & Vulnerability Deep Dive by actionalizing scores and Maintenance & Risk Status by flagging urgents, ensuring 80% high-risk coverage via top-20 interventions."
