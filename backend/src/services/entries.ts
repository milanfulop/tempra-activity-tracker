import { pool } from '../config/config';
import Entry from '../types/entry';
import User from '../types/user';

async function getEntries(userId: User['id'], date: string): Promise<Entry[]> {
  const { rows } = await pool.query(
    'SELECT * FROM entry WHERE user_id = $1 AND created_at = $2',
    [userId, date]
  );
  return rows as Entry[];
}

async function createEntry(
  userId: User['id'],
  start_time: Entry['start_time'],
  end_time: Entry['end_time'],
  category_id: Entry['category_id']
): Promise<Entry> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const date = start_time.split('T')[0];

    // 1. Exact same start and end time -> just update category_id
    const { rows: exactMatch } = await client.query(
      `SELECT * FROM entry WHERE user_id = $1 AND created_at = $2 AND start_time = $3 AND end_time = $4`,
      [userId, date, start_time, end_time]
    );
    if (exactMatch.length > 0) {
      const { rows } = await client.query(
        `UPDATE entry SET category_id = $1 WHERE id = $2 RETURNING *`,
        [category_id, exactMatch[0].id]
      );
      await client.query('COMMIT');
      return rows[0];
    }

    // 2. Adjacent same-category_id block (existing end = new start) -> extend it
    const { rows: adjacent } = await client.query(
      `SELECT * FROM entry WHERE user_id = $1 AND created_at = $2 AND category_id = $3 AND end_time = $4`,
      [userId, date, category_id, start_time]
    );
    if (adjacent.length > 0) {
      const { rows } = await client.query(
        `UPDATE entry SET end_time = $1 WHERE id = $2 RETURNING *`,
        [end_time, adjacent[0].id]
      );
      await client.query('COMMIT');
      return rows[0];
    }

    // 3. Handle overlapping entries
    const { rows: overlapping } = await client.query(
      `SELECT * FROM entry WHERE user_id = $1 AND created_at = $2 AND start_time < $4 AND end_time > $3`,
      [userId, date, start_time, end_time]
    );

    for (const existing of overlapping) {
      const startsBeforeNew = existing.start_time < start_time;
      const endsAfterNew = existing.end_time > end_time;

      if (startsBeforeNew && endsAfterNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [start_time, existing.id]
        );
        await client.query(
          `INSERT INTO entry (user_id, created_at, start_time, end_time, category_id) VALUES ($1, $2, $3, $4, $5)`,
          [userId, date, end_time, existing.end_time, existing.category_id]
        );
      } else if (startsBeforeNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [start_time, existing.id]
        );
      } else if (endsAfterNew) {
        await client.query(
          `UPDATE entry SET start_time = $1 WHERE id = $2`,
          [end_time, existing.id]
        );
      } else {
        await client.query(`DELETE FROM entry WHERE id = $1`, [existing.id]);
      }
    }

    // 4. Insert new entry
    const { rows: inserted } = await client.query(
      `INSERT INTO entry (user_id, created_at, start_time, end_time, category_id) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, date, start_time, end_time, category_id]
    );

    await client.query('COMMIT');
    return inserted[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function deleteEntry(
  userId: User['id'],
  start_time: Entry['start_time'],
  end_time: Entry['end_time']
): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const date = start_time.split('T')[0];

    const { rows: overlapping } = await client.query(
      `SELECT * FROM entry WHERE user_id = $1 AND created_at = $2 AND start_time < $4 AND end_time > $3`,
      [userId, date, start_time, end_time]
    );

    for (const existing of overlapping) {
      const startsBeforeNew = existing.start_time < start_time;
      const endsAfterNew = existing.end_time > end_time;

      if (startsBeforeNew && endsAfterNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [start_time, existing.id]
        );
        await client.query(
          `INSERT INTO entry (user_id, created_at, start_time, end_time, category_id) VALUES ($1, $2, $3, $4, $5)`,
          [userId, date, end_time, existing.end_time, existing.category_id]
        );
      } else if (startsBeforeNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [start_time, existing.id]
        );
      } else if (endsAfterNew) {
        await client.query(
          `UPDATE entry SET start_time = $1 WHERE id = $2`,
          [end_time, existing.id]
        );
      } else {
        await client.query(`DELETE FROM entry WHERE id = $1`, [existing.id]);
      }
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export { getEntries, createEntry, deleteEntry };