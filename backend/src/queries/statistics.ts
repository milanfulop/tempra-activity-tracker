const longestSingleSession = (userId: string, date: string) => `
  SELECT
    user_id,
    category_id,
    start_time,
    end_time,
    duration_minutes
  FROM \`activity-tracker-statistics.facts.fact_entries\`
  WHERE user_id = '${userId}'
    AND date_id = '${date}'
  ORDER BY duration_minutes DESC
  LIMIT 1
`

const trackedTimePercent = (userId: string, date: string) => `
  SELECT
    user_id,
    ROUND(SUM(duration_minutes) / 1440 * 100, 2) AS tracked_percent,
    SUM(duration_minutes) AS total_tracked_minutes
  FROM \`activity-tracker-statistics.facts.fact_entries\`
  WHERE user_id = '${userId}'
    AND date_id = '${date}'
  GROUP BY user_id
`

const timeDistribution = (userId: string, date: string) => `
  WITH category_totals AS (
    SELECT
      category_id,
      SUM(duration_minutes) AS minutes
    FROM \`activity-tracker-statistics.facts.fact_entries\`
    WHERE user_id = '${userId}'
      AND date_id = '${date}'
    GROUP BY category_id
  ),
  total AS (
    SELECT SUM(minutes) AS total_tracked_minutes
    FROM category_totals
  )
  SELECT
    category_id,
    minutes,
    ROUND(minutes / 1440 * 100, 2) AS percent_of_day
  FROM category_totals, total

  UNION ALL

  SELECT
    'untracked' AS category_id,
    1440 - total_tracked_minutes AS minutes,
    ROUND((1440 - total_tracked_minutes) / 1440 * 100, 2) AS percent_of_day
  FROM total
  ORDER BY minutes DESC
`

export {longestSingleSession, trackedTimePercent, timeDistribution}