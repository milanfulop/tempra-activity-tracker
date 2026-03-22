const dailySummary = (userId: string, date: string) => `
  WITH all_entries AS (
    SELECT
      e.duration_minutes,
      e.category_id,
      e.start_time,
      e.end_time,
      c.is_productive
    FROM \`activity-tracker-statistics.facts.fact_entries\` e
    JOIN \`activity-tracker-statistics.dims.dim_categories\` c
      ON e.category_id = c.category_id
    WHERE e.user_id = '${userId}'
      AND e.date_id = '${date}'
  ),
  totals AS (
    SELECT
      SUM(duration_minutes) AS total_tracked_minutes,
      SUM(IF(is_productive, duration_minutes, 0)) AS total_productive_minutes
    FROM all_entries
  ),
  longest AS (
    SELECT *
    FROM (
      SELECT
        category_id,
        start_time,
        end_time,
        duration_minutes,
        is_productive
      FROM all_entries
      ORDER BY duration_minutes DESC
      LIMIT 1
    )
  )
  SELECT
    ROUND(t.total_tracked_minutes / 1440 * 100, 2)                                  AS tracked_percent,
    t.total_tracked_minutes,
    ROUND(t.total_productive_minutes / NULLIF(t.total_tracked_minutes, 0) * 100, 2) AS productive_percent,
    t.total_productive_minutes,
    l.category_id                                                                     AS longest_category_id,
    l.start_time                                                                      AS longest_start_time,
    l.end_time                                                                        AS longest_end_time,
    l.duration_minutes                                                                AS longest_duration_minutes,
    l.is_productive                                                                   AS longest_is_productive
  FROM totals t, longest l
`

const timeDistribution = (userId: string, date: string) => `
  WITH category_totals AS (
    SELECT
      e.category_id,
      c.category_name,
      c.category_color,
      c.is_productive,
      c.is_sleep,
      SUM(e.duration_minutes) AS minutes
    FROM \`activity-tracker-statistics.facts.fact_entries\` e
    JOIN \`activity-tracker-statistics.dims.dim_categories\` c
      ON e.category_id = c.category_id
    WHERE e.user_id = '${userId}'
      AND e.date_id = '${date}'
    GROUP BY
      e.category_id,
      c.category_name,
      c.category_color,
      c.is_productive,
      c.is_sleep
  ),
  total AS (
    SELECT SUM(minutes) AS total_tracked_minutes
    FROM category_totals
  )
  SELECT
    category_id,
    category_name,
    category_color,
    is_productive,
    is_sleep,
    minutes,
    ROUND(minutes / 1440 * 100, 2) AS percent_of_day
  FROM category_totals, total

  UNION ALL

  SELECT
    'untracked'    AS category_id,
    'Untracked'    AS category_name,
    '#808080'      AS category_color,
    FALSE          AS is_productive,
    FALSE          AS is_sleep,
    1440 - total_tracked_minutes AS minutes,
    ROUND((1440 - total_tracked_minutes) / 1440 * 100, 2) AS percent_of_day
  FROM total
  ORDER BY minutes DESC
`

export { dailySummary, timeDistribution }