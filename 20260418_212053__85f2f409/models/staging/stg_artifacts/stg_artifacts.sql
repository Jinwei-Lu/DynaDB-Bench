CREATE OR REPLACE VIEW "stg_artifacts" AS
SELECT
  ac."ARTregID",
  ac."art_title",
  ac."DYNASTY",
  ac."ageYears",
  ac."MatKind",
  ac."conserve_status",
  rr."risk_level",
  rr."conserve_score",
  ar."rating_profile",
  sd."ENVsense",
  sd."env_handling_sensitivity"
FROM "ArtifactsCore" ac
LEFT JOIN LATERAL (
  SELECT
    "risk_level",
    "conserve_score"
  FROM "RiskAssessments" r
  WHERE r."art_concern" = ac."ARTregID"
  ORDER BY "conserve_score" DESC NULLS LAST, "risk_id" ASC
  LIMIT 1
) rr ON true
LEFT JOIN "ArtifactRatings" ar ON ar."ART_link" = ac."ARTregID"
LEFT JOIN "SensitivityData" sd ON sd."ART_link" = ac."ARTregID";