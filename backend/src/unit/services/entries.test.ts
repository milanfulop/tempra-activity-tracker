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
const date = new Date().toISOString().split('T')[0]
const category_id = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'
const other_category_id = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33'

const iso = (time: string) => `${date}T${time}`

// existing rows use full ISO strings so comparisons in the service work correctly
const row = (id: number, start: string, end: string, cat = category_id) => ({
  id,
  user_id: userId,
  created_at: date,
  start_time: iso(start),
  end_time: iso(end),
  category_id: cat,
})

beforeEach(() => {
  vi.clearAllMocks()
  mockClient.query.mockResolvedValue({ rows: [] })
})

// ─── getEntries ───────────────────────────────────────────────

describe('getEntries', () => {
  it('returns entries for a user and date', async () => {
    const mockRows = [{ id: 1, user_id: userId, created_at: date, start_time: '10:00:00', end_time: '11:00:00', category_id }]
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: mockRows } as any)

    const result = await getEntries(userId, date)

    expect(result).toEqual(mockRows)
    expect(pool.query).toHaveBeenCalledWith(
      'SELECT * FROM entry WHERE user_id = $1 AND created_at = $2',
      [userId, date]
    )
  })

  it('returns empty array if no entries exist', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as any)
    const result = await getEntries(userId, date)
    expect(result).toEqual([])
  })
})

// ─── createEntry ─────────────────────────────────────────────

describe('createEntry', () => {

  // ── Exact match ──────────────────────────────────────────

  it('updates category_id when exact same time block exists', async () => {
    const existing = [row(99, '10:00:00', '11:00:00')]
    const updated  = [{ ...row(99, '10:00:00', '11:00:00'), category_id }]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // exact match
      .mockResolvedValueOnce({ rows: updated })  // UPDATE category_id
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result.category_id).toBe(category_id)
    expect(mockClient.release).toHaveBeenCalled()
  })

  // ── Clean insert ─────────────────────────────────────────

  it('inserts new entry when timeline is empty', async () => {
    const inserted = [row(1, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result.id).toBe(1)
    expect(mockClient.release).toHaveBeenCalled()
  })

  // ── Adjacency merges ──────────────────────────────────────

  it('extends into left adjacent same-category block', async () => {
    const left    = [row(88, '09:00:00', '10:00:00')]
    const updated = [row(88, '09:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: left })     // left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: updated })  // UPDATE left end_time
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result.start_time).toBe(iso('09:00:00'))
    expect(result.end_time).toBe(iso('11:00:00'))
  })

  it('extends into right adjacent same-category block', async () => {
    const right   = [row(77, '11:00:00', '12:00:00')]
    const updated = [row(77, '10:00:00', '12:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: right })    // right adjacent
      .mockResolvedValueOnce({ rows: updated })  // UPDATE right start_time
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result.start_time).toBe(iso('10:00:00'))
    expect(result.end_time).toBe(iso('12:00:00'))
  })

  it('merges left + new + right into one block when both sides are same category', async () => {
    const left   = [row(88, '09:00:00', '10:00:00')]
    const right  = [row(77, '11:00:00', '12:00:00')]
    const merged = [row(88, '09:00:00', '12:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: left })     // left adjacent
      .mockResolvedValueOnce({ rows: right })    // right adjacent
      .mockResolvedValueOnce({ rows: merged })   // UPDATE left end_time = right end_time
      .mockResolvedValueOnce({ rows: [] })       // DELETE right
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result.start_time).toBe(iso('09:00:00'))
    expect(result.end_time).toBe(iso('12:00:00'))
  })

  it('does not merge adjacent block of different category', async () => {
    const inserted = [row(1, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: [] })       // no overlaps
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result.id).toBe(1)
  })

  // ── Overlap trimming ──────────────────────────────────────

  it('punches a hole in a block when new entry lands in the middle', async () => {
    // existing: 09-12, new: 10-11 → trim existing to 09-10, insert remnant 11-12, insert new 10-11
    const existing = [row(77, '09:00:00', '12:00:00', other_category_id)]
    const inserted = [row(2, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlap: straddles
      .mockResolvedValueOnce({ rows: [] })       // UPDATE existing end_time = new start
      .mockResolvedValueOnce({ rows: [] })       // INSERT right remnant
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT new entry
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.id).toBe(2)
  })

  it('trims end of existing block when new entry overlaps its right side', async () => {
    // existing: 09-10:30, new: 10-11 → startsBeforeNew=true, endsAfterNew=false → UPDATE end_time
    const existing = [row(77, '09:00:00', '10:30:00', other_category_id)]
    const inserted = [row(2, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlap
      .mockResolvedValueOnce({ rows: [] })       // UPDATE existing end_time = new start
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.id).toBe(2)
  })

  it('trims start of existing block when new entry overlaps its left side', async () => {
    // existing: 10:30-12, new: 10-11 → startsBeforeNew=false, endsAfterNew=true → UPDATE start_time
    const existing = [row(77, '10:30:00', '12:00:00', other_category_id)]
    const inserted = [row(2, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlap
      .mockResolvedValueOnce({ rows: [] })       // UPDATE existing start_time = new end
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.id).toBe(2)
  })

  it('deletes existing block fully covered by new entry', async () => {
    // existing: 10:15-10:45, new: 10-11 → startsBeforeNew=false, endsAfterNew=false → DELETE
    const existing = [row(77, '10:15:00', '10:45:00', other_category_id)]
    const inserted = [row(2, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: [] })       // no exact match
      .mockResolvedValueOnce({ rows: existing }) // overlap
      .mockResolvedValueOnce({ rows: [] })       // DELETE existing
      .mockResolvedValueOnce({ rows: [] })       // no left adjacent
      .mockResolvedValueOnce({ rows: [] })       // no right adjacent
      .mockResolvedValueOnce({ rows: inserted }) // INSERT
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.id).toBe(2)
  })

  it('deletes multiple fully covered entries and inserts new one', async () => {
    const e1 = row(1, '10:00:00', '10:30:00', other_category_id)
    const e2 = row(2, '10:45:00', '11:00:00', other_category_id)
    const inserted = [row(3, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [] })          // no exact match
      .mockResolvedValueOnce({ rows: [e1, e2] })    // two overlapping entries
      .mockResolvedValueOnce({ rows: [] })          // DELETE e1
      .mockResolvedValueOnce({ rows: [] })          // DELETE e2
      .mockResolvedValueOnce({ rows: [] })          // no left adjacent
      .mockResolvedValueOnce({ rows: [] })          // no right adjacent
      .mockResolvedValueOnce({ rows: inserted })    // INSERT
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.id).toBe(3)
  })

  it('trims overlapping block then merges with same-category left adjacent', async () => {
    const overlapping = [row(77, '09:00:00', '11:00:00')]
    const left        = [row(77, '09:00:00', '10:00:00')]
    const merged      = [row(77, '09:00:00', '12:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [] })          // no exact match
      .mockResolvedValueOnce({ rows: overlapping }) // overlap: starts before, ends inside
      .mockResolvedValueOnce({ rows: [] })          // UPDATE end_time = new start
      .mockResolvedValueOnce({ rows: left })        // left adjacent
      .mockResolvedValueOnce({ rows: [] })          // no right adjacent
      .mockResolvedValueOnce({ rows: merged })      // UPDATE left end_time = new end
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('12:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.start_time).toBe(iso('09:00:00'))
    expect(result.end_time).toBe(iso('12:00:00'))
  })

  it('trims left, deletes middle, trims right, then inserts', async () => {
    const eA = row(1, '08:00:00', '10:30:00', other_category_id)
    const eB = row(2, '10:45:00', '11:15:00', other_category_id)
    const eC = row(3, '11:30:00', '13:00:00', other_category_id)
    const inserted = [row(4, '10:00:00', '12:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })             // BEGIN
      .mockResolvedValueOnce({ rows: [] })             // no exact match
      .mockResolvedValueOnce({ rows: [eA, eB, eC] })  // three overlapping entries
      .mockResolvedValueOnce({ rows: [] })             // UPDATE A end_time → 10:00
      .mockResolvedValueOnce({ rows: [] })             // DELETE B
      .mockResolvedValueOnce({ rows: [] })             // UPDATE C start_time → 12:00
      .mockResolvedValueOnce({ rows: [] })             // no left adjacent
      .mockResolvedValueOnce({ rows: [] })             // no right adjacent
      .mockResolvedValueOnce({ rows: inserted })       // INSERT
      .mockResolvedValueOnce({ rows: [] })             // COMMIT

    const result = await createEntry(userId, iso('10:00:00'), iso('12:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.id).toBe(4)
  })

  it('trims overlap then merges with same-category right adjacent', async () => {
    // existing: 10:30-12, new: 09-13 → trim existing start to 13, right adjacent 13-14 → extend to 09-14
    const overlapping = [row(1, '10:30:00', '12:00:00', other_category_id)]
    const right       = [row(2, '13:00:00', '14:00:00')]
    const updated     = [row(2, '09:00:00', '14:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [] })          // no exact match
      .mockResolvedValueOnce({ rows: overlapping }) // overlap: starts inside, ends after new end
      .mockResolvedValueOnce({ rows: [] })          // UPDATE overlapping start_time = new end (13:00)
      .mockResolvedValueOnce({ rows: [] })          // no left adjacent
      .mockResolvedValueOnce({ rows: right })       // right adjacent at 13:00
      .mockResolvedValueOnce({ rows: updated })     // UPDATE right start_time = new start (09:00)
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    const result = await createEntry(userId, iso('09:00:00'), iso('13:00:00'), category_id)

    expect(result).toBeDefined()
    expect(result.start_time).toBe(iso('09:00:00'))
    expect(result.end_time).toBe(iso('14:00:00'))
  })

  // ── Error handling ────────────────────────────────────────

  it('rolls back and releases client on error', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] })           // BEGIN
      .mockResolvedValueOnce({ rows: [] })           // no exact match
      .mockRejectedValueOnce(new Error('DB error'))  // overlaps query throws
      .mockResolvedValueOnce({ rows: [] })           // ROLLBACK

    await expect(
      createEntry(userId, iso('10:00:00'), iso('11:00:00'), category_id)
    ).rejects.toThrow('DB error')

    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
    expect(mockClient.release).toHaveBeenCalled()
  })
})

// ─── deleteEntry ─────────────────────────────────────────────

describe('deleteEntry', () => {
  it('deletes a fully covered entry', async () => {
    const existing = [row(55, '10:00:00', '11:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlapping
      .mockResolvedValueOnce({ rows: [] })       // DELETE
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
    expect(mockClient.release).toHaveBeenCalled()
  })

  it('trims end of block when delete range overlaps its right side', async () => {
    const existing = [row(55, '09:00:00', '10:30:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlap
      .mockResolvedValueOnce({ rows: [] })       // UPDATE end_time = delete start
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
  })

  it('trims start of block when delete range overlaps its left side', async () => {
    const existing = [row(55, '10:30:00', '12:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlap
      .mockResolvedValueOnce({ rows: [] })       // UPDATE start_time = delete end
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
  })

  it('splits block when deleting from the middle', async () => {
    const existing = [row(44, '09:00:00', '12:00:00')]

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })       // BEGIN
      .mockResolvedValueOnce({ rows: existing }) // overlap: straddles
      .mockResolvedValueOnce({ rows: [] })       // UPDATE end_time = delete start
      .mockResolvedValueOnce({ rows: [] })       // INSERT right remnant
      .mockResolvedValueOnce({ rows: [] })       // COMMIT

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
  })

  it('does nothing when no entries overlap the delete range', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] }) // BEGIN
      .mockResolvedValueOnce({ rows: [] }) // no overlapping entries
      .mockResolvedValueOnce({ rows: [] }) // COMMIT

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
  })

  it('deletes multiple entries including one that straddles the range', async () => {
    const eA = row(1, '09:00:00', '10:30:00')
    const eB = row(2, '10:45:00', '11:00:00')

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [eA, eB] })    // two overlapping entries
      .mockResolvedValueOnce({ rows: [] })          // UPDATE A end_time → 10:00
      .mockResolvedValueOnce({ rows: [] })          // DELETE B
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
  })

  it('deletes multiple entries spanning tracked and untracked regions', async () => {
    const eA = row(1, '09:00:00', '10:00:00')
    const eB = row(2, '10:30:00', '11:30:00')

    mockClient.query
      .mockResolvedValueOnce({ rows: [] })          // BEGIN
      .mockResolvedValueOnce({ rows: [eA, eB] })    // two overlapping entries
      .mockResolvedValueOnce({ rows: [] })          // DELETE A (fully covered)
      .mockResolvedValueOnce({ rows: [] })          // UPDATE B start_time → 11:00
      .mockResolvedValueOnce({ rows: [] })          // COMMIT

    await expect(deleteEntry(userId, iso('09:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
  })

  it('delete range exactly touches entry boundary but does not overlap', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] }) // BEGIN
      .mockResolvedValueOnce({ rows: [] }) // no overlapping entries
      .mockResolvedValueOnce({ rows: [] }) // COMMIT

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).resolves.toBeUndefined()
  })

  it('rolls back and releases client on error', async () => {
    mockClient.query
      .mockResolvedValueOnce({ rows: [] })           // BEGIN
      .mockRejectedValueOnce(new Error('DB error'))  // overlaps query throws
      .mockResolvedValueOnce({ rows: [] })           // ROLLBACK

    await expect(deleteEntry(userId, iso('10:00:00'), iso('11:00:00'))).rejects.toThrow('DB error')

    expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK')
    expect(mockClient.release).toHaveBeenCalled()
  })
})