CREATE OR REPLACE VIEW "int_priority_metrics" AS
WITH risk_metrics AS (
  SELECT avg("likelihoodScore"::numeric * "impactScore"::numeric / 121.0) AS risk_composite
  FROM "stg_riskdetails"
),
maintenance_metrics AS (
  SELECT avg(
    CASE 
      WHEN "nextClean" IS NOT NULL AND "nextClean" < CURRENT_DATE 
      THEN (CURRENT_DATE - "nextClean")
      ELSE 0 
    END
  ) AS overdue_days
  FROM "stg_maintenance"
),
stability_metrics AS (
  SELECT avg("weighted_sesr_score") AS stability_score
  FROM "int_daily_stability_metrics"
),
radiation_metrics AS (
  SELECT avg("overall_radiation_risk_index") AS radiation_risk_index
  FROM "int_radiation_risk"
),
artifact_base AS (
  SELECT 
    *,
    CASE
      WHEN lower("art_title") LIKE '%painting%' THEN 'painting'
      WHEN lower("art_title") LIKE '%sculpture%' THEN 'sculpture'
      ELSE 'other'
    END AS category,
    'unknown' AS hall_id,
    CASE upper(coalesce("ENVsense", '')) 
      WHEN 'HIGH' THEN 'high' 
      ELSE 'low' 
    END AS sensitivity,
    CASE
      WHEN lower("art_title") LIKE '%painting%' THEN 1.3
      WHEN lower("art_title") LIKE '%sculpture%' THEN 1.1
      ELSE 1.0
    END AS category_multiplier,
    coalesce((rating_profile->>'exhibit_value')::numeric, 0) +
    coalesce((rating_profile->>'cultural_score')::numeric, 0) +
    coalesce((rating_profile->>'research_score')::numeric, 0) +
    coalesce((rating_profile->>'educational_value')::numeric, 0) +
    coalesce((rating_profile->>'public_access_rating')::numeric, 0) / 5.0 AS avg_rating,
    0.0 AS lag_trend_factor
  FROM "stg_artifacts"
),
enriched AS (
  SELECT 
    ab.*,
    rm.risk_composite,
    mm.overdue_days,
    greatest(mm.overdue_days / 90.0, 1.0) AS overdue_normalized,
    st.stability_score,
    rad.radiation_risk_index,
    0.35 * (100.0 - coalesce("conserve_score"::numeric, 50.0)) +
    0.25 * coalesce(rm.risk_composite, 0.0) +
    0.20 * greatest(mm.overdue_days / 90.0, 1.0) +
    0.10 * coalesce(st.stability_score, 0.0) +
    0.10 * coalesce(rad.radiation_risk_index, 0.0) AS cpi,
    ab.avg_rating * case ab.sensitivity when 'high' then 1.5 else 1 end * ab.category_multiplier * (1 + ab.lag_trend_factor) AS avs
  FROM artifact_base ab
  CROSS JOIN risk_metrics rm
  CROSS JOIN maintenance_metrics mm
  CROSS JOIN stability_metrics st
  CROSS JOIN radiation_metrics rad
),
trends AS (
  SELECT 
    *,
    lag("conserve_score") OVER (PARTITION BY "ARTregID" ORDER BY "ageYears" DESC) AS lag_conserve_score,
    null::numeric AS lag_radiation_exposure,
    coalesce("conserve_score"::numeric, 50.0) - coalesce(lag("conserve_score") OVER (PARTITION BY "ARTregID" ORDER BY "ageYears" DESC), coalesce("conserve_score"::numeric, 50.0)) AS conserve_trend_delta
  FROM enriched
)
SELECT 
  *,
  ntile(5) OVER (PARTITION BY category, hall_id ORDER BY cpi ASC, avs DESC) AS priority_rank,
  case when cpi > 60 then 'urgent' else 'normal' end AS urgency_flag,
  case when avs > 85 and cpi < 40 then 'rotate' else 'keep' end AS rotation_flag,
  case when conserve_trend_delta < -10 then 'rapid_deterioration' else 'stable' end AS deterioration_flag
FROM trends;