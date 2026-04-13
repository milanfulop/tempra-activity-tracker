import { pool } from '../config/config';

export async function getProfile(userId: string) {
    try {
      const { rows } = await pool.query(
        'SELECT created_at FROM public.user WHERE id = $1::uuid',
        [userId]
      );
      if (rows.length === 0) throw new Error('Profile not found');
      return rows[0];
    } catch (err) {
      console.error('getProfile error:', err);
      throw err;
    }
}