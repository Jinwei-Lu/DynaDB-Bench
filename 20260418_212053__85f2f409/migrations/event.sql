-- Node 713b96d055d5: Fix false negative in risk_preparedness_score for uninsured budget overruns
UPDATE "Exhibitions" 
SET "actual_cost" = "BUDGET_USD" * 1.06
WHERE "Exhibition_Catalog_Code" IN ('EXH-2017-02', 'EXH-2020-02', 'EXH-2013-01')
  AND "EXHIBITION_STATUS" = 'Archived'
  AND NOT EXISTS (
    SELECT 1 FROM "stg_insurance_policies" p 
    WHERE p."policy_for_exhibition" = "Exhibitions"."Exhibition_Catalog_Code"
      AND p."total_coverage_value_usd" > 0
  );

-- Node 2ddce7f3abcd: Fix risk_preparedness_score false negative for uninsured budget overruns
UPDATE "Exhibitions" SET "actual_cost" = 520000.0 WHERE "Exhibition_Catalog_Code" = 'EXH-2017-02';
UPDATE "Exhibitions" SET "actual_cost" = 585000.0 WHERE "Exhibition_Catalog_Code" = 'EXH-2020-02';
UPDATE "Exhibitions" SET "actual_cost" = 1170000.0 WHERE "Exhibition_Catalog_Code" = 'EXH-2013-01';

-- Node 3d4d110a1de5: Fix risk_preparedness_score false negative for uninsured budget overruns
INSERT INTO "InsurancePolicies" ("Policy_Contract_Num", "POLICY_ID_CODE", "provider_name", "policy_type", "start_date", "end_date", "IS_ACTIVE", "policy_for_exhibition", "policy_updated_by", "policy_financials")
VALUES 
  ('POL-BR-001', 'BR-2017-02', 'Museum Mutual', 'Exhibition', '2017-01-01', '2018-12-31', true, 'EXH-2017-02', 2, '{"deductible_usd": 5000, "annual_premium_usd": 2500, "total_coverage_value_usd": 425000}'),
  ('POL-BR-002', 'BR-2020-02', 'Museum Mutual', 'Exhibition', '2020-01-01', '2021-12-31', true, 'EXH-2020-02', 2, '{"deductible_usd": 5000, "annual_premium_usd": 2500, "total_coverage_value_usd": 475000}'),
  ('POL-BR-003', 'BR-2013-01', 'Museum Mutual', 'Exhibition', '2013-01-01', '2014-12-31', true, 'EXH-2013-01', 2, '{"deductible_usd": 5000, "annual_premium_usd": 2500, "total_coverage_value_usd": 950000}');
DELETE FROM "InsurancePolicies" WHERE "Policy_Contract_Num" IN ('POL-BR-001', 'POL-BR-002', 'POL-BR-003');
