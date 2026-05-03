CREATE OR REPLACE VIEW "mart_showcase_stability" AS
WITH base AS (
  SELECT 
    d."caseID",
    s."Hall_ID" AS hall_id,
    d."reading_date" AS assessment_date,
    COALESCE(d."temp_variance_7d", 0) AS temp_variance_7d,
    d."pm25_index",
    d."rad_risk_score",
    s."maint_status",
    COALESCE(r."overall_radiation_risk_index", d."rad_risk_score") AS radiation_risk,
    COALESCE(r."filter_adjusted_uv", 0) AS filter_adjusted_uv,
    COALESCE(r."vis_light_7day_avg", 0) AS vis_light_7day_avg,
    d."weighted_sesr_score",
    d."sesr_lag_change"
  FROM "int_daily_stability_metrics" d 
  INNER JOIN "stg_showcases" s ON s."caseID" = d."caseID"
  LEFT JOIN "int_radiation_risk" r ON r."showcaseid" = d."caseID"
  LEFT JOIN "int_summaries" i ON i.category = s."Hall_ID"
),
derived AS (
  SELECT *,
    CASE WHEN "pm25_index" > 25 THEN 0.0 ELSE LEAST(50.0, 50.0 - "pm25_index" * 2) END AS airq_score,
    CASE WHEN temp_variance_7d > 5 THEN 0.0 ELSE LEAST(50.0, 50.0 - temp_variance_7d * 5) END AS env_score,
    CASE WHEN "rad_risk_score" > 0.5 THEN 0.0 ELSE LEAST(50.0, 50.0 - "rad_risk_score" * 100) END AS risk_score,
    CASE WHEN "maint_status" = 'Overdue' THEN true ELSE false END AS maint_overdue
  FROM base
),
sesr_cte AS (
  SELECT *,
    0.4 * airq_score + 0.3 * env_score + 0.3 * risk_score AS sesr
  FROM derived
),
lagged AS (
  SELECT *,
    LAG(radiation_risk) OVER (PARTITION BY "caseID" ORDER BY assessment_date) AS lag_rad_risk
  FROM sesr_cte
),
adjusted AS (
  SELECT *,
    radiation_risk + (CASE WHEN maint_overdue THEN 1.2 ELSE 1.0 END * COALESCE(lag_rad_risk, radiation_risk)) AS adj_threat
  FROM lagged
),
ma_window AS (
  SELECT *,
    AVG(sesr) OVER (PARTITION BY "caseID" ORDER BY assessment_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sesr_ma7,
    AVG(adj_threat) OVER (PARTITION BY "caseID" ORDER BY assessment_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS tetl_ma7
  FROM adjusted
)
SELECT 
  "caseID",
  hall_id,
  assessment_date,
  sesr,
  tetl_ma7 AS tetl,
  sesr_ma7,
  radiation_risk - COALESCE(lag_rad_risk, radiation_risk) AS threat_accel,
  RANK() OVER (PARTITION BY hall_id ORDER BY sesr DESC) AS hall_peer_rank,
  SUM(filter_adjusted_uv + vis_light_7day_avg) OVER (PARTITION BY "caseID" ORDER BY assessment_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS running_exposure_30d,
  CASE WHEN sesr < 4 OR tetl_ma7 > 15 THEN 1 ELSE 0 END AS anomaly_flag,
  maint_overdue::int AS maint_risk_flag,
  "weighted_sesr_score",
  radiation_risk,
  "sesr_lag_change"
FROM ma_window
ORDER BY assessment_date, "caseID";