CREATE OR REPLACE VIEW "int_daily_stability_metrics" AS
WITH daily_airq AS (
  SELECT 
    "case_link" AS "caseID",
    DATE("readTS") AS "reading_date",
    AVG("TEMPc"::numeric) AS avg_temp,
    STDDEV("TEMPc"::numeric) AS temp_variance_daily,  -- temporary
    AVG("pm25UgM3") AS avg_pm25
  FROM "stg_env_airq_readings"
  GROUP BY 1, 2
),
temp_window AS (
  SELECT 
    *,
    STDDEV(avg_temp) OVER (
      PARTITION BY "caseID"
      ORDER BY "reading_date"
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS temp_variance_7d
  FROM daily_airq
),
artifact_summary AS (
  SELECT 
    COUNT(*)::integer AS artifact_count,
    AVG(COALESCE(1.0 - ("conserve_score"::numeric / 100.0), 0.5)) AS avg_artifact_sensitivity
  FROM "stg_artifacts"
),
rad_summary AS (
  SELECT 
    AVG("visibleLightLux" + COALESCE("uvAWM2", 0) + COALESCE("uvBWM2", 0)) AS avg_rad_total
  FROM "stg_light_radiation"
),
enriched AS (
  SELECT 
    t.*,
    COALESCE(r.avg_rad_total, 0)::numeric AS rad_exposure,
    a.artifact_count,
    a.avg_artifact_sensitivity
  FROM temp_window t
  CROSS JOIN rad_summary r
  CROSS JOIN artifact_summary a
),
risk_metrics AS (
  SELECT 
    *,
    CASE WHEN avg_pm25 > 25 THEN 1.0 ELSE avg_pm25 / 25.0 END AS pm25_index,  -- normalized 0-1
    GREATEST(0, LEAST(1, rad_exposure / 50.0)) AS rad_risk_score,  -- assume max 50
    GREATEST(0, LEAST(1, COALESCE(temp_variance_7d, 0) / 5.0)) AS temp_var_norm
  FROM enriched
),
base_risk AS (
  SELECT 
    *,
    0.4 * pm25_index + 0.3 * temp_var_norm + 0.3 * rad_risk_score AS base_env_risk
  FROM risk_metrics
),
sesr_calc AS (
  SELECT 
    *,
    100.0 * (1.0 - base_env_risk * (1.0 + 0.3 * avg_artifact_sensitivity)) AS raw_sesr
  FROM base_risk
)
SELECT 
  "caseID",
  "reading_date",
  avg_temp,
  temp_variance_7d,
  pm25_index,
  rad_risk_score,
  artifact_count,
  avg_artifact_sensitivity,
  GREATEST(0, LEAST(100, raw_sesr)) AS weighted_sesr_score,
  GREATEST(0, LEAST(100, raw_sesr)) - 
  LAG(GREATEST(0, LEAST(100, raw_sesr))) OVER (PARTITION BY "caseID" ORDER BY "reading_date") AS sesr_lag_change
FROM sesr_calc
ORDER BY "caseID", "reading_date";