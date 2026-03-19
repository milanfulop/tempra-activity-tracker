import { bq } from '../config/config';
import { longestSingleSession } from '../queries/statistics';

const statQueries: Record<string, (userId: string, date: string) => string> = {
  longest_session: longestSingleSession,
  // add more as implemented
};

export async function getStats(userId: string, date: string, stats: string[]) {
  const result: Record<string, any> = {};

  for (const stat of stats) {
    const query = statQueries[stat];
    if (!query) {
      result[stat] = { error: 'Unknown stat' };
      continue;
    }
    console.log(date, userId, stats)
    const [rows] = await bq.query(query(userId, date));
    result[stat] = rows[0] ?? null;
  }

  return result;
}   