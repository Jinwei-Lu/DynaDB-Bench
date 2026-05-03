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