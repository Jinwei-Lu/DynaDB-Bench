CREATE OR REPLACE VIEW "stg_light_radiation" AS
SELECT
  "id",
  "showcaseId",
  "measurementTimestamp",
  CASE
    WHEN "visibleLightLux" ~ '^[0-9]+(\.[0-9]+)?$' THEN "visibleLightLux"::numeric
    ELSE NULL
  END AS "visibleLightLux",
  CASE
    WHEN "uvAWM2" ~ '^[0-9]+(\.[0-9]+)?$' THEN "uvAWM2"::numeric
    ELSE NULL
  END AS "uvAWM2",
  CASE
    WHEN "uvBWM2" ~ '^[0-9]+(\.[0-9]+)?$' THEN "uvBWM2"::numeric
    ELSE NULL
  END AS "uvBWM2",
  COALESCE("lightSourceType", 'Unknown') AS "lightSourceType",
  COALESCE("filterStatus", 'Unknown') AS "filterStatus"
FROM "LightRadiationLog"
-- Assumption 1: Safe casts on varchar metrics to numeric
-- Assumption 2: filterStatus != 'Installed' increases risk (preserved for downstream)
-- Assumption 3: visibleLightLux >50 or uvAWM2 >5 high exposure (preserved for downstream)
;
