CREATE OR REPLACE VIEW "stg_insurance_policies" AS
SELECT
  "Policy_Contract_Num",
  "provider_name",
  "policy_type",
  "start_date",
  "end_date",
  "IS_ACTIVE",
  "policy_for_exhibition",
  ("policy_financials" ->> 'deductible_usd')::NUMERIC AS deductible_usd,
  ("policy_financials" ->> 'annual_premium_usd')::NUMERIC AS annual_premium_usd,
  ("policy_financials" ->> 'total_coverage_value_usd')::NUMERIC AS total_coverage_value_usd
FROM "InsurancePolicies"
WHERE NOT ("IS_ACTIVE" = true AND COALESCE(("policy_financials" ->> 'total_coverage_value_usd')::NUMERIC, 0) <= 0);