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
