CREATE OR REPLACE VIEW "stg_env_airq_readings" AS
SELECT
    e."monitor_code",
    e."readTS",
    e."case_link",
    e."TEMPc",
    e."RH",
    e."tempVar24",
    e."RHvar",
    m."pm25UgM3"::numeric AS "pm25UgM3",
    m."no2Ppb"::numeric AS "no2Ppb",
    m."anomalyDetected"
FROM "AirQualityMonitor" m
JOIN "AirQualityReadings" a ON m."aqReadingId" = a."aq_id"
JOIN "EnvironmentalReadingsCore" e ON a."env_link" = e."monitor_code";