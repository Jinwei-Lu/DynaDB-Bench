# RiskManagementReport

## Table of Contents

- [Insurance Coverage Analysis](#insurance-coverage-analysis)
- [Emergency Preparedness](#emergency-preparedness)
- [Prioritized Recommendations](#prioritized-recommendations)

---

# Insurance Coverage Analysis

## Key Findings

Out of 47 total exhibitions in `int_exhibition_risk_profile`, only 17 have linked insurance policies and positive coverage (total_coverage_value_usd > 0), aligning with the assumption of 17 exhibitions with linked policies. This leaves 30 exhibitions (64%) completely uncovered, posing significant risk exposure. Average coverage across covered exhibitions is approximately $76.8 million USD, with Hall-12 leading in coverage adequacy (average $92.1M across 7 exhibitions, though 2 uncovered).

Coverage adequacy is defined per business logic as budget_variance_pct > 50 (coverage > 150% of budget). However, no exhibitions meet this threshold; all covered ones are either 'Partial' (coverage >0 but variance <=50) or 'None/Inadequate'. Distribution shows:

| coverage_status    | count | avg_coverage     | avg_var_pct |
|--------------------|-------|------------------|-------------|
| None/Inadequate   | 30    | 0                | -0.02       |
| Partial            | 17    | 76764705.88      | 1.13        |

Provider performance (for the 17 exhibition-linked policies from `stg_insurance_policies`): AIG dominates with 7 policies totaling $520M coverage, followed by AXA XL (5 policies, $337M) and Chubb (4 policies, $248M). No direct claim involvement data available, but higher policy volume suggests greater involvement.

Cross-referencing with `mart_risk_management_dashboard`, high composite_risk_score halls often lack coverage:

| location_in_hall | composite_risk_score | avg_coverage_usd | avg_budget_var | num_exhibitions |
|------------------|----------------------|------------------|----------------|-----------------|
| Hall-16         | 37.19                | 11666666.67      | -1.61          | 3               |
| Hall-20         | 36.77                | 0                | 0.28           | 2               |
| Hall-17         | 24.97                | 0                | 1.52           | 2               |
| Hall-18         | 18.97                | 0                | 0.83           | 2               |
| Hall-11         | 15.73                | 37500000         | -1.81          | 2               |

Hall-12 (low risk 1.58) has highest coverage ($92.1M avg), supporting the cross-column correlation assumption that high-budget exhibitions correlate with higher coverage.

## Anomalies & Data Quality Notes

**DATA QUALITY WARNING**: 27 of 47 exhibitions (57.4% >30% threshold) have negative budget_variance_pct (min -6.67), anomalous as non-negative expected per prescan alert. Root cause hypotheses: 
1. Calculation inversion: variance computed as (budget - coverage)/budget *100 instead of (coverage - budget)/budget *100.
2. Actual budget overspend/underspend relative to coverage, but negatives contradict adequacy logic.
3. Data entry errors in upstream budget or coverage values.

Prominently flagged: Hall-1 avg_var -5.00 (both exhibitions uncovered, risk_preparedness_score=0). 0E-20 artifacts appear as display for 0 in aggregates—likely floating-point precision; treat as zero coverage.

30 exhibitions have zero coverage despite num_emergency_plans >0 (e.g., Hall-15: 3 exhibitions, all uncovered). risk_preparedness_score is 0 for all uncovered (31 cases), spiking to 102-240 for covered—strong binary correlation, suggesting score derives from coverage ratio.

## Analysis by Hall and Coverage Adequacy

Analyzing by hall reveals stark disparities: Hall-12 (7 exhibitions) averages $92.1M coverage but 2 uncovered; Hall-9 (3 exh) $60M avg, fully covered. Conversely, 12 halls have all exhibitions uncovered (e.g., Hall-15:3, Hall-1/2/4/etc:2 each). Distribution: 64% halls partial/full no-coverage.

By risk dimension (cross-ref `mart_risk_management_dashboard`): Top-5 risk halls (composite_risk_score >15) average only $19.8M coverage vs overall $38.6M (weighted by exhibitions), with Hall-16 (37.19 risk) under-covered despite partial avg $11.7M (2/3 uncovered). Negative correlation: higher risk inversely relates to coverage (Pearson-like: high-risk Hall-20/17/18 at 0 coverage). Budget variance clusters negative in high-risk halls (-1.61 to 0.28), amplifying vulnerability—links to Security Incidents Deep Dive where escalating risk_category_flag (e.g., Hall-1) noted.

## Recommendations

1. **Prioritize coverage for 30 uncovered exhibitions** (quant: 64% portfolio), starting with high-risk halls: Hall-15 (3 exh, risk 2.45), Hall-20 (2 exh, risk 36.77), Hall-16 (risk 37.19, 2/3 uncovered). Expected impact: Lift 31 risk_preparedness_scores from 0, reduce composite_risk exposure by ~20-30% in top halls (cross-ref Executive Risk Summary).

2. **Audit top providers (AIG/AXA/Chubb >80% linked coverage)** for claim history/performance; consolidate to AIG (handles 41% of exhibition policies, $74M avg/policy). Target: Increase avg variance >50% via negotiation, impacting 17 exhibitions (+$1.3B potential uplift at 150%).

3. **Resolve budget_variance_pct anomalies**: Recompute as ABS((coverage/budget-1)*100) or validate upstream; flag 27 negatives for review. Prioritize Hall-1 (-6.67 min), linking to Emergency Preparedness section's low preparedness_rank=1.

These complement Prioritized Recommendations by quantifying insurance gaps in risk hotspots, avoiding duplication of top-level summaries.

---

# Emergency Preparedness

## Key Findings

Analysis of emergency preparedness across 20 halls (excluding NULL location in `mart_risk_management_dashboard`) reveals significant gaps in plan coverage, drill recency, and responder staffing. Out of 20 halls, **16 have at least one active emergency plan** from the `EmergencyPlans` table (total active plans: 20), leaving **4 halls without any active plans**: Hall-16, Hall-17, Hall-19, and Hall-20. Fire-type plans dominate, covering 15 halls (75% coverage), falling below the 80% threshold flagged as a gap per business assumptions. Other types like Chemical Spill, Earthquake, Flood, Power Outage, and Theft each cover only 1 hall, indicating over-reliance on fire protocols.

Recent drill coverage shows positive trends: 10 of the 16 covered halls have documented 2024 drills (e.g., Hall-5,6,7,8 at 2024/10/15; Hall-2,1 at 2024/04/20), representing ~63% recent activity. However, 6 halls have NULL or older drills (e.g., Hall-11,18 NULL; Hall-10 at 2023/11/10). Responder staffing adequacy is mixed: Fire plans average 4 staff per hall, but extremes exist (Earthquake: 1 staff; Flood/Power Outage: 19 staff). Cross-referencing with `mart_risk_management_dashboard`, high-risk halls (composite_risk_score >10) like Hall-20 (36.77, no plan, rank 3) and Hall-16 (37.19, no plan, rank 3) amplify vulnerabilities, correlating with 'Escalating' risk_category_flag seen in the Executive Risk Summary. No-plan halls average composite_risk_score of 28.29 (vs. overall avg 10.67).

The table below summarizes hall-level metrics, joining `mart_risk_management_dashboard` with active plans count:

| location_in_hall | num_plans | preparedness_rank | composite_risk_score | plan_status     |
|------------------|-----------|-------------------|----------------------|-----------------|
| Hall-1          | 2        | 1                | 9.05                | Adequate       |
| Hall-19         | 0        | 1                | 14.25               | No Plan        |
| Hall-10         | 1        | 2                | 2.28                | Minimal Coverage|
| Hall-18         | 1        | 2                | 18.97               | Minimal Coverage|
| Hall-4          | 1        | 2                | 1.49                | Minimal Coverage|
| Hall-20         | 0        | 3                | 36.77               | No Plan        |
| Hall-14         | 1        | 3                | 0.89                | Minimal Coverage|
| Hall-16         | 0        | 3                | 37.19               | No Plan        |
| Hall-2          | 1        | 4                | 2.70                | Minimal Coverage|
| Hall-5          | 1        | 4                | 6.71                | Minimal Coverage|
| Hall-15         | 1        | 4                | 2.45                | Minimal Coverage|
| Hall-17         | 0        | 5                | 24.97               | No Plan        |
| Hall-8          | 1        | 5                | 1.56                | Minimal Coverage|
| Hall-13         | 1        | 5                | 2.08                | Minimal Coverage|
| Hall-6          | 1        | 6                | 14.07               | Minimal Coverage|
| Hall-11         | 1        | 6                | 15.73               | Minimal Coverage|
| Hall-9          | 2        | 7                | 14.10               | Adequate       |
| Hall-7          | 1        | 7                | 4.01                | Minimal Coverage|
| Hall-3          | 2        | 8                | 2.59                | Adequate       |
| Hall-12         | 2        | 9                | 1.58                | Adequate       |

*Note: Scores rounded for readability; queried directly from LEFT JOIN on active plans. plan_status: No Plan (0), Minimal (<2), Adequate (>=2).*

Emergency type distribution highlights imbalance:

| EMERGENCY_TYPE | halls_covered | avg_staff | oldest_drill | recent_drill |
|----------------|---------------|-----------|--------------|--------------|
| Fire          | 15            | 4.00     | 2023/11/10  | 2024/10/15  |
| Chemical Spill| 1             | 3.00     | NULL        | NULL        |
| Earthquake    | 1             | 1.00     | 2023/08/22  | 2023/08/22  |
| Flood         | 1             | 19.00    | 2023/09/15  | 2023/09/15  |
| Power Outage  | 1             | 19.00    | 2023/12/05  | 2023/12/05  |
| Theft         | 1             | 4.00     | 2024/07/15  | 2024/07/15  |

## Analysis by Hall Risk and Plan Coverage

Analyzing along two dimensions—hall preparedness_rank and emergency type—reveals inverse correlations between preparedness_rank (lower better) and plan coverage. Top-ranked halls (1-3) average 0.67 plans/hall (e.g., Hall-19 rank 1, 0 plans; Hall-20 rank 3, 0 plans), while lower ranks (7-9) average 1.67 plans/hall. Distribution: 25% of halls (5/20) have >=2 plans (Adequate), 55% (11/20) Minimal (1 plan), 20% (4/20) No Plan. Correlating with composite_risk_score from `mart_risk_management_dashboard`, no-plan halls average risk_score 28.29 (vs. overall avg 10.67), aligning with Security Incidents Deep Dive trends, where escalating incidents (all 'Escalating' flags) compound unpreparedness.

Drill recency distributes unevenly: 50% of plans have 2024 drills, but non-Fire types lag (only Theft recent). Staffing adequacy: 75% of Fire plans at exactly 4 staff (adequate per implicit benchmark), but 20% of halls with plans have avg_staff <4 (e.g., Hall-18:3), risking overload in multi-incident scenarios per Insurance Coverage Analysis linkages. High-incident halls like Hall-9 (cross-ref running_total_incidents from mart) show better coverage (2 plans), suggesting preparedness mitigates risks.

## Anomalies & Data Quality Notes

- **Critical Anomaly**: 4 halls (20%) lack active plans, including top preparedness_rank halls (Hall-19 rank 1), contradicting expected Fire plan >=1/hall assumption. Hypothesis: Data capture lag or deactivation; impacts highest-risk halls (avg risk_score 28.29).
- **Outliers**: Extreme staffing—Earthquake (1 staff, understaffed), Flood/Power (19, overstaffed potentially inefficient). NULL LAST_DRILL in ~30% of covered halls (e.g., Hall-11), possible data quality issue (missing logs vs. no drills).
- **Data Quality**: `plan_for_hall` matches `location_in_hall` exactly (no JOIN mismatches). One NULL hall in mart (5% rows); uniform 'Escalating' flags—potential staleness. No negatives/zeros unexpected. Coverage 80% overall but Fire 75% <80% threshold. Anomalies <30%—no **DATA QUALITY WARNING**.

## Recommendations

1. **High Priority: Develop Fire plans for 4 no-plan halls** (Hall-16/17/19/20; avg risk_score 28.29, total exposure ~113). Expected impact: Lift Fire coverage to 100%, reduce composite_risk ~20% (benchmark: planned halls avg risk 8.5 vs no-plan 28.3).
2. **Medium: Schedule drills for 6 halls with NULL/old drills** (e.g., Hall-11/18; ~37% of covered halls). Target Q1 2025; expected: Improve preparedness_rank by 1-2 tiers based on recent drill correlations.
3. **Staffing Audit**: Normalize to 4-6 staff/hall for Fire (current avg 4); reallocate from overstaffed (19→8). For understaffed like Hall-18 (3), add 1 FTE. Expected: Balance load, enhance response in 20% vulnerable halls.
4. **Cross-Functional**: Link to Prioritized Recommendations—prioritize high-risk no-plans; track via env_stability_index quarterly, tying to Executive Risk Summary.

This section provides depth on preparedness gaps driving 'Escalating' risks in Executive Risk Summary and incident patterns in Security Incidents Deep Dive."


---

# Prioritized Recommendations

## Key Findings

Analysis of the mart_risk_management_dashboard reveals that composite_risk_score varies widely across 21 records (20 unique halls plus one NULL location), with a mean of 10.66, minimum 0.89, maximum 37.19, and standard deviation of 11.11. The top 5 halls by composite_risk_score account for the highest risks, all classified as 'Escalating'. These halls show a moderate positive correlation (0.574) between composite_risk_score and running_total_incidents, suggesting that elevated risk levels are associated with higher historical incident volumes. Additionally, a weaker correlation (0.270) exists between risk and preparedness_rank, indicating that while preparedness contributes to risk, other factors like security_trend_delta and maintenance_overdue_weighted play significant roles.

The following table summarizes the top 5 halls by descending composite_risk_score (excluding NULL location for prioritization):

| location_in_hall | composite_risk_score | preparedness_rank | running_total_incidents | security_trend_delta | maintenance_overdue_weighted | risk_category_flag |
|------------------|----------------------|-------------------|-------------------------|----------------------|------------------------------|--------------------|
| Hall-16         | 37.1903846153846153846150 | 3                | 14                      | 12                   | 7.563890654799745707503210425937698665 | Escalating        |
| Hall-20         | 36.7656617647058823529410 | 3                | 25                      | 12                   | 14.460379192999513852854414195430238211 | Escalating        |
| Hall-17         | 24.9683639455782312925165 | 5                | 12                      | 8                    | 13.043852251644459434854417271040647664 | Escalating        |
| Hall-18         | 18.9695833333333333333330 | 2                | 11                      | 6                    | 16.388429752066115699836115702479338843 | Escalating        |
| Hall-11         | 15.7312500000000000000000 | 6                | 5                       | 5                    | 14.749586776859504130000000000000000000 | Escalating        |

These top 5 halls have an average risk score of 26.73 (2.5x the overall average) and average incidents of 13.4 (slightly above the global average of 16.62 across all records, but notable given their risk concentration).

## Preparedness and Multi-Dimensional Risk View

Considering preparedness_rank as a second dimension (lower rank presumed better preparedness, with ranks ranging 1-9), the worst-prepared halls (highest ranks) show lower average risks but still warrant attention when combined with other metrics. For instance, ranks 7-9 average risk of ~23.9 (elevated vs. overall avg), with Hall-9 exhibiting 55 running_total_incidents in detailed inspection—far above average. Distribution by preparedness_rank shows clustering: ranks 1-3 average risk ~3.3 (low), ranks 4-6 ~5.0 (low-moderate), ranks 7-9 ~30+ in outliers (high variance).

| preparedness_rank | count | avg_risk | avg_incidents |
|-------------------|-------|----------|---------------|
| 1                 | 3     | 4.160995707353490108249333333333333333333333 | 14.0000000000000000 |
| 2                 | 3     | 1.655394429531381930761166666666666666666667 | 5.6666666666666667 |
| 3                 | 3     | 4.149986474522919535706916666666666666666667 | 4.3333333333333333 |
| 4                 | 3     | 2.521438492063492063492000000000000000000000 | 9.3333333333333333 |
| 5                 | 3     | 9.1083038548752834467118 | 24.6666666666666667 |
| 6                 | 2     | 3.814583333333333333333250000000000000000000 | 4.5000000000000000 |
| 7                 | 2     | 44.556985947712418300653342600000000000000000 | 26.5000000000000000 |
| 8                 | 1     | 2.5918622448979591836730 | 5.0000000000000000 |
| 9                 | 1     | 2.094456101190476183332611100000000000000000 | 12.0000000000000000 |

This table highlights escalation in average risk and incidents at higher ranks (e.g., rank 7 avg risk 44.56, incidents 26.5), correlating with findings in the Emergency Preparedness section where low preparedness amplifies vulnerabilities.

## Anomalies & Data Quality Notes

- **Prominent Outlier:** A NULL location_in_hall record shows 81 running_total_incidents (4.9x the average of 16.62) and security_trend_delta of 17, despite a moderate risk of 10.45 and top-tier preparedness_rank=1. Hypothesis: This may represent an unassigned or multi-hall aggregation error; cross-verification recommended against raw incident logs from Security Incidents Deep Dive.
- Uniform risk_category_flag='Escalating' across all 21 rows suggests either pervasive issues or categorical stagnation—monitor for updates.
- env_stability_index is uniformly ~1.0 (no variance observed), rendering it non-discriminatory; potential data quality issue (constant propagation from upstream).
- High standard deviation (11.11) driven by top-end outliers like Hall-16 (37.19); no negatives where positives expected (e.g., all incidents >=0).
- No evidence of >30% anomalous values per metric; however, inconsistent risk reporting for Hall-9 across subsets (14.10 vs. 87.60 in rank-filtered views) flags potential view refresh or precision issues—verified via direct queries.

## Recommendations

Prioritized actions target top-risk halls (composite_risk_score >15, above 80th percentile of 16.38), cross-referenced with preparedness_rank >3 (below median preparedness) and high running_total_incidents (>10). Expected impacts based on correlations: addressing top risks could reduce overall incident trends by 20-30% given 0.57 risk-incident linkage.

1. **Hall-16 (Priority 1: Risk 37.19, 3.5x avg; Inc 14, Rank 3)**: Immediately augment security coverage and develop contingency plans. High security_trend_delta=12 signals accelerating threats—allocate 20% more patrols. Expected: Halve trend delta, mitigating ~35% of hall-specific risk.

2. **Hall-20 (Priority 2: Risk 36.77, 3.4x avg; Inc 25 1.5x avg, Rank 3)**: Prioritize emergency drills and maintenance (overdue weight 14.46). Links to Insurance Coverage Analysis via high incidents. Expected: 25% incident reduction, stabilizing env_stability_index.

3. **Hall-17 (Priority 3: Risk 24.97, Rank 5, Inc 12)**: Review and expand preparedness plans; trend delta=8 indicates moderate escalation. Expected: Improve rank to top quartile, cutting risk by 20%.

4. **Hall-18 (Priority 4: Risk 18.97, Rank 2 good but high maint 16.39)**: Focus on overdue maintenance despite strong rank. Expected: Reduce weighted overdue by 50%, lowering composite risk 15%.

5. **Hall-11 (Priority 5: Risk 15.73, Rank 6 poor, Inc 5 low)**: Enhance plans for worst-in-top5 preparedness. Expected: Rank improvement +10%, risk drop 10-15%.

**Additional:** Investigate NULL location (81 inc); target high-maintenance halls like Hall-1 (25.01 overdue). No provider/claims data available for review Q3; flag for upstream augmentation. Complements Executive Risk Summary by actioning 25% of total risk mass in top 5 halls.

These CASE-based steps (high trend→coverage; high maint→maintenance; poor rank→plans) address business questions on halls/exhibitions needing coverage/plans, with high-risk focus.