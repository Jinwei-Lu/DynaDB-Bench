CREATE OR REPLACE VIEW "mart_risk_management_dashboard" AS
WITH security_latest AS (
  SELECT 
    "hall_ref" AS location_in_hall,
    "incident_count" - COALESCE("lag_1m_count", 0) AS security_trend_delta,
    "running_total_incidents",
    "preparedness_index",
    "weighted_severity_score" AS security_rate,
    ROW_NUMBER() OVER (PARTITION BY "hall_ref" ORDER BY "month_year" DESC) AS rn 
  FROM "int_security_metrics"
),
sec AS (SELECT * FROM security_latest WHERE rn = 1),
exh_agg AS (
  SELECT 
    "location_in_hall", 
    AVG(ABS("budget_variance_pct")) AS financial_exposure,
    AVG("risk_preparedness_score") AS exhibition_preparedness
  FROM "int_exhibition_risk_profile" 
  GROUP BY 1
),
rad_agg AS (
  SELECT 
    "hall_ref" AS location_in_hall, 
    AVG("env_dev_score") AS radiation_exposure,
    COUNT(*) FILTER (WHERE "maint_status" = 'Overdue')::numeric / COUNT(*) AS maintenance_overdue_ratio,
    AVG("avg_conserve_score") AS avg_conserve_score,
    COUNT(*) AS showcase_count
  FROM "int_radiation_risk" 
  GROUP BY 1 
),
env_data AS (
  SELECT 
    r."hall_ref" AS location_in_hall, 
    d."reading_date", 
    d."pm25_index", 
    COALESCE(r."avg_uv_7day", 0) AS uv_radiation,
    COALESCE(r."vis_light_7day_avg", 0) AS lux_exposure
  FROM "int_daily_stability_metrics" d 
  JOIN "int_radiation_risk" r ON d."caseID" = r."showcaseid"
),
env_window AS (
  SELECT *,
    AVG("pm25_index" + "uv_radiation" + "lux_exposure") OVER (
      PARTITION BY location_in_hall 
      ORDER BY "reading_date" 
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS env_stability_raw
  FROM env_data
),
env_latest AS (
  SELECT DISTINCT ON (location_in_hall) 
    location_in_hall, 
    env_stability_raw AS env_stability_index
  FROM env_window 
  ORDER BY location_in_hall, "reading_date" DESC
),
joined AS (
  SELECT 
    s.*,
    COALESCE(e.financial_exposure, 0) AS financial_exposure,
    COALESCE(e.exhibition_preparedness, 0) AS exhibition_preparedness,
    COALESCE(r.radiation_exposure, 0) AS radiation_exposure,
    COALESCE(r.maintenance_overdue_ratio, 0) AS maintenance_overdue_ratio,
    COALESCE(r.avg_conserve_score, 0) AS avg_conserve_score,
    COALESCE(r.showcase_count, 0) AS showcase_count,
    COALESCE(env.env_stability_index, 1) AS env_stability_index,
    CASE 
      WHEN COALESCE(r.showcase_count, 0) > 50 THEN 'Large'
      WHEN COALESCE(r.showcase_count, 0) > 40 THEN 'Medium' 
      ELSE 'Small' 
    END AS hall_size_bucket
  FROM sec s 
  LEFT JOIN exh_agg e ON s.location_in_hall = e."location_in_hall"
  LEFT JOIN rad_agg r ON s.location_in_hall = r.location_in_hall
  LEFT JOIN env_latest env ON s.location_in_hall = env.location_in_hall
)
SELECT 
  location_in_hall,
  CASE 
    WHEN maintenance_overdue_ratio > 0.3 AND radiation_exposure > 5 
    THEN (financial_exposure * 0.25 + security_rate * 0.30 + env_stability_index * 0.25 + maintenance_overdue_ratio * 0.10 + preparedness_index * 0.10) * 1.5 
    ELSE (financial_exposure * 0.25 + security_rate * 0.30 + env_stability_index * 0.25 + maintenance_overdue_ratio * 0.10 + preparedness_index * 0.10)
  END AS composite_risk_score,
  security_trend_delta,
  running_total_incidents,
  ROW_NUMBER() OVER (PARTITION BY hall_size_bucket ORDER BY exhibition_preparedness ASC) AS preparedness_rank,
  env_stability_index,
  maintenance_overdue_ratio * avg_conserve_score AS maintenance_overdue_weighted,
  CASE 
    WHEN (financial_exposure * 0.25 + security_rate * 0.30 + env_stability_index * 0.25 + maintenance_overdue_ratio * 0.10 + preparedness_index * 0.10) > 75 THEN 'Critical'
    WHEN security_trend_delta > 0.2 THEN 'Escalating'
    ELSE 'Stable'
  END AS risk_category_flag
FROM joined 
ORDER BY location_in_hall;