export const longestSingleSession = (userId: string, date: string) => `
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