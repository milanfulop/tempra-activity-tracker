import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getEntries, createEntry, deleteEntry } from '../../services/entries'

const mockClient = vi.hoisted(() => ({
  query: vi.fn(),
  release: vi.fn(),
}))

vi.mock('../../config/config', () => ({
  pool: {
    query: vi.fn(),
    connect: vi.fn().mockResolvedValue(mockClient),
  },
}))

import { pool } from '../../config/config'

const userId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
const date = '2026-03-10'
const start_time = '10:00'
const end_time = '11:00'
const category_id = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'

beforeEach(() => {
  vi.clearAllMocks()
  mockClient.query.mockResolvedValue({ rows: [] })
})

// ─── getEntries ───────────────────────────────────────────────

describe('getEntries', () => {
  it('returns entries for a user and date', async () => {
    const mockRows = [{ id: 1, user_id: userId, created_at: date, start_time, end_time, category_id }]
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: mockRows } as any)

    const result = await getEntries(userId, date)
    expect(result).toEqual(mockRows)
    expect(pool.query).toHaveBeenCalledWith(
      expect.stringContaining('WHERE user_id'),
      [userId, date]
    )
  })

  it('returns empty array if no entries', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)
    const result = await getEntries(userId, date)
    expect(result).toEqual([])
  })
})

// ─── createEntry ─────────────────────────────────────────────

describe('createEntry', () => {
  it('updates category_id if exact same time block exists', async () => {
    const existing = [{ id: 99, start_time, end_time, category_id: 'old-uuid' }]
    const updated = [{ id: 99, start_time, end_time, category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // exact match
      .mockResolvedValueOnce({ rows: updated })  // UPDATE category_id
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, start_time, end_time, category_id)
    expect(result.category_id).toBe(category_id)
  })

  it('extends adjacent same-category_id block', async () => {
    const adjacent = [{ id: 88, start_time: '09:00', end_time: start_time, category_id }]
    const extended = [{ id: 88, start_time: '09:00', end_time, category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })        // BEGIN
      .mockResolvedValueOnce({ rows: [] })        // no exact match
      .mockResolvedValueOnce({ rows: adjacent })  // adjacent match
      .mockResolvedValueOnce({ rows: extended })  // UPDATE end_time
      .mockResolvedValueOnce({ rows: [] })        // COMMIT

    const result = await createEntry(userId, start_time, end_time, category_id)
    expect(result.end_time).toBe(end_time)
  })

  it('inserts new entry when no conflicts', async () => {
    const inserted = [{ id: 1, user_id: userId, created_at: date, start_time, end_time, category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no adjacent
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, start_time, end_time, category_id)
    expect(result.id).toBe(1)
  })

  it('splits existing block when new entry lands in the middle', async () => {
    const existing = [{ id: 77, start_time: '09:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })           // BEGIN
      .mockResolvedValueOnce({ rows: [] })           // no exact match
      .mockResolvedValueOnce({ rows: [] })           // no adjacent
      .mockResolvedValueOnce({ rows: existing })     // overlapping
      .mockResolvedValueOnce({ rows: [] })           // UPDATE (trim left)
      .mockResolvedValueOnce({ rows: [] })           // INSERT (right split)
      .mockResolvedValueOnce({ rows: [{ id: 2 }] }) // INSERT new entry
      .mockResolvedValueOnce({ rows: [] })           // COMMIT

    const result = await createEntry(userId, start_time, end_time, category_id)
    expect(result.id).toBe(2)
  })

  it('rolls back on error', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] })
      .mockRejectedValueOnce(new Error('DB error'))

    await expect(createEntry(userId, start_time, end_time, category_id)).rejects.toThrow('DB error')
    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
  })
})

it('trims end of existing block when new entry overlaps the right side', async () => {
  const existing = [{ id: 77, start_time: '09:00', end_time: '10:00', category_id }]
  const inserted = [{ id: 2, start_time: '09:30', end_time: '11:00', category_id }]

  mockClient.query
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: existing })
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: inserted })
    .mockResolvedValueOnce({ rows: [] })

  const result = await createEntry(userId, '09:30', '11:00', category_id)
  expect(result.id).toBe(2)
})

it('trims start of existing block when new entry overlaps the left side', async () => {
  const existing = [{ id: 77, start_time: '10:30', end_time: '12:00', category_id }]
  const inserted = [{ id: 2, start_time: '09:00', end_time: '11:00', category_id }]

  mockClient.query
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: existing })
    .mockResolvedValueOnce({ rows: [] })
    .mockResolvedValueOnce({ rows: inserted })
    .mockResolvedValueOnce({ rows: [] })

  const result = await createEntry(userId, '09:00', '11:00', category_id)
  expect(result.id).toBe(2)
})

// ─── deleteEntry ─────────────────────────────────────────────

describe('deleteEntry', () => {
  it('deletes a fully covered entry', async () => {
    const existing = [{ id: 55, start_time, end_time, category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: existing })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [] })

    await expect(deleteEntry(userId, start_time, end_time)).resolves.toBeUndefined()
  })

  it('splits block when deleting from the middle', async () => {
    const existing = [{ id: 44, start_time: '09:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: existing })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [] })

    await expect(deleteEntry(userId, start_time, end_time)).resolves.toBeUndefined()
  })

  it('rolls back on error', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] })
      .mockRejectedValueOnce(new Error('DB error'))

    await expect(deleteEntry(userId, start_time, end_time)).rejects.toThrow('DB error')
    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
  })
})