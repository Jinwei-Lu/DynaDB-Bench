CREATE OR REPLACE VIEW "stg_emergency_plans" AS
SELECT
  "Plan_Protocol_Code",
  "plan_for_hall",
  "EMERGENCY_TYPE",
  "plan_name",
  "primary_responder_staff",
  "is_active",
  "plan_versioning"->>'plan_version' AS plan_version
FROM "EmergencyPlans";