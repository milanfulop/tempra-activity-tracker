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
export {longestSingleSession, trackedTimePercent}