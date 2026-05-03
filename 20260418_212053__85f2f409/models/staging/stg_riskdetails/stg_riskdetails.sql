CREATE OR REPLACE VIEW "stg_riskdetails" AS
SELECT
  "id",
  "conditionAssessmentId",
  CAST("assessmentDate" AS date) AS "assessmentDate",
  "riskCategory",
  CAST("likelihoodScore" AS integer) AS "likelihoodScore",
  CAST("impactScore" AS integer) AS "impactScore",
  "riskLevel",
  "residualRisk"
FROM "RiskAssessmentDetail"
WHERE "likelihoodScore" IS NOT NULL
  AND "impactScore" IS NOT NULL
  AND "likelihoodScore" ~ '^[0-9]+$'
  AND "impactScore" ~ '^[0-9]+$'
  -- Assumption 1: castable to int 1-11 (data shows 0-10)
  -- Assumption 2: No nulls in scores (filter enforces)
  -- Assumption 3: PhysicalDamage ~51% dominant (observed in source)
  -- Assumption 4: High likelihood with high impact in theft (cross-correlation observed, no filter needed for staging)
;