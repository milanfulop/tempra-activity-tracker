import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getCategories, createCategory, updateCategory, deleteCategory } from '../services/categories'

vi.mock('../config/config', () => ({
  pool: {
    query: vi.fn(),
  },
}))

import { pool } from '../config/config'

const userId = 'user-123'
const categoryId = 'cat-456'
const name = 'Work'
const color = '#FF5733'

beforeEach(() => {
  vi.clearAllMocks()
})

// ─── getCategories ────────────────────────────────────────────

describe('getCategories', () => {
  it('returns categories for a user', async () => {
    const mockRows = [{ id: categoryId, user_id: userId, name, color, created_at: new Date() }]
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: mockRows } as any)

    const result = await getCategories(userId)
    expect(result).toEqual(mockRows)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('WHERE user_id'),
      [userId]
    )
  })

  it('returns empty array if no categories', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)
    const result = await getCategories(userId)
    expect(result).toEqual([])
  })
})

// ─── createCategory ───────────────────────────────────────────

describe('createCategory', () => {
  it('inserts and returns a new category', async () => {
    const mockRow = { id: categoryId, user_id: userId, name, color, created_at: new Date() }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockRow] } as any)

    const result = await createCategory(userId, name, color)
    expect(result).toEqual(mockRow)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO category'),
      [userId, name, color]
    )
  })
})

// ─── updateCategory ───────────────────────────────────────────

describe('updateCategory', () => {
  it('updates and returns the category', async () => {
    const mockRow = { id: categoryId, user_id: userId, name: 'Updated', color: '#000000', created_at: new Date() }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockRow] } as any)

    const result = await updateCategory(userId, categoryId, 'Updated', '#000000')
    expect(result).toEqual(mockRow)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE category'),
      ['Updated', '#000000', categoryId, userId]
    )
  })

  it('throws if category not found', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)
    await expect(updateCategory(userId, categoryId, name, color)).rejects.toThrow('Category not found')
  })

  it('throws if category belongs to another user', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)
    await expect(updateCategory('other-user', categoryId, name, color)).rejects.toThrow('Category not found')
  })
})

// ─── deleteCategory ───────────────────────────────────────────

describe('deleteCategory', () => {
  it('deletes the category', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rowCount: 1 } as any)
    await expect(deleteCategory(userId, categoryId)).resolves.toBeUndefined()
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('DELETE FROM category'),
      [categoryId, userId]
    )
  })

  it('throws if category not found', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rowCount: 0 } as any)
    await expect(deleteCategory(userId, categoryId)).rejects.toThrow('Category not found')
  })

  it('throws if category belongs to another user', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rowCount: 0 } as any)
    await expect(deleteCategory('other-user', categoryId)).rejects.toThrow('Category not found')
  })
})