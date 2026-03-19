import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getCategories, createCategory, updateCategory, deleteCategory } from '../../services/categories'

vi.mock('../../config/config', () => ({
  pool: {
    query: vi.fn(),
  },
}))

import { pool } from '../../config/config'

const userId = 'user-123'
const categoryId = 'cat-456'
const name = 'Work'
const color = '#FF5733'
const isProductive = false
const isSleep = false

beforeEach(() => {
  vi.clearAllMocks()
})

// ─── getCategories ────────────────────────────────────────────

describe('getCategories', () => {
  it('returns categories for a user', async () => {
    const mockRows = [{ id: categoryId, user_id: userId, name, color, is_productive: false, is_sleep: false, created_at: new Date() }]
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
    const mockRow = { id: categoryId, user_id: userId, name, color, is_productive: false, is_sleep: false, created_at: new Date() }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockRow] } as any)

    const result = await createCategory(userId, name, color, isProductive, isSleep)
    expect(result).toEqual(mockRow)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO category'),
      [userId, name, color, isProductive, isSleep]
    )
  })

  it('inserts with is_productive true', async () => {
    const mockRow = { id: categoryId, user_id: userId, name, color, is_productive: true, is_sleep: false, created_at: new Date() }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockRow] } as any)

    const result = await createCategory(userId, name, color, true, false)
    expect(result).toEqual(mockRow)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO category'),
      [userId, name, color, true, false]
    )
  })

  it('inserts with is_sleep true', async () => {
    const mockRow = { id: categoryId, user_id: userId, name, color, is_productive: false, is_sleep: true, created_at: new Date() }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockRow] } as any)

    const result = await createCategory(userId, name, color, false, true)
    expect(result).toEqual(mockRow)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO category'),
      [userId, name, color, false, true]
    )
  })
})

// ─── updateCategory ───────────────────────────────────────────

describe('updateCategory', () => {
  it('updates and returns the category', async () => {
    const mockRow = { id: categoryId, user_id: userId, name: 'Updated', color: '#000000', is_productive: false, is_sleep: false, created_at: new Date() }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockRow] } as any)

    const result = await updateCategory(userId, categoryId, 'Updated', '#000000', isProductive, isSleep)
    expect(result).toEqual(mockRow)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE category'),
      ['Updated', '#000000', isProductive, isSleep, categoryId, userId]
    )
  })

  it('updates is_productive and is_sleep flags', async () => {
    const mockRow = { id: categoryId, user_id: userId, name, color, is_productive: true, is_sleep: true, created_at: new Date() }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockRow] } as any)

    const result = await updateCategory(userId, categoryId, name, color, true, true)
    expect(result).toEqual(mockRow)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE category'),
      [name, color, true, true, categoryId, userId]
    )
  })

  it('throws if category not found', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)
    await expect(updateCategory(userId, categoryId, name, color, isProductive, isSleep)).rejects.toThrow('Category not found')
  })

  it('throws if category belongs to another user', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)
    await expect(updateCategory('other-user', categoryId, name, color, isProductive, isSleep)).rejects.toThrow('Category not found')
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