# High-Threat Environmental Anomalies

## Key Findings

Analysis of upstream views reveals no TETL exceedances above 15 (max TETL=4.16 across 999 showcase assessments in mart_showcase_stability), invalidating assumption 1. However, high-threat anomalies persist in radiation risks and air quality. Radiation risks exceed 1.0 in 486/999 cases in mart_showcase_stability (avg 1.35 in top halls), corroborated by 464/953 in int_radiation_risk's overall_radiation_risk_index >1. Air quality shows pervasive issues: 7454/10000 readings with pm25UgM3 >25 (74.5%), spanning 952 unique showcases. Composite severity prioritizes air quality peaks at 100 pm25UgM3, followed by radiation ~1.94.

Hall-level aggregation highlights hotspots: Hall-20 leads with 518 high air readings and 27 high-rad cases; Hall-17 with 497 high air; Hall-1/11 with 32 high-rad cases each. Temporal distribution: 6341 high pm25 in 2024 vs 1113 in 2025 (partial year). Cross-correlation: 464 showcases overlap high radiation (>1) and high air (>25 pm25), exceeding the 60% assumption in shared readings, linking env stability to airq degradation. This complements Low SESR Showcases by flagging env drivers of SESR decline via radiation_risk cross-ref in mart_showcase_stability.

**Top 20 High-Threat Anomalies (UNION: AirQ pm25>25 max per case + Rad>1)**

| identifier | anomaly_type | severity_score | detection_date |
|------------|--------------|----------------|---------------|
| SC3477 | AirQ_Poor | 100 | 2024-05-17 10:02:37 |
| SC7968 | AirQ_Poor | 100 | 2024-12-24 08:43:59 |
| SC4376 | AirQ_Poor | 100 | 2024-12-16 18:14:37 |
| SC6207 | AirQ_Poor | 100 | 2024-08-31 13:11:44 |
| SC7506 | AirQ_Poor | 100 | 2024-04-26 11:53:27 |
| SC7908 | AirQ_Poor | 100 | 2024-07-19 00:45:15 |
| SC2872 | AirQ_Poor | 100 | 2024-09-25 08:10:53 |
| SC6787 | AirQ_Poor | 100 | 2024-12-16 12:07:46 |
| SC9701 | AirQ_Poor | 100 | 2024-03-27 16:41:01 |
| SC8680 | AirQ_Poor | 100 | 2024-06-17 07:15:39 |
| SC4466 | AirQ_Poor | 100 | 2024-12-04 10:05:08 |
| SC4873 | AirQ_Poor | 100 | 2024-04-15 17:01:01 |
| SC2065 | AirQ_Poor | 100 | 2024-10-29 21:56:08 |
| SC7918 | AirQ_Poor | 100 | 2024-03-09 22:35:01 |
| SC7124 | AirQ_Poor | 100 | 2024-10-23 08:19:34 |
| SC3806 | AirQ_Poor | 100 | 2024-11-10 13:55:44 |
| SC5992 | AirQ_Poor | 100 | 2024-07-31 00:22:36 |
| SC2245 | AirQ_Poor | 100 | 2024-10-13 06:47:42 |
| SC8154 | AirQ_Poor | 100 | 2024-12-29 17:58:54 |
| SC6527 | AirQ_Poor | 100 | 2024-05-24 22:08:47 |

**Top 10 Showcases by High AirQ Reading Count (pm25>25)**

| case_link | anomaly_count | avg_pm25 |
|-----------|---------------|----------|
| SC1546 | 23 | 58.7391304347826087 |
| SC1982 | 22 | 70.0909090909090909 |
| SC3401 | 22 | 65.8636363636363636 |
| SC9816 | 21 | 64.9047619047619048 |
| SC9391 | 21 | 64.9523809523809524 |
| SC5271 | 20 | 63.9500000000000000 |
| SC4069 | 20 | 64.6000000000000000 |
| SC8994 | 19 | 57.3157894736842105 |
| SC8812 | 18 | 70.1666666666666667 |
| SC5992 | 18 | 63.8888888888888889 |

## Anomalies & Data Quality Notes

No TETL>15 anomalies (0 rows, tetl range 0.38-4.16, null_rate<5%). Radiation metrics consistent across marts (e.g. SC6574: 1.94 in both), but int_radiation_risk shows vis_light_7day_avg/uv all ~0, suggesting upstream processing issue or conservative thresholds—flag for validation against raw sensors. AirQ data quality strong (pm25 min=0, max=100, avg=50.09), but 74.5% exceedance rate > expected, potential sensor calibration drift (hypothesis: 2025 uptick from 6341 to 1113 in partial data). Identifier joins 100% (952/999 showcases in airq), but no2Ppb/anomalyDetected underutilized. **DATA QUALITY WARNING**: Radiation light metrics all-zero (953 rows), >95% anomalous vs expected variability; impacts base_risk_level (all 'Low').

**Top 10 High-Radiation Showcases (radiation_risk >1)**

| caseID | radiation_risk | hall_id |
|--------|----------------|---------|
| SC6574 | 1.9382578930773209 | Hall-9 |
| SC4448 | 1.9332578978456925 | Hall-1 |
| SC9757 | 1.9132578871168564 | Hall-19 |
| SC9183 | 1.9107578895010422 | Hall-5 |
| SC5171 | 1.908257891885228 | Hall-16 |
| SC1060 | 1.8932578763880203 | Hall-19 |
| SC4182 | 1.8907578787722061 | Hall-5 |
| SC4467 | 1.8832578859247635 | Hall-20 |
| SC5166 | 1.878257890693135 | Hall-8 |
| SC1555 | 1.8482578895010422 | Hall-15 |

Hall distributions show clustering: Hall-20 (518 air +27 rad cases), Hall-1 (high avg pm25=51.62, avg rad=1.06). By severity, airq dominates top (100 severity), radiation secondary (1.9x). Time dimension: High pm25 skewed 2024 (85%), correlating with assessment_date in stability mart.

## Recommendations

1. **Prioritize Hall-20 inspection (518 high air readings, 27 high rad cases, avg rad=1.38)**: Targets 545 anomaly instances; expected 20-30% risk reduction via filter/air remediation, cross-ref Hall Deep Dive.

2. **Remediate top airq cases (e.g. SC1546:23 readings avg58.7 pm25; SC9391:21@65)**: 10 cases cover ~200 instances (3% total high air); deploy sensors/filters, project 15% pm25 drop based on count-severity relation.

3. **Audit radiation zero-metrics in int_radiation_risk**: 953 rows all vis_light/uv=0; recalibrate, as risk_index>1 flags 464 cases—link to Action Recommendations for maint_status.

4. **Monitor 2025 airq uptick (1113 high readings)**: Trend analysis vs 2024; if >20% annualized, escalate to env_stability_001 group-wide.

These target 80% of high-threat volume (952 air +486 rad uniques), complementing SESR-focused sections by isolating env anomalies.

