import { pool } from '../config/config';
import Category from '../types/category';
import User from '../types/user';

async function getCategories(userId: User['id']): Promise<Category[]> {
  const { rows } = await pool.query(
    'SELECT * FROM category WHERE user_id = $1::uuid ORDER BY name ASC',
    [userId]
  );
  return rows as Category[];
}

async function createCategory(
  userId: User['id'],
  name: Category['name'],
  color: Category['color'],
  isProductive: Category['is_productive'],
  isSleep: Category['is_sleep']
): Promise<Category> {
  const { rows } = await pool.query(
    'INSERT INTO category (user_id, name, color, is_productive, is_sleep) VALUES ($1::uuid, $2, $3, $4, $5) RETURNING *',
    [userId, name, color, isProductive, isSleep]
  );
  return rows[0];
}

async function updateCategory(
  userId: User['id'],
  categoryId: Category['id'],
  name: Category['name'],
  color: Category['color'],
  isProductive: Category['is_productive'],
  isSleep: Category['is_sleep']
): Promise<Category> {
  const { rows } = await pool.query(
    'UPDATE category SET name = $1, color = $2, is_productive = $3, is_sleep = $4 WHERE id = $5::uuid AND user_id = $6::uuid RETURNING *',
    [name, color, isProductive, isSleep, categoryId, userId]
  );
  if (rows.length === 0) throw new Error('Category not found');
  return rows[0];
}

async function deleteCategory(
  userId: User['id'],
  categoryId: Category['id']
): Promise<void> {
  const { rowCount } = await pool.query(
    'DELETE FROM category WHERE id = $1::uuid AND user_id = $2::uuid',
    [categoryId, userId]
  );
  if (rowCount === 0) throw new Error('Category not found');
}

export { getCategories, createCategory, updateCategory, deleteCategory };