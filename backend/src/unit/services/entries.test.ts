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
const category_id = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'
const other_category_id = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33'

// New call order for createEntry:
// BEGIN → exact match → overlaps → left adjacent → right adjacent → action → COMMIT

function beginAndExactMatch(exactRows = []) {
  return [
    { rows: [] },       // BEGIN
    { rows: exactRows } // exact match query
  ]
}

function noOverlapsNoAdjacents() {
  return [
    { rows: [] }, // overlaps
    { rows: [] }, // left adjacent
    { rows: [] }, // right adjacent
  ]
}

beforeEach(() => {
  vi.clearAllMocks()
  mockClient.query.mockResolvedValue({ rows: [] })
})

// ─── getEntries ───────────────────────────────────────────────

describe('getEntries', () => {
  it('returns entries for a user and date', async () => {
    const mockRows = [{ id: 1, user_id: userId, created_at: date, start_time: '10:00', end_time: '11:00', category_id }]
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

  // ── Exact match ──────────────────────────────────────────

  it('updates category_id when exact same time block exists', async () => {
    const existing = [{ id: 99, start_time: '10:00', end_time: '11:00', category_id: 'old-uuid' }]
    const updated  = [{ id: 99, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // exact match → early return
      .mockResolvedValueOnce({ rows: updated })  // UPDATE category_id
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.category_id).toBe(category_id)
  })

  // ── Clean insert (no conflicts) ───────────────────────────

  it('inserts new entry when timeline is empty', async () => {
    const inserted = [{ id: 1, user_id: userId, created_at: date, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(1)
  })

  // ── Adjacency merges ──────────────────────────────────────

  it('extends into left adjacent same-category block', async () => {
    const left    = [{ id: 88, start_time: '09:00', end_time: '10:00', category_id }]
    const updated = [{ id: 88, start_time: '09:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: left })     // left adjacent found
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: updated })  // UPDATE end_time on left
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.end_time).toBe('11:00')
    expect(result.start_time).toBe('09:00')
  })

  it('extends into right adjacent same-category block', async () => {
    const right   = [{ id: 77, start_time: '11:00', end_time: '12:00', category_id }]
    const updated = [{ id: 77, start_time: '10:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: right })    // right adjacent found
      .mockResolvedValueOnce({ rows: updated })  // UPDATE start_time on right
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.start_time).toBe('10:00')
    expect(result.end_time).toBe('12:00')
  })

  it('merges left + new + right into one block when both sides are same category', async () => {
    const left    = [{ id: 88, start_time: '09:00', end_time: '10:00', category_id }]
    const right   = [{ id: 77, start_time: '11:00', end_time: '12:00', category_id }]
    const updated = [{ id: 88, start_time: '09:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: left })     // left adjacent
      .mockResolvedValueOnce({ rows: right })    // right adjacent
      .mockResolvedValueOnce({ rows: updated })  // UPDATE left.end_time = right.end_time
      .mockResolvedValueOnce({ rows: [] })       // DELETE right
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.start_time).toBe('09:00')
    expect(result.end_time).toBe('12:00')
  })

  it('does not merge adjacent block of different category', async () => {
    const inserted = [{ id: 1, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent (different category excluded by query)
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(1)
  })

  // ── Overlap trimming ──────────────────────────────────────

  it('punches a hole in a block when new entry lands in the middle', async () => {
    const existing = [{ id: 77, start_time: '09:00', end_time: '12:00', category_id: other_category_id }]
    const inserted = [{ id: 2, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlapping: straddles new entry
      .mockResolvedValueOnce({ rows: [] })       // UPDATE existing end_time = new start
      .mockResolvedValueOnce({ rows: [] })       // INSERT right remnant
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT new entry
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(2)
  })

  it('trims end of existing block when new entry overlaps its right side', async () => {
    const existing = [{ id: 77, start_time: '09:00', end_time: '10:30', category_id: other_category_id }]
    const inserted = [{ id: 2, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlapping: starts before, ends inside
      .mockResolvedValueOnce({ rows: [] })       // UPDATE existing end_time = new start
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT new entry
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(2)
  })

  it('trims start of existing block when new entry overlaps its left side', async () => {
    const existing = [{ id: 77, start_time: '10:30', end_time: '12:00', category_id: other_category_id }]
    const inserted = [{ id: 2, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlapping: starts inside, ends after
      .mockResolvedValueOnce({ rows: [] })       // UPDATE existing start_time = new end
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT new entry
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(2)
  })

  it('deletes existing block fully covered by new entry', async () => {
    const existing = [{ id: 77, start_time: '10:15', end_time: '10:45', category_id: other_category_id }]
    const inserted = [{ id: 2, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlapping: fully inside new range
      .mockResolvedValueOnce({ rows: [] })       // DELETE existing
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT new entry
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(2)
  })

  it('deletes multiple fully covered entries and inserts new one', async () => {
    const e1 = { id: 1, start_time: '10:00', end_time: '10:30', category_id: other_category_id }
    const e2 = { id: 2, start_time: '10:45', end_time: '11:00', category_id: other_category_id }
    const inserted = [{ id: 3, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [] })          // no exact match
      .mockResolvedValueOnce({ rows: [e1, e2] })    // two overlapping entries
      .mockResolvedValueOnce({ rows: [] })          // DELETE e1
      .mockResolvedValueOnce({ rows: [] })          // DELETE e2
      .mockResolvedValueOnce({ rows: [] })          // no left adjacent
      .mockResolvedValueOnce({ rows: [] })          // no right adjacent
      .mockResolvedValueOnce({ rows: inserted })    // INSERT new entry
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(3)
  })

  // ── Overlap + adjacency merge combo (the original bug) ───

  it('trims overlapping block then merges with same-category left adjacent', async () => {
    // [A: 9–11] exists, insert [A: 10–12] → trim to [A: 9–10], merge → [A: 9–12]
    const overlapping = [{ id: 77, start_time: '09:00', end_time: '11:00', category_id }]
    const left        = [{ id: 77, start_time: '09:00', end_time: '10:00', category_id }]
    const merged      = [{ id: 77, start_time: '09:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [] })          // no exact match
      .mockResolvedValueOnce({ rows: overlapping }) // overlap: starts before, ends inside new range
      .mockResolvedValueOnce({ rows: [] })          // UPDATE existing end_time = new start (trim to 9–10)
      .mockResolvedValueOnce({ rows: left })        // left adjacent (now 9–10, same category)
      .mockResolvedValueOnce({ rows: [] })          // no right adjacent
      .mockResolvedValueOnce({ rows: merged })      // UPDATE left end_time = new end_time
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    const result = await createEntry(userId, '10:00', '12:00', category_id)
    expect(result.start_time).toBe('09:00')
    expect(result.end_time).toBe('12:00')
  })

  // ── Error handling ────────────────────────────────────────

  it('rolls back on error', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] })
      .mockRejectedValueOnce(new Error('DB error'))

    await expect(createEntry(userId, '10:00', '11:00', category_id)).rejects.toThrow('DB error')
    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
  })
})

// ─── deleteEntry ─────────────────────────────────────────────

describe('deleteEntry', () => {
  it('deletes a fully covered entry', async () => {
    const existing = [{ id: 55, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlapping
      .mockResolvedValueOnce({ rows: [] })       // DELETE
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, '10:00', '11:00')).resolves.toBeUndefined()
  })

  it('trims end of block when delete range overlaps its right side', async () => {
    const existing = [{ id: 55, start_time: '09:00', end_time: '10:30', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlapping: starts before delete range
      .mockResolvedValueOnce({ rows: [] })       // UPDATE end_time = delete start
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, '10:00', '11:00')).resolves.toBeUndefined()
  })

  it('trims start of block when delete range overlaps its left side', async () => {
    const existing = [{ id: 55, start_time: '10:30', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlapping: ends after delete range
      .mockResolvedValueOnce({ rows: [] })       // UPDATE start_time = delete end
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, '10:00', '11:00')).resolves.toBeUndefined()
  })

  it('splits block when deleting from the middle', async () => {
    const existing = [{ id: 44, start_time: '09:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlapping: straddles delete range
      .mockResolvedValueOnce({ rows: [] })       // UPDATE end_time = delete start
      .mockResolvedValueOnce({ rows: [] })       // INSERT right remnant
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, '10:00', '11:00')).resolves.toBeUndefined()
  })

  it('does nothing when no entries overlap the delete range', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] }) // BEGIN
      .mockResolvedValueOnce({ rows: [] }) // no overlapping entries
      .mockResolvedValueOnce({ rows: [] }) // COMMIT

    await expect(deleteEntry(userId, '10:00', '11:00')).resolves.toBeUndefined()
    // Only BEGIN, overlap query, COMMIT — no writes
    expect(mockClient.query).toHaveBeenCalledTimes(3)
  })

  it('rolls back on error', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] })
      .mockRejectedValueOnce(new Error('DB error'))

    await expect(deleteEntry(userId, '10:00', '11:00')).rejects.toThrow('DB error')
    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
  })
  
})

describe('createEntry edge cases', () => {

  // ── Untracked gaps ────────────────────────────────────────

  it('fills an untracked gap between two different-category blocks', async () => {
    // [A: 9–10] [untracked: 10–11] [B: 11–12], insert [C: 10–11]
    // no overlaps, no adjacents (different category), clean insert
    const inserted = [{ id: 3, start_time: '10:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps (gap is untracked)
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent (A is different category)
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent (B is different category)
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.id).toBe(3)
    expect(result.start_time).toBe('10:00')
    expect(result.end_time).toBe('11:00')
  })

  it('fills untracked gap and merges with same-category block on left', async () => {
    // [A: 9–10] [untracked: 10–11] [B: 11–12], insert [A: 10–11]
    // no overlaps, left adjacent is A (same category), right adjacent is B (different) → extend A
    const left    = [{ id: 1, start_time: '09:00', end_time: '10:00', category_id }]
    const updated = [{ id: 1, start_time: '09:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: left })     // left adjacent: A ends at 10:00
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent (B is different category)
      .mockResolvedValueOnce({ rows: updated })  // UPDATE A end_time → 11:00
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.start_time).toBe('09:00')
    expect(result.end_time).toBe('11:00')
  })

  it('fills untracked gap and merges with same-category block on right', async () => {
    // [A: 9–10] [untracked: 10–11] [B: 11–12], insert [B: 10–11]
    // no overlaps, left adjacent is A (different), right adjacent is B (same) → extend B
    const right   = [{ id: 2, start_time: '11:00', end_time: '12:00', category_id }]
    const updated = [{ id: 2, start_time: '10:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent (A is different category)
      .mockResolvedValueOnce({ rows: right })    // right adjacent: B starts at 11:00
      .mockResolvedValueOnce({ rows: updated })  // UPDATE B start_time → 10:00
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.start_time).toBe('10:00')
    expect(result.end_time).toBe('12:00')
  })

  it('fills untracked gap and merges both sides when same category on both', async () => {
    // [A: 9–10] [untracked: 10–11] [A: 11–12], insert [A: 10–11]
    // no overlaps, both adjacents are A → collapse all three into [A: 9–12]
    const left    = [{ id: 1, start_time: '09:00', end_time: '10:00', category_id }]
    const right   = [{ id: 2, start_time: '11:00', end_time: '12:00', category_id }]
    const merged  = [{ id: 1, start_time: '09:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })      // BEGIN
      .mockResolvedValueOnce({ rows: [] })      // no exact match
      .mockResolvedValueOnce({ rows: [] })      // no overlaps (gap is untracked)
      .mockResolvedValueOnce({ rows: left })    // left adjacent
      .mockResolvedValueOnce({ rows: right })   // right adjacent
      .mockResolvedValueOnce({ rows: merged })  // UPDATE left end_time = right end_time
      .mockResolvedValueOnce({ rows: [] })      // DELETE right
      .mockResolvedValueOnce({ rows: [] })      // COMMIT

    const result = await createEntry(userId, '10:00', '11:00', category_id)
    expect(result.start_time).toBe('09:00')
    expect(result.end_time).toBe('12:00')
  })

  it('spans tracked and untracked: clears tracked entries inside gap and inserts', async () => {
    // [A: 9–9:30] [untracked: 9:30–10] [B: 10–10:30] [untracked: 10:30–11]
    // insert [C: 9–11] → A and B both fully covered, both deleted, C inserted
    const e1 = { id: 1, start_time: '09:00', end_time: '09:30', category_id: other_category_id }
    const e2 = { id: 2, start_time: '10:00', end_time: '10:30', category_id: other_category_id }
    const inserted = [{ id: 3, start_time: '09:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })         // BEGIN
      .mockResolvedValueOnce({ rows: [] })         // no exact match
      .mockResolvedValueOnce({ rows: [e1, e2] })   // overlapping: A and B fully covered
      .mockResolvedValueOnce({ rows: [] })         // DELETE e1
      .mockResolvedValueOnce({ rows: [] })         // DELETE e2
      .mockResolvedValueOnce({ rows: [] })         // no left adjacent
      .mockResolvedValueOnce({ rows: [] })         // no right adjacent
      .mockResolvedValueOnce({ rows: inserted })   // INSERT C
      .mockResolvedValueOnce({ rows: [] })         // COMMIT

    const result = await createEntry(userId, '09:00', '11:00', category_id)
    expect(result.id).toBe(3)
    expect(result.start_time).toBe('09:00')
    expect(result.end_time).toBe('11:00')
  })

  it('spans tracked entry and untracked gap: trims tracked, inserts into rest', async () => {
    // [A: 9–10:30] [untracked: 10:30–12], insert [B: 10–12]
    // A starts before new, ends inside → trim A to 9–10, no adjacents, insert B
    const existing = [{ id: 1, start_time: '09:00', end_time: '10:30', category_id: other_category_id }]
    const inserted = [{ id: 2, start_time: '10:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })        // BEGIN
      .mockResolvedValueOnce({ rows: [] })        // no exact match
      .mockResolvedValueOnce({ rows: existing })  // overlapping: A clips left side
      .mockResolvedValueOnce({ rows: [] })        // UPDATE A end_time → 10:00
      .mockResolvedValueOnce({ rows: [] })        // no left adjacent
      .mockResolvedValueOnce({ rows: [] })        // no right adjacent
      .mockResolvedValueOnce({ rows: inserted })  // INSERT B
      .mockResolvedValueOnce({ rows: [] })        // COMMIT

    const result = await createEntry(userId, '10:00', '12:00', category_id)
    expect(result.id).toBe(2)
    expect(result.start_time).toBe('10:00')
    expect(result.end_time).toBe('12:00')
  })

  it('untracked gap then tracked entry: trims tracked, inserts into combined range', async () => {
    // [untracked: 9–10:30] [A: 10:30–12], insert [B: 9–11]
    // A starts inside new range, ends after → push A start to 11, no adjacents, insert B
    const existing = [{ id: 1, start_time: '10:30', end_time: '12:00', category_id: other_category_id }]
    const inserted = [{ id: 2, start_time: '09:00', end_time: '11:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })        // BEGIN
      .mockResolvedValueOnce({ rows: [] })        // no exact match
      .mockResolvedValueOnce({ rows: existing })  // overlapping: A clips right side
      .mockResolvedValueOnce({ rows: [] })        // UPDATE A start_time → 11:00
      .mockResolvedValueOnce({ rows: [] })        // no left adjacent
      .mockResolvedValueOnce({ rows: [] })        // no right adjacent
      .mockResolvedValueOnce({ rows: inserted })  // INSERT B
      .mockResolvedValueOnce({ rows: [] })        // COMMIT

    const result = await createEntry(userId, '09:00', '11:00', category_id)
    expect(result.id).toBe(2)
    expect(result.start_time).toBe('09:00')
    expect(result.end_time).toBe('11:00')
  })

  // ── Mixed overlap + adjacency with gaps ───────────────────

  it('trims overlap then merges with same-category right adjacent across a gap', async () => {
    // [A: 10:30–12] overlaps new range, [B: 13–14] is right adjacent (same category)
    // insert [B: 9–13]: A gets start pushed to 13, B is right adjacent → extend B start to 9
    const overlapping = [{ id: 1, start_time: '10:30', end_time: '12:00', category_id: other_category_id }]
    const right       = [{ id: 2, start_time: '13:00', end_time: '14:00', category_id }]
    const updated     = [{ id: 2, start_time: '09:00', end_time: '14:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [] })          // no exact match
      .mockResolvedValueOnce({ rows: overlapping }) // overlapping: A clips right side
      .mockResolvedValueOnce({ rows: [] })          // UPDATE A start_time → 13:00
      .mockResolvedValueOnce({ rows: [] })          // no left adjacent
      .mockResolvedValueOnce({ rows: right })       // right adjacent: B starts at 13:00
      .mockResolvedValueOnce({ rows: updated })     // UPDATE B start_time → 09:00
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    const result = await createEntry(userId, '09:00', '13:00', category_id)
    expect(result.start_time).toBe('09:00')
    expect(result.end_time).toBe('14:00')
  })

  it('multiple mixed overlaps: trim left, delete middle, trim right, then insert', async () => {
    // [A: 8–10:30] [B: 10:45–11:15] [C: 11:30–13], insert [D: 10–12]
    // A trimmed to 8–10, B deleted, C pushed to 12–13, no adjacents, insert D
    const eA = { id: 1, start_time: '08:00', end_time: '10:30', category_id: other_category_id }
    const eB = { id: 2, start_time: '10:45', end_time: '11:15', category_id: other_category_id }
    const eC = { id: 3, start_time: '11:30', end_time: '13:00', category_id: other_category_id }
    const inserted = [{ id: 4, start_time: '10:00', end_time: '12:00', category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })             // BEGIN
      .mockResolvedValueOnce({ rows: [] })             // no exact match
      .mockResolvedValueOnce({ rows: [eA, eB, eC] })  // three overlapping entries
      .mockResolvedValueOnce({ rows: [] })             // UPDATE A end_time → 10:00 (startsBeforeNew)
      .mockResolvedValueOnce({ rows: [] })             // DELETE B (fully covered)
      .mockResolvedValueOnce({ rows: [] })             // UPDATE C start_time → 12:00 (endsAfterNew)
      .mockResolvedValueOnce({ rows: [] })             // no left adjacent
      .mockResolvedValueOnce({ rows: [] })             // no right adjacent
      .mockResolvedValueOnce({ rows: inserted })       // INSERT D
      .mockResolvedValueOnce({ rows: [] })             // COMMIT

    const result = await createEntry(userId, '10:00', '12:00', category_id)
    expect(result.id).toBe(4)
    expect(result.start_time).toBe('10:00')
    expect(result.end_time).toBe('12:00')
  })
})

describe('deleteEntry edge cases', () => {

  it('deletes multiple entries including one that straddles the range', async () => {
    // [A: 9–10:30] straddles start, [B: 10:45–11] fully covered
    // A trimmed to 9–10, B deleted
    const eA = { id: 1, start_time: '09:00', end_time: '10:30', category_id }
    const eB = { id: 2, start_time: '10:45', end_time: '11:00', category_id }

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [eA, eB] })   // two overlapping entries
      .mockResolvedValueOnce({ rows: [] })          // UPDATE A end_time → 10:00
      .mockResolvedValueOnce({ rows: [] })          // DELETE B
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    await expect(deleteEntry(userId, '10:00', '11:00')).resolves.toBeUndefined()
  })

  it('deletes multiple entries spanning tracked and untracked regions', async () => {
    // [A: 9–10] [untracked: 10–10:30] [B: 10:30–11:30] straddles end
    // A fully covered → deleted, B pushed to 11–11:30
    const eA = { id: 1, start_time: '09:00', end_time: '10:00', category_id }
    const eB = { id: 2, start_time: '10:30', end_time: '11:30', category_id }

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [eA, eB] })   // two overlapping entries
      .mockResolvedValueOnce({ rows: [] })          // DELETE A (fully covered)
      .mockResolvedValueOnce({ rows: [] })          // UPDATE B start_time → 11:00
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    await expect(deleteEntry(userId, '09:00', '11:00')).resolves.toBeUndefined()
  })

  it('delete range exactly touches entry boundary but does not overlap', async () => {
    // entry [A: 11–12], delete [10–11] — they touch at 11 but overlap query uses strict < and >
    // so A is not returned, nothing happens
    mockClient.query
      .mockResolvedValueOnce({ rows: [] }) // BEGIN
      .mockResolvedValueOnce({ rows: [] }) // no overlapping entries (boundary touch excluded)
      .mockResolvedValueOnce({ rows: [] }) // COMMIT

    await expect(deleteEntry(userId, '10:00', '11:00')).resolves.toBeUndefined()
    expect(mockClient.query).toHaveBeenCalledTimes(3)
  })
})