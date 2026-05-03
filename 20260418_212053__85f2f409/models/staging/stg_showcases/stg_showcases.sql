CREATE OR REPLACE VIEW "stg_showcases" AS
SELECT
  s."caseID",
  s."hall_ref",
  h."Hall_ID",
  (s."case_environment_profile" -> 'maintenance' ->> 'maint_status') AS maint_status,
  (s."case_environment_profile" -> 'maintenance' ->> 'filter_status') AS filter_status,
  (s."case_environment_profile" -> 'maintenance' ->> 'silica_status') AS silica_status,
  (s."case_environment_profile" -> 'maintenance' ->> 'silica_last_replaced')::date AS silica_last_replaced,
  (s."case_environment_profile" -> 'physical_state' ->> 'seal_state') AS seal_state,
  (s."case_environment_profile" -> 'physical_state' ->> 'leak_rate_per_day')::numeric AS leak_rate_per_day,
  (h."security_visitor_overview" -> 'security' ->> 'alarm_status') AS alarm_status
FROM "Showcases" s
JOIN "ExhibitionHalls" h ON s."hall_ref" = h."Hall_ID";