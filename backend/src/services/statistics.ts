import { bq } from '../config/config';
import { longestSingleSession, trackedTimePercent, timeDistribution } from '../queries/statistics';

type StatQuery = {
  query: (userId: string, date: string) => string;
  multiple?: boolean;
};

const statQueries: Record<string, StatQuery> = {
  longest_session: { query: longestSingleSession },
  tracked_time_percentage: { query: trackedTimePercent },
  time_distribution: { query: timeDistribution, multiple: true },
};

export async function getStats(userId: string, date: string, stats: string[]) {
  const result: Record<string, any> = {};

  for (const stat of stats) {
    const statQuery = statQueries[stat];
    if (!statQuery) {
      result[stat] = { error: 'Unknown stat' };
      continue;
    }
    const [rows] = await bq.query(statQuery.query(userId, date));
    result[stat] = statQuery.multiple ? rows : (rows[0] ?? null);
  }

  return result;
}