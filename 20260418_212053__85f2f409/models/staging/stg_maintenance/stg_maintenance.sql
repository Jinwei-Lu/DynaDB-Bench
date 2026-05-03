CREATE OR REPLACE VIEW "stg_maintenance" AS
SELECT
  "maint_id"
  , "prio_tag"
  , "treat_stat"
  , "lastClean"
  , "nextClean"
  , "cleanDays"
  , "incident_stat"
  , "conserveFreq"
FROM "ConservationAndMaintenance";