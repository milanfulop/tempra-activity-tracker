import { pool } from '../config/config';

export async function getAppVersion(): Promise<string> {
  const { rows } = await pool.query(
    "SELECT value FROM app_config WHERE key = 'version'",
  );

  if (rows.length === 0) throw new Error('Version config not found');

  return rows[0].value as string;
}