import { supabase, pool } from '../config/config';

async function getEntries(userId: string, date: string) {
  const { data, error } = await supabase
    .from('entry')
    .select('*')
    .eq('user_id', userId)
    .eq('date', date);

  if (error) throw error;
  return data;
}
async function createEntry(userId: string, start_time: string, end_time: string, category: string) {
  try {
    const { rows } = await pool.query(
      'INSERT INTO entry (user_id, start_time, end_time, category) VALUES ($1, $2, $3, $4) RETURNING *',
      [userId, start_time, end_time, category]
    );
    return rows[0];
  } catch (err) {
    console.error(err);
    throw err;
  }
}

function updateEntry(userId: string) {
    return "update"
}

function deleteEntry(userId: string) {
    return "delete"
}

export { getEntries, createEntry, updateEntry, deleteEntry };