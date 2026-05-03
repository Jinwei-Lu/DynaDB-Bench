CREATE OR REPLACE VIEW "stg_security_events" AS
SELECT
  si."id",
  si."incidentType",
  si."severityLevel",
  si."insuranceClaimFiled",
  si."alarmSystemResponse",
  erl."responseTeam",
  erl."evidencePreservation",
  si."staffCode"
FROM "SecurityIncident" si
LEFT JOIN LATERAL (
  SELECT
    "responseTeam",
    "evidencePreservation"
  FROM "EmergencyResponseLog" er
  WHERE er."incidentId" = si."id"
  ORDER BY er."id" ASC
  LIMIT 1
) erl ON true;