CREATE OR REPLACE VIEW "int_radiation_risk" AS
WITH light_enriched AS (
  SELECT
    "showcaseId",
    COALESCE("uvAWM2", 0) AS uvAWM2_raw,
    "visibleLightLux",
    "filterStatus",
    CASE
      WHEN "filterStatus" = 'Installed' THEN COALESCE("uvAWM2", 0) * 1.0
      ELSE COALESCE("uvAWM2", 0) * 1.5
    END AS filter_adjusted_uv,
    "measurementTimestamp"::time AS meas_time
  FROM "stg_light_radiation"
  WHERE "uvAWM2" IS NOT NULL OR "visibleLightLux" IS NOT NULL
),
light_rolling AS (
  SELECT *,
    AVG(filter_adjusted_uv) OVER (
      PARTITION BY "showcaseId" 
      ORDER BY meas_time 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS avg_uv_7day,
    SUM(filter_adjusted_uv) OVER (
      PARTITION BY "showcaseId" 
      ORDER BY meas_time 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS cumulative_exposure_7d,
    AVG("visibleLightLux") OVER (
      PARTITION BY "showcaseId" 
      ORDER BY meas_time 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS vis_light_7day_avg
  FROM light_enriched
),
light_lagged AS (
  SELECT *,
    LAG(avg_uv_7day, 1) OVER (
      PARTITION BY "showcaseId" 
      ORDER BY meas_time
    ) AS lag_avg_uv_7day
  FROM light_rolling
),
light_profile AS (
  SELECT DISTINCT ON ("showcaseId")
    "showcaseId",
    filter_adjusted_uv,
    avg_uv_7day,
    lag_avg_uv_7day,
    cumulative_exposure_7d,
    vis_light_7day_avg,
    CASE 
      WHEN avg_uv_7day > COALESCE(lag_avg_uv_7day, 0) * 1.2 THEN 1 
      ELSE 0 
    END AS trend_spike_flag
  FROM light_lagged
  ORDER BY "showcaseId", meas_time DESC
),
airq_profile AS (
  SELECT
    "case_link" AS showcaseId,
    AVG("RH")::numeric AS avg_humidity_pct,
    AVG("RHvar")::numeric AS humidity_dev,
    AVG(COALESCE("tempVar24", 0)) AS temp_dev,
    CASE 
      WHEN AVG("RH") > 70 THEN 1.2 
      ELSE 1.0 
    END AS env_modifier
  FROM "stg_env_airq_readings"
  GROUP BY "case_link"
),
artifact_profile AS (
  SELECT
    AVG("conserve_score")::numeric AS avg_conserve_score,
    AVG(
      CASE 
        WHEN (env_handling_sensitivity -> 'environment' ->> 'light') = 'High' THEN 3.0
        WHEN (env_handling_sensitivity -> 'environment' ->> 'light') = 'Medium' THEN 2.0
        WHEN (env_handling_sensitivity -> 'environment' ->> 'light') = 'Low' THEN 1.0
        ELSE 1.5
      END
    )::numeric AS avg_light_sens
  FROM "stg_artifacts"
)
SELECT
  s."caseID" AS showcaseId,
  s."hall_ref",
  s."Hall_ID",
  s."maint_status",
  s."filter_status" AS showcase_filter_status,
  COALESCE(lp.filter_adjusted_uv, 0) AS filter_adjusted_uv,
  COALESCE(lp.vis_light_7day_avg, 0) AS vis_light_7day_avg,
  COALESCE(lp.cumulative_exposure_7d, 0) AS cumulative_exposure_7d,
  COALESCE(lp.avg_uv_7day, 0) AS avg_uv_7day,
  COALESCE(lp.trend_spike_flag, 0) AS trend_spike_flag,
  COALESCE(ap.avg_humidity_pct, 50) AS avg_humidity_pct,
  COALESCE(ap.humidity_dev, 0) + COALESCE(ap.temp_dev, 0) AS env_dev_score,
  COALESCE(ap.env_modifier, 1.0) AS env_modifier,
  COALESCE(art.avg_conserve_score, 50) AS avg_conserve_score,
  COALESCE(art.avg_light_sens, 1.5) AS avg_light_sens,
  COALESCE(art.avg_light_sens, 1.5) * (1.0 + 0.1 * COALESCE(ap.humidity_dev, 0)) AS artifact_risk_factor,
  (1.0 - LEAST(COALESCE(art.avg_conserve_score, 50) / 100.0, 1.0)) * COALESCE(art.avg_light_sens, 1.5) AS artifact_sens_weight,
  CASE 
    WHEN COALESCE(lp.filter_adjusted_uv, 0) > 5 OR COALESCE(lp.vis_light_7day_avg, 0) > 50 THEN 'High'
    ELSE 'Low'
  END AS base_risk_level,
  0.5 * COALESCE(lp.cumulative_exposure_7d, lp.filter_adjusted_uv, 0) +
  0.25 * (COALESCE(ap.humidity_dev, 0) + COALESCE(ap.temp_dev, 0)) +
  0.25 * (1.0 - LEAST(COALESCE(art.avg_conserve_score, 50) / 100.0, 1.0)) * COALESCE(art.avg_light_sens, 1.5) AS overall_radiation_risk_index,
  SUM(
    0.5 * COALESCE(lp.cumulative_exposure_7d, lp.filter_adjusted_uv, 0) +
    0.25 * (COALESCE(ap.humidity_dev, 0) + COALESCE(ap.temp_dev, 0)) +
    0.25 * (1.0 - LEAST(COALESCE(art.avg_conserve_score, 50) / 100.0, 1.0)) * COALESCE(art.avg_light_sens, 1.5)
  ) OVER (ORDER BY s."caseID") AS running_risk_total
FROM "stg_showcases" s
LEFT JOIN light_profile lp ON s."caseID" = lp."showcaseId"
LEFT JOIN airq_profile ap ON s."caseID" = ap.showcaseId
CROSS JOIN artifact_profile art;