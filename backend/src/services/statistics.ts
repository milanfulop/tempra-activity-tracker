import { bq } from '../config/config';
import { dailySummary, timeDistribution } from '../queries/statistics';

type StatQuery = {
  query: (userId: string, date: string) => string;
  multiple?: boolean;
};

const statQueries: Record<string, StatQuery> = {
  daily_summary: { query: dailySummary },
  time_distribution: { query: timeDistribution, multiple: true },
};

export async function getStats(userId: string, date: string, stats: string[]) {
  const entries = await Promise.all(
    stats.map(async (stat) => {
      const statQuery = statQueries[stat];
      if (!statQuery) return [stat, { error: 'Unknown stat' }];
      const [rows] = await bq.query(statQuery.query(userId, date));
      return [stat, statQuery.multiple ? rows : (rows[0] ?? null)];
    })
  );

  return Object.fromEntries(entries);
}