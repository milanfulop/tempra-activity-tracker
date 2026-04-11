import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getCategories, createCategory, updateCategory, deleteCategory } from '../../services/categories'

vi.mock('../../config/config', () => ({
  pool: {
    query: vi.fn(),
    connect: vi.fn(),
  },
}))

import { pool } from '../../config/config'

const userId = 'user-123'
const categoryId = 'cat-456'
const name = 'Work'
const color = '#FF5733'
const isProductive = false
const isSleep = false

const mockCategory = {
  id: categoryId,
  user_id: userId,
  name,
  color,
  is_productive: isProductive,
  is_sleep: isSleep,
  created_at: new Date(),
}

// reusable mock client for transaction tests
const mockClient = {
  query: vi.fn(),
  release: vi.fn(),
}

beforeEach(() => {
  vi.clearAllMocks()
  vi.mocked(pool.connect).mockResolvedValue(mockClient as any)
})

// ─── getCategories ────────────────────────────────────────────

describe('getCategories', () => {
  it('returns categories for a user ordered by name', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockCategory] } as any)

    const result = await getCategories(userId)

    expect(result).toEqual([mockCategory])
    expect(pool.query).toHaveBeenCalledWith(
      'SELECT * FROM category WHERE user_id = $1::uuid ORDER BY name ASC',
      [userId]
    )
  })

  it('returns empty array if user has no categories', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)

    const result = await getCategories(userId)

    expect(result).toEqual([])
  })
})

// ─── createCategory ───────────────────────────────────────────

describe('createCategory', () => {
  it('inserts and returns a new category', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [mockCategory] } as any)

    const result = await createCategory(userId, name, color, isProductive, isSleep)

    expect(result).toEqual(mockCategory)
    expect(pool.query).toHaveBeenCalledWith(
      'INSERT INTO category (user_id, name, color, is_productive, is_sleep) VALUES ($1::uuid, $2, $3, $4, $5) RETURNING *',
      [userId, name, color, isProductive, isSleep]
    )
  })

  it('inserts with is_productive true', async () => {
    const row = { ...mockCategory, is_productive: true }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [row] } as any)

    const result = await createCategory(userId, name, color, true, false)

    expect(result).toEqual(row)
    expect(pool.query).toHaveBeenCalledWith(
      'INSERT INTO category (user_id, name, color, is_productive, is_sleep) VALUES ($1::uuid, $2, $3, $4, $5) RETURNING *',
      [userId, name, color, true, false]
    )
  })

  it('inserts with is_sleep true', async () => {
    const row = { ...mockCategory, is_sleep: true }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [row] } as any)

    const result = await createCategory(userId, name, color, false, true)

    expect(result).toEqual(row)
    expect(pool.query).toHaveBeenCalledWith(
      'INSERT INTO category (user_id, name, color, is_productive, is_sleep) VALUES ($1::uuid, $2, $3, $4, $5) RETURNING *',
      [userId, name, color, false, true]
    )
  })

  it('inserts with both is_productive and is_sleep true', async () => {
    const row = { ...mockCategory, is_productive: true, is_sleep: true }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [row] } as any)

    const result = await createCategory(userId, name, color, true, true)

    expect(result).toEqual(row)
    expect(pool.query).toHaveBeenCalledWith(
      'INSERT INTO category (user_id, name, color, is_productive, is_sleep) VALUES ($1::uuid, $2, $3, $4, $5) RETURNING *',
      [userId, name, color, true, true]
    )
  })
})

// ─── updateCategory ───────────────────────────────────────────

describe('updateCategory', () => {
  it('updates and returns the category', async () => {
    const updated = { ...mockCategory, name: 'Updated', color: '#000000' }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [updated] } as any)

    const result = await updateCategory(userId, categoryId, 'Updated', '#000000', isProductive, isSleep)

    expect(result).toEqual(updated)
    expect(pool.query).toHaveBeenCalledWith(
      'UPDATE category SET name = $1, color = $2, is_productive = $3, is_sleep = $4 WHERE id = $5::uuid AND user_id = $6::uuid RETURNING *',
      ['Updated', '#000000', isProductive, isSleep, categoryId, userId]
    )
  })

  it('updates is_productive and is_sleep flags', async () => {
    const updated = { ...mockCategory, is_productive: true, is_sleep: true }
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [updated] } as any)

    const result = await updateCategory(userId, categoryId, name, color, true, true)

    expect(result).toEqual(updated)
    expect(pool.query).toHaveBeenCalledWith(
      'UPDATE category SET name = $1, color = $2, is_productive = $3, is_sleep = $4 WHERE id = $5::uuid AND user_id = $6::uuid RETURNING *',
      [name, color, true, true, categoryId, userId]
    )
  })

  it('throws if category not found', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)

    await expect(
      updateCategory(userId, categoryId, name, color, isProductive, isSleep)
    ).rejects.toThrow('Category not found')
  })

  it('throws if category belongs to another user', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)

    await expect(
      updateCategory('other-user', categoryId, name, color, isProductive, isSleep)
    ).rejects.toThrow('Category not found')
  })
})

// ─── deleteCategory ───────────────────────────────────────────

describe('deleteCategory', () => {
  it('disowns the category and deletes todays entries', async () => {
    mockClient.query
      .mockResolvedValueOnce(undefined)                // BEGIN
      .mockResolvedValueOnce({ rowCount: 1 })          // UPDATE user_id = NULL
      .mockResolvedValueOnce(undefined)                // DELETE entries
      .mockResolvedValueOnce(undefined)                // COMMIT

    await expect(deleteCategory(userId, categoryId)).resolves.toBeUndefined()

    expect(mockClient.query).toHaveBeenNthCalledWith(1, 'BEGIN')
    expect(mockClient.query).toHaveBeenNthCalledWith(2,
      expect.stringContaining('UPDATE category'),
      [categoryId, userId]
    )
    expect(mockClient.query).toHaveBeenNthCalledWith(3,
      expect.stringContaining('DELETE FROM entry'),
      [categoryId]
    )
    expect(mockClient.query).toHaveBeenNthCalledWith(4, 'COMMIT')
    expect(mockClient.release).toHaveBeenCalled()
  })

  it('throws and rolls back if category not found', async () => {
    mockClient.query
      .mockResolvedValueOnce(undefined)                // BEGIN
      .mockResolvedValueOnce({ rowCount: 0 })          // UPDATE returns 0 rows
      .mockResolvedValueOnce(undefined)                // ROLLBACK

    await expect(
      deleteCategory(userId, categoryId)
    ).rejects.toThrow('Category not found or not owned by user')

    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
    expect(mockClient.release).toHaveBeenCalled()
  })

  it('throws and rolls back if category belongs to another user', async () => {
    mockClient.query
      .mockResolvedValueOnce(undefined)                // BEGIN
      .mockResolvedValueOnce({ rowCount: 0 })          // UPDATE matches nothing
      .mockResolvedValueOnce(undefined)                // ROLLBACK

    await expect(
      deleteCategory('other-user', categoryId)
    ).rejects.toThrow('Category not found or not owned by user')

    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
    expect(mockClient.release).toHaveBeenCalled()
  })

  it('releases client even if an unexpected error is thrown', async () => {
    mockClient.query
      .mockResolvedValueOnce(undefined)                // BEGIN
      .mockRejectedValueOnce(new Error('DB exploded')) // UPDATE throws
      .mockResolvedValueOnce(undefined)                // ROLLBACK

    await expect(
      deleteCategory(userId, categoryId)
    ).rejects.toThrow('DB exploded')

    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
    expect(mockClient.release).toHaveBeenCalled()
  })
})