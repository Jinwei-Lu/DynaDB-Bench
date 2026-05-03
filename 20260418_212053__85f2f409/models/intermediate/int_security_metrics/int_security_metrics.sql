CREATE OR REPLACE VIEW "int_security_metrics" AS
WITH hall_prep AS (
  SELECT 
    COALESCE(p."plan_for_hall", s."hall_ref") AS hall_ref,
    AVG(CASE WHEN p."is_active" AND COALESCE(s."maint_status", 'Overdue') != 'Overdue' THEN 1.0::numeric ELSE 0.0::numeric END) AS prep_compliance
  FROM "stg_emergency_plans" p
  FULL OUTER JOIN "stg_showcases" s ON p."plan_for_hall" = s."hall_ref"
  GROUP BY COALESCE(p."plan_for_hall", s."hall_ref")
),
ins_agg AS (
  SELECT
    "policy_for_exhibition" AS exhibition_catalog_code,
    AVG("total_coverage_value_usd"::numeric) AS avg_total_coverage_usd
  FROM "stg_insurance_policies"
  WHERE "IS_ACTIVE" = true
  GROUP BY "policy_for_exhibition"
),
enriched AS (
  SELECT
    s."incidentType",
    s."severityLevel",
    e."Exhibition_Catalog_Code" AS exhibition_catalog_code,
    e."location_in_hall" AS hall_ref,
    TO_CHAR(e."start_date", 'YYYY-MM') AS month_year,
    CASE WHEN s."insuranceClaimFiled" IN ('Yes', 'Pending') THEN 1::numeric ELSE 0::numeric END AS claim_flag,
    LEAST(
      CASE s."alarmSystemResponse"
        WHEN 'Immediate' THEN 5::numeric
        WHEN 'Partial' THEN 15::numeric
        WHEN 'Delayed' THEN 45::numeric
        WHEN 'Failed' THEN 90::numeric
        WHEN 'NotTriggered' THEN 120::numeric
        ELSE 60::numeric
      END, 120::numeric
    ) AS response_time_min,
    CASE s."severityLevel"
      WHEN 'Critical' THEN 5::numeric
      WHEN 'High' THEN 10::numeric
      WHEN 'Medium' THEN 20::numeric
      WHEN 'Low' THEN 30::numeric
      WHEN 'Informational' THEN 60::numeric
      ELSE 60::numeric
    END AS planned_response_min,
    COALESCE(e."BUDGET_USD"::numeric, 0::numeric) AS est_exhibition_value_usd,
    COALESCE(ia.avg_total_coverage_usd, 0::numeric) AS avg_total_coverage_usd,
    COALESCE(hp.prep_compliance, 0::numeric) AS prep_compliance
  FROM "stg_security_events" s
  LEFT JOIN "stg_exhibitions" e ON s."staffCode" = e."curator_in_charge_stafftag"
  LEFT JOIN ins_agg ia ON e."Exhibition_Catalog_Code" = ia.exhibition_catalog_code
  LEFT JOIN hall_prep hp ON e."location_in_hall" = hp.hall_ref
),
monthly_metrics AS (
  SELECT
    "incidentType",
    "severityLevel",
    exhibition_catalog_code,
    hall_ref,
    month_year,
    COUNT(*) AS incident_count,
    ROUND(AVG(response_time_min)::numeric, 2) AS avg_response_time_min,
    ROUND(AVG(planned_response_min)::numeric, 2) AS avg_planned_response_min,
    SUM(claim_flag) AS claims_filed,
    AVG(est_exhibition_value_usd) AS est_exhibition_value_usd,
    AVG(avg_total_coverage_usd) AS avg_total_coverage_usd,
    MAX(prep_compliance) AS prep_compliance
  FROM enriched
  GROUP BY "incidentType", "severityLevel", exhibition_catalog_code, hall_ref, month_year
),
derived AS (
  SELECT *,
    CASE WHEN avg_planned_response_min > 0 THEN
      ROUND(((avg_response_time_min - avg_planned_response_min) / avg_planned_response_min * 100)::numeric, 2)
    ELSE NULL::numeric END AS response_delay_pct
  FROM monthly_metrics
)
SELECT 
  "incidentType",
  "severityLevel",
  exhibition_catalog_code,
  hall_ref,
  month_year,
  incident_count,
  incident_count * CASE "severityLevel" 
    WHEN 'Critical' THEN 10::numeric 
    WHEN 'High' THEN 5::numeric 
    WHEN 'Medium' THEN 2::numeric 
    WHEN 'Low' THEN 1::numeric 
    WHEN 'Informational' THEN 0.5::numeric
    ELSE 0::numeric END AS weighted_severity_score,
  avg_response_time_min,
  avg_planned_response_min,
  response_delay_pct,
  ROUND(claims_filed::numeric / NULLIF(incident_count::numeric, 0), 4) AS claim_rate,
  ROUND(
    (claims_filed::numeric / NULLIF(incident_count::numeric, 0)) * 
    (1::numeric - LEAST(avg_total_coverage_usd / NULLIF(est_exhibition_value_usd, 0::numeric), 1::numeric)), 4
  ) AS claim_rate_adjusted,
  LAG(incident_count, 1) OVER (
    PARTITION BY "incidentType", "severityLevel", exhibition_catalog_code 
    ORDER BY month_year
  ) AS lag_1m_count,
  CASE 
    WHEN LAG(incident_count, 1) OVER (
      PARTITION BY "incidentType", "severityLevel", exhibition_catalog_code 
      ORDER BY month_year
    ) > 0 
    THEN ROUND(
      ((incident_count::numeric - LAG(incident_count, 1) OVER (
        PARTITION BY "incidentType", "severityLevel", exhibition_catalog_code 
        ORDER BY month_year
      )::numeric) / LAG(incident_count, 1) OVER (
        PARTITION BY "incidentType", "severityLevel", exhibition_catalog_code 
        ORDER BY month_year
      )::numeric * 100::numeric)::numeric, 2
    )
    ELSE NULL::numeric
  END AS mom_growth_pct,
  SUM(incident_count) OVER (
    PARTITION BY "incidentType", exhibition_catalog_code 
    ORDER BY month_year 
    ROWS UNBOUNDED PRECEDING
  ) AS running_total_incidents,
  SUM(incident_count * CASE "severityLevel" 
    WHEN 'Critical' THEN 10::numeric 
    WHEN 'High' THEN 5::numeric 
    WHEN 'Medium' THEN 2::numeric 
    WHEN 'Low' THEN 1::numeric 
    WHEN 'Informational' THEN 0.5::numeric
    ELSE 0::numeric END) OVER (
    PARTITION BY "incidentType", exhibition_catalog_code 
    ORDER BY month_year 
    ROWS UNBOUNDED PRECEDING
  ) AS cumulative_weighted_severity,
  prep_compliance * GREATEST(0::numeric, (1::numeric - COALESCE(response_delay_pct, 0::numeric) / 100::numeric)) AS preparedness_index
FROM derived;