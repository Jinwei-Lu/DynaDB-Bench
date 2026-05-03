CREATE OR REPLACE VIEW "int_exhibition_risk_profile" AS
WITH policy_agg AS (
  SELECT
    "policy_for_exhibition",
    COUNT(*)::INTEGER AS num_policies,
    SUM("total_coverage_value_usd") AS total_coverage_value_usd
  FROM "stg_insurance_policies"
  WHERE "policy_for_exhibition" IS NOT NULL
  GROUP BY "policy_for_exhibition"
),
plan_agg AS (
  SELECT
    "plan_for_hall",
    COUNT(*)::INTEGER AS num_emergency_plans
  FROM "stg_emergency_plans"
  GROUP BY "plan_for_hall"
)
SELECT
  e."Exhibition_Catalog_Code",
  e."location_in_hall",
  COALESCE(p.total_coverage_value_usd, 0::NUMERIC) AS total_coverage_value_usd,
  COALESCE(p.num_policies, 0::INTEGER) AS num_policies,
  COALESCE(pl.num_emergency_plans, 0::INTEGER) AS num_emergency_plans,
  ROUND(
    ((e."actual_cost"::NUMERIC - e."BUDGET_USD"::NUMERIC) / e."BUDGET_USD"::NUMERIC * 100),
    2
  ) AS budget_variance_pct,
  ROUND(
    COALESCE(pl.num_emergency_plans, 0)::NUMERIC *
    COALESCE(p.total_coverage_value_usd / NULLIF(p.num_policies::NUMERIC, 0), 0::NUMERIC) /
    e."BUDGET_USD"::NUMERIC,
    2
  ) AS risk_preparedness_score
FROM "stg_exhibitions" e
LEFT JOIN policy_agg p ON p."policy_for_exhibition" = e."Exhibition_Catalog_Code"
LEFT JOIN plan_agg pl ON pl."plan_for_hall" = e."location_in_hall";