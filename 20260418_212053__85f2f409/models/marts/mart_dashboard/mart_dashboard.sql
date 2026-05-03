CREATE OR REPLACE VIEW "mart_dashboard" AS
WITH p_stats AS (
  SELECT 
    MIN("conserve_score") AS min_cons,
    MAX("conserve_score") AS max_cons,
    MIN("risk_composite") AS min_risk,
    MAX("risk_composite") AS max_risk
  FROM "int_priority_metrics"
),
s_stats AS (
  SELECT 
    AVG("weighted_severity_score") AS avg_sec,
    MIN("weighted_severity_score") AS min_sec,
    MAX("weighted_severity_score") AS max_sec
  FROM "int_security_metrics"
),
base_enriched AS (
  SELECT 
    p.*,
    ps.min_cons, ps.max_cons, ps.min_risk, ps.max_risk,
    ss.avg_sec, ss.min_sec, ss.max_sec,
    CASE 
      WHEN ps.max_cons > ps.min_cons THEN 
        (COALESCE(p."conserve_score"::float8, (ps.min_cons + ps.max_cons)/2.0) - ps.min_cons) / (ps.max_cons - ps.min_cons) 
      ELSE 0.5 
    END AS norm_conserve,
    CASE 
      WHEN ps.max_risk > ps.min_risk THEN (p."risk_composite" - ps.min_risk) / (ps.max_risk - ps.min_risk) 
      ELSE 0.5 
    END AS norm_risk,
    CASE 
      WHEN ss.max_sec > ss.min_sec THEN (ss.avg_sec - ss.min_sec) / (ss.max_sec - ss.min_sec) 
      ELSE 0.5 
    END AS norm_sec,
    0.5 * CASE 
      WHEN ps.max_cons > ps.min_cons THEN 
        (COALESCE(p."conserve_score"::float8, (ps.min_cons + ps.max_cons)/2.0) - ps.min_cons) / (ps.max_cons - ps.min_cons) 
      ELSE 0.5 
    END +
    0.3 * CASE 
      WHEN ps.max_risk > ps.min_risk THEN (p."risk_composite" - ps.min_risk) / (ps.max_risk - ps.min_risk) 
      ELSE 0.5 
    END +
    0.2 * CASE 
      WHEN ss.max_sec > ss.min_sec THEN (ss.avg_sec - ss.min_sec) / (ss.max_sec - ss.min_sec) 
      ELSE 0.5 
    END AS composite_score
  FROM "int_priority_metrics" p
  CROSS JOIN p_stats ps
  CROSS JOIN s_stats ss
),
enriched AS (
  SELECT *,
    CASE 
      WHEN composite_score > 0.75 THEN 'High' 
      ELSE 'Low' 
    END AS priority_flag,
    CASE 
      WHEN COALESCE("overdue_days", 0) <= 0 THEN 0
      WHEN "overdue_days" <= 30 THEN 0.5  
      ELSE 1 
    END AS overdue_count,
    GREATEST(0, COALESCE("overdue_days", 0)) AS overdue_lag_days
  FROM base_enriched
),
enriched_trends AS (
  SELECT *,
    LAG(composite_score) OVER (PARTITION BY "category" ORDER BY "priority_rank", "ageYears") AS lag_composite,
    LAG("conserve_score") OVER (PARTITION BY "risk_level" ORDER BY "priority_rank", "ageYears") AS lag_conserve_prio
  FROM enriched
),
art_concern_agg AS (
  SELECT 
    "category" AS dimension_value,
    COUNT(*) AS total_artifacts,
    AVG(composite_score) AS avg_composite_score,
    AVG(overdue_lag_days) AS overdue_lag_avg,
    AVG("ageYears") AS avg_age_years,
    AVG("conserve_score") AS avg_conserve_score,
    SUM(overdue_count) AS overdue_total,
    COUNT(CASE WHEN priority_flag = 'High' THEN 1 END)::float8 / COUNT(*) * 100 AS high_priority_pct,
    MODE() WITHIN GROUP (ORDER BY "rotation_flag") AS rotation_flag
  FROM enriched_trends 
  GROUP BY "category"
),
art_concern_window AS (
  SELECT *,
    SUM(overdue_total) OVER (ORDER BY dimension_value ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_overdue_total
  FROM art_concern_agg
),
conserve_status_agg AS (
  SELECT 
    COALESCE("conserve_status", 'Unknown') AS dimension_value,
    COUNT(*) AS total_artifacts,
    AVG(composite_score) AS avg_composite_score,
    AVG(overdue_lag_days) AS overdue_lag_avg,
    AVG("conserve_score") AS avg_conserve_score,
    SUM(overdue_count) AS overdue_total,
    COUNT(CASE WHEN priority_flag = 'High' THEN 1 END)::float8 / COUNT(*) * 100 AS high_priority_pct,
    MODE() WITHIN GROUP (ORDER BY "rotation_flag") AS rotation_flag
  FROM enriched_trends 
  GROUP BY COALESCE("conserve_status", 'Unknown')
),
conserve_status_window AS (
  SELECT *,
    SUM(overdue_total) OVER (ORDER BY dimension_value ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_overdue_total
  FROM conserve_status_agg
),
prio_tag_agg AS (
  SELECT 
    "risk_level" AS dimension_value,
    COUNT(*) AS total_artifacts,
    AVG(composite_score) AS avg_composite_score,
    AVG(overdue_lag_days) AS overdue_lag_avg,
    AVG("conserve_score") AS avg_conserve_score,
    SUM(overdue_count) AS overdue_total,
    COUNT(CASE WHEN priority_flag = 'High' THEN 1 END)::float8 / COUNT(*) * 100 AS high_priority_pct,
    MODE() WITHIN GROUP (ORDER BY "rotation_flag") AS rotation_flag
  FROM enriched_trends 
  GROUP BY "risk_level"
),
prio_tag_window AS (
  SELECT *,
    SUM(overdue_total) OVER (ORDER BY dimension_value ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_overdue_total
  FROM prio_tag_agg
),
art_concern_metrics AS (
  SELECT 'art_concern' AS dimension, dimension_value, 'total_artifacts' AS metric_name, total_artifacts::numeric AS metric_value, avg_composite_score AS composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY avg_composite_score DESC) AS rank, rotation_flag FROM art_concern_window
  UNION ALL
  SELECT 'art_concern', dimension_value, 'avg_age_years', avg_age_years::numeric, avg_composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY avg_age_years DESC), rotation_flag FROM art_concern_window
  UNION ALL
  SELECT 'art_concern', dimension_value, 'avg_conserve_score', avg_conserve_score::numeric, avg_composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY avg_conserve_score DESC), rotation_flag FROM art_concern_window
  UNION ALL
  SELECT 'art_concern', dimension_value, 'high_priority_pct', high_priority_pct::numeric, avg_composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY high_priority_pct DESC), rotation_flag FROM art_concern_window
  UNION ALL
  SELECT 'art_concern', dimension_value, 'running_overdue_total', running_overdue_total::numeric, avg_composite_score, overdue_lag_avg, NULL::int AS rank, rotation_flag FROM art_concern_window
),
conserve_status_metrics AS (
  SELECT 'conserve_status' AS dimension, dimension_value, 'total_artifacts' AS metric_name, total_artifacts::numeric AS metric_value, avg_composite_score AS composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY avg_composite_score DESC) AS rank, rotation_flag FROM conserve_status_window
  UNION ALL
  SELECT 'conserve_status', dimension_value, 'avg_conserve_score', avg_conserve_score::numeric, avg_composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY avg_conserve_score DESC), rotation_flag FROM conserve_status_window
  UNION ALL
  SELECT 'conserve_status', dimension_value, 'high_priority_pct', high_priority_pct::numeric, avg_composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY high_priority_pct DESC), rotation_flag FROM conserve_status_window
  UNION ALL
  SELECT 'conserve_status', dimension_value, 'running_overdue_total', running_overdue_total::numeric, avg_composite_score, overdue_lag_avg, NULL::int, rotation_flag FROM conserve_status_window
),
prio_tag_metrics AS (
  SELECT 'prio_tag' AS dimension, dimension_value, 'total_artifacts' AS metric_name, total_artifacts::numeric AS metric_value, avg_composite_score AS composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY avg_composite_score DESC) AS rank, rotation_flag FROM prio_tag_window
  UNION ALL
  SELECT 'prio_tag', dimension_value, 'avg_conserve_score', avg_conserve_score::numeric, avg_composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY avg_conserve_score DESC), rotation_flag FROM prio_tag_window
  UNION ALL
  SELECT 'prio_tag', dimension_value, 'high_priority_pct', high_priority_pct::numeric, avg_composite_score, overdue_lag_avg, ROW_NUMBER() OVER (ORDER BY high_priority_pct DESC), rotation_flag FROM prio_tag_window
  UNION ALL
  SELECT 'prio_tag', dimension_value, 'running_overdue_total', running_overdue_total::numeric, avg_composite_score, overdue_lag_avg, NULL::int, rotation_flag FROM prio_tag_window
),
top_art_concern AS (
  SELECT 
    dimension, dimension_value, metric_name, metric_value, composite_score, rank, overdue_lag_avg, rotation_flag
  FROM (
    SELECT 
      'art_concern' AS dimension,
      "category" AS dimension_value,
      "art_title" AS metric_name,
      composite_score::numeric AS metric_value,
      composite_score,
      overdue_lag_days AS overdue_lag_avg,
      "rotation_flag",
      ROW_NUMBER() OVER (PARTITION BY "category" ORDER BY composite_score DESC NULLS LAST, "ARTregID") AS rank
    FROM enriched_trends
  ) ranked WHERE rank <= 10
),
top_conserve_status AS (
  SELECT 
    dimension, dimension_value, metric_name, metric_value, composite_score, rank, overdue_lag_avg, rotation_flag
  FROM (
    SELECT 
      'conserve_status' AS dimension,
      COALESCE("conserve_status", 'Unknown') AS dimension_value,
      "art_title" AS metric_name,
      composite_score::numeric AS metric_value,
      composite_score,
      overdue_lag_days AS overdue_lag_avg,
      "rotation_flag",
      ROW_NUMBER() OVER (PARTITION BY COALESCE("conserve_status", 'Unknown') ORDER BY composite_score DESC NULLS LAST, "ARTregID") AS rank
    FROM enriched_trends
  ) ranked WHERE rank <= 10
),
top_prio_tag AS (
  SELECT 
    dimension, dimension_value, metric_name, metric_value, composite_score, rank, overdue_lag_avg, rotation_flag
  FROM (
    SELECT 
      'prio_tag' AS dimension,
      "risk_level" AS dimension_value,
      "art_title" AS metric_name,
      composite_score::numeric AS metric_value,
      composite_score,
      overdue_lag_days AS overdue_lag_avg,
      "rotation_flag",
      ROW_NUMBER() OVER (PARTITION BY "risk_level" ORDER BY composite_score DESC NULLS LAST, "ARTregID") AS rank
    FROM enriched_trends
  ) ranked WHERE rank <= 10
),
globals AS (
  SELECT 
    COUNT(*)::numeric AS total_artifacts,
    AVG(composite_score)::numeric AS avg_composite_score,
    MAX(composite_score)::numeric AS max_composite_score,
    MIN(composite_score)::numeric AS min_composite_score,
    AVG(overdue_lag_days)::numeric AS overdue_lag_avg,
    COUNT(CASE WHEN composite_score > 0.75 THEN 1 END)::float8 / COUNT(*) * 100 AS high_composite_pct
  FROM enriched
),
global_kpis AS (
  SELECT 'global' AS dimension, NULL::text AS dimension_value, 'total_artifacts' AS metric_name, total_artifacts AS metric_value, avg_composite_score AS composite_score, overdue_lag_avg, NULL::int AS rank, NULL::text AS rotation_flag FROM globals
  UNION ALL
  SELECT 'global', NULL::text, 'avg_composite_score', avg_composite_score, avg_composite_score, overdue_lag_avg, NULL, NULL FROM globals
  UNION ALL
  SELECT 'global', NULL::text, 'max_composite_score', max_composite_score, avg_composite_score, overdue_lag_avg, NULL, NULL FROM globals
  UNION ALL
  SELECT 'global', NULL::text, 'min_composite_score', min_composite_score, avg_composite_score, overdue_lag_avg, NULL, NULL FROM globals
  UNION ALL
  SELECT 'global', NULL::text, 'high_composite_pct', high_composite_pct::numeric, avg_composite_score, overdue_lag_avg, NULL, NULL FROM globals
),
summary_agg AS (
  SELECT 
    summary_type AS dimension,
    category AS dimension_value,
    AVG(weighted_score)::numeric AS avg_weighted,
    AVG(overdue_rate)::numeric AS avg_overdue_rate,
    AVG(running_highrisk_count)::numeric AS avg_highrisk_count
  FROM "int_summaries"
  GROUP BY summary_type, category
),
summary_metrics AS (
  SELECT dimension, dimension_value, 'avg_weighted_score' AS metric_name, avg_weighted AS metric_value, avg_weighted AS composite_score, NULL::numeric AS overdue_lag_avg, NULL::int AS rank, NULL::text AS rotation_flag FROM summary_agg
  UNION ALL
  SELECT dimension, dimension_value, 'avg_overdue_rate', avg_overdue_rate, avg_weighted, NULL, NULL, NULL FROM summary_agg
  UNION ALL
  SELECT dimension, dimension_value, 'avg_highrisk_count', avg_highrisk_count, avg_weighted, NULL, NULL, NULL FROM summary_agg
)
SELECT * FROM art_concern_metrics
UNION ALL SELECT * FROM conserve_status_metrics
UNION ALL SELECT * FROM prio_tag_metrics
UNION ALL SELECT * FROM top_art_concern
UNION ALL SELECT * FROM top_conserve_status
UNION ALL SELECT * FROM top_prio_tag
UNION ALL SELECT * FROM global_kpis
UNION ALL SELECT * FROM summary_metrics
ORDER BY dimension, dimension_value NULLS LAST, metric_name, rank NULLS LAST;