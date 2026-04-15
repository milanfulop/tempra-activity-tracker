import { pool } from '../config/config';
import Entry from '../types/entry';
import User from '../types/user';

function getLocalDateString(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function normalizeEndTime(time: string): string {
  return time === '00:00:00' ? '23:59:59' : time;
}

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

    const date = getLocalDateString();
    const rawStart = start_time.includes('T') ? start_time.split('T')[1] : start_time;
    const rawEnd = end_time.includes('T') ? end_time.split('T')[1] : end_time;

    if (!rawStart || !rawEnd) {
      throw new Error(`Invalid time format: start=${start_time}, end=${end_time}`);
    }

    const startTimeOnly = rawStart;
    const endTimeOnly = normalizeEndTime(rawEnd);

    // 1. Exact match → just update category
    const { rows: exactMatch } = await client.query(
      `SELECT * FROM entry
       WHERE user_id = $1 AND created_at = $2
       AND start_time = $3 AND end_time = $4`,
      [userId, date, startTimeOnly, endTimeOnly]
    );

    if (exactMatch.length > 0) {
      const { rows } = await client.query(
        `UPDATE entry SET category_id = $1 WHERE id = $2 RETURNING *`,
        [category_id, exactMatch[0].id]
      );
      await client.query('COMMIT');
      return rows[0];
    }

    // 2. Trim/delete all overlapping entries
    const { rows: overlapping } = await client.query(
      `SELECT * FROM entry
       WHERE user_id = $1 AND created_at = $2
       AND start_time < $4 AND end_time > $3`,
      [userId, date, startTimeOnly, endTimeOnly]
    );

    for (const existing of overlapping) {
      const startsBeforeNew = existing.start_time < startTimeOnly;
      const endsAfterNew = existing.end_time > endTimeOnly;

      if (startsBeforeNew && endsAfterNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [startTimeOnly, existing.id]
        );
        await client.query(
          `INSERT INTO entry (user_id, created_at, start_time, end_time, category_id)
           VALUES ($1, $2, $3, $4, $5)`,
          [userId, date, endTimeOnly, existing.end_time, existing.category_id]
        );
      } else if (startsBeforeNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [startTimeOnly, existing.id]
        );
      } else if (endsAfterNew) {
        await client.query(
          `UPDATE entry SET start_time = $1 WHERE id = $2`,
          [endTimeOnly, existing.id]
        );
      } else {
        await client.query(
          `DELETE FROM entry WHERE id = $1`,
          [existing.id]
        );
      }
    }

    // 3. Check for adjacent same-category blocks and merge
    const { rows: leftAdjacent } = await client.query(
      `SELECT * FROM entry
       WHERE user_id = $1 AND created_at = $2
       AND category_id = $3 AND end_time = $4`,
      [userId, date, category_id, startTimeOnly]
    );
    const { rows: rightAdjacent } = await client.query(
      `SELECT * FROM entry
       WHERE user_id = $1 AND created_at = $2
       AND category_id = $3 AND start_time = $4`,
      [userId, date, category_id, endTimeOnly]
    );

    const left = leftAdjacent[0];
    const right = rightAdjacent[0];

    if (left && right) {
      const { rows } = await client.query(
        `UPDATE entry SET end_time = $1 WHERE id = $2 RETURNING *`,
        [right.end_time, left.id]
      );
      await client.query(`DELETE FROM entry WHERE id = $1`, [right.id]);
      await client.query('COMMIT');
      return rows[0];
    }

    if (left) {
      const { rows } = await client.query(
        `UPDATE entry SET end_time = $1 WHERE id = $2 RETURNING *`,
        [endTimeOnly, left.id]
      );
      await client.query('COMMIT');
      return rows[0];
    }

    if (right) {
      const { rows } = await client.query(
        `UPDATE entry SET start_time = $1 WHERE id = $2 RETURNING *`,
        [startTimeOnly, right.id]
      );
      await client.query('COMMIT');
      return rows[0];
    }

    // 4. no adjacency — clean insert
    const { rows: inserted } = await client.query(
      `INSERT INTO entry (user_id, created_at, start_time, end_time, category_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, date, startTimeOnly, endTimeOnly, category_id]
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

    const date = getLocalDateString();

    if (!start_time || !end_time) {
      throw new Error(`Invalid time format: start=${start_time}, end=${end_time}`);
    }

    const startNormalized = start_time;
    const endNormalized = normalizeEndTime(end_time);

    const { rows: overlapping } = await client.query(
      `SELECT * FROM entry
       WHERE user_id = $1 AND created_at = $2
       AND start_time < $4 AND end_time > $3`,
      [userId, date, startNormalized, endNormalized]
    );

    for (const existing of overlapping) {
      const startsBeforeNew = existing.start_time < startNormalized;
      const endsAfterNew = existing.end_time > endNormalized;

      if (startsBeforeNew && endsAfterNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [startNormalized, existing.id]
        );
        await client.query(
          `INSERT INTO entry (user_id, created_at, start_time, end_time, category_id)
           VALUES ($1, $2, $3, $4, $5)`,
          [userId, date, endNormalized, existing.end_time, existing.category_id]
        );
      } else if (startsBeforeNew) {
        await client.query(
          `UPDATE entry SET end_time = $1 WHERE id = $2`,
          [startNormalized, existing.id]
        );
      } else if (endsAfterNew) {
        await client.query(
          `UPDATE entry SET start_time = $1 WHERE id = $2`,
          [endNormalized, existing.id]
        );
      } else {
        await client.query(
          `DELETE FROM entry WHERE id = $1`,
          [existing.id]
        );
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