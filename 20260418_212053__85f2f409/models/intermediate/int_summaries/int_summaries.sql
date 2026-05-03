CREATE OR REPLACE VIEW "int_summaries" AS
WITH base AS (
  SELECT 
    r."riskCategory",
    m."prio_tag",
    a."MatKind",
    r."likelihoodScore",
    r."impactScore",
    m."cleanDays",
    date_trunc('month', r."assessmentDate") AS report_month,
    CASE 
      WHEN m."prio_tag" = 'Low' THEN 1
      WHEN m."prio_tag" = 'Medium' THEN 2
      WHEN m."prio_tag" = 'High' THEN 3
      WHEN m."prio_tag" = 'Urgent' THEN 4
      ELSE 0 
    END AS priority_num,
    CASE 
      WHEN COALESCE(m."cleanDays", 0) > 90 THEN 
        (CASE 
          WHEN m."prio_tag" = 'Low' THEN 1
          WHEN m."prio_tag" = 'Medium' THEN 2
          WHEN m."prio_tag" = 'High' THEN 3
          WHEN m."prio_tag" = 'Urgent' THEN 4
          ELSE 0 
        END) * 1.5 
      ELSE 
        (CASE 
          WHEN m."prio_tag" = 'Low' THEN 1
          WHEN m."prio_tag" = 'Medium' THEN 2
          WHEN m."prio_tag" = 'High' THEN 3
          WHEN m."prio_tag" = 'Urgent' THEN 4
          ELSE 0 
        END)
    END AS adjusted_priority,
    0.4 * 
      (CASE 
        WHEN COALESCE(m."cleanDays", 0) > 90 THEN 
          (CASE 
            WHEN m."prio_tag" = 'Low' THEN 1
            WHEN m."prio_tag" = 'Medium' THEN 2
            WHEN m."prio_tag" = 'High' THEN 3
            WHEN m."prio_tag" = 'Urgent' THEN 4
            ELSE 0 
          END) * 1.5 
        ELSE 
          (CASE 
            WHEN m."prio_tag" = 'Low' THEN 1
            WHEN m."prio_tag" = 'Medium' THEN 2
            WHEN m."prio_tag" = 'High' THEN 3
            WHEN m."prio_tag" = 'Urgent' THEN 4
            ELSE 0 
          END)
      END
    ) + 
    0.6 * (r."likelihoodScore" * r."impactScore" / 121.0) AS weighted_score_row,
    CASE WHEN COALESCE(m."cleanDays", 0) > 90 THEN 1 ELSE 0 END AS is_overdue,
    CASE 
      WHEN 0.4 * 
        (CASE 
          WHEN COALESCE(m."cleanDays", 0) > 90 THEN 
            (CASE WHEN m."prio_tag" = 'Low' THEN 1 WHEN m."prio_tag" = 'Medium' THEN 2 WHEN m."prio_tag" = 'High' THEN 3 WHEN m."prio_tag" = 'Urgent' THEN 4 ELSE 0 END) * 1.5 
          ELSE (CASE WHEN m."prio_tag" = 'Low' THEN 1 WHEN m."prio_tag" = 'Medium' THEN 2 WHEN m."prio_tag" = 'High' THEN 3 WHEN m."prio_tag" = 'Urgent' THEN 4 ELSE 0 END)
        END
      ) + 0.6 * (r."likelihoodScore" * r."impactScore" / 121.0) > 7.5 
      THEN 1 
      ELSE 0 
    END AS is_high_risk
  FROM "stg_riskdetails" r 
  INNER JOIN "stg_maintenance" m ON r."conditionAssessmentId" = m."maint_id"
  LEFT JOIN "stg_artifacts" a ON m."maint_id" = a."conserve_score"
  WHERE r."assessmentDate" IS NOT NULL 
    AND r."assessmentDate" >= '2021-01-01'
),
agg AS (
  SELECT 
    'risk_category' AS summary_type, 
    "riskCategory" AS category, 
    report_month, 
    AVG(weighted_score_row) AS weighted_score, 
    SUM(is_overdue)::float8 / COUNT(*) AS overdue_rate, 
    SUM(is_high_risk) AS highrisk_count
  FROM base 
  WHERE "riskCategory" IS NOT NULL 
  GROUP BY "riskCategory", report_month
  
  UNION ALL
  
  SELECT 
    'material_kind' AS summary_type, 
    "MatKind" AS category, 
    report_month, 
    AVG(weighted_score_row) AS weighted_score, 
    SUM(is_overdue)::float8 / COUNT(*) AS overdue_rate, 
    SUM(is_high_risk) AS highrisk_count
  FROM base 
  WHERE "MatKind" IS NOT NULL 
  GROUP BY "MatKind", report_month
  
  UNION ALL
  
  SELECT 
    'priority_level' AS summary_type, 
    "prio_tag" AS category, 
    report_month, 
    AVG(weighted_score_row) AS weighted_score, 
    SUM(is_overdue)::float8 / COUNT(*) AS overdue_rate, 
    SUM(is_high_risk) AS highrisk_count
  FROM base 
  WHERE "prio_tag" IS NOT NULL 
  GROUP BY "prio_tag", report_month
)
SELECT 
  summary_type, 
  category, 
  report_month, 
  weighted_score, 
  overdue_rate, 
  overdue_rate - LAG(overdue_rate, 1) OVER (PARTITION BY summary_type, category ORDER BY report_month) AS lag_diff_overdue, 
  SUM(highrisk_count) OVER (PARTITION BY summary_type ORDER BY report_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_highrisk_count
FROM agg 
ORDER BY summary_type, category, report_month;