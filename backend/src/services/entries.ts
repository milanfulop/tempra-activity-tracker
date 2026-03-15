import { supabase, pool } from '../config/config';
import Entry from '../types/entry';
import User from '../types/user';

async function getEntries(userId: User['id'], date: string): Promise<Entry[]> {
  console.log(typeof(date), typeof(userId))
  const { data, error } = await supabase
    .from('entry')
    .select('*')
    .eq('user_id', userId)
    .eq('created_at', date);

  if (error) throw error;
  return data as Entry[];
}

async function createEntry(userId: User['id'], start_time: Entry['start_time'], end_time: Entry['end_time'], category: Entry['category']): Promise<Entry> {
  try {
    const { rows } = await pool.query(
      'INSERT INTO entry (user_id, start_time, end_time, category) VALUES ($1, $2, $3, $4) RETURNING *',
      [userId, start_time, end_time, category]
    );
    return rows[0] as Entry;
  } catch (err) {
    console.error(err);
    throw err;
  }
}

function updateEntry(userId: User['id']): string {
    return "update"
}

function deleteEntry(userId: User['id']): string {
    return "delete"
}

export { getEntries, createEntry, updateEntry, deleteEntry };