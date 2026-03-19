import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getStats } from '../../services/statistics'

vi.mock('../../config/config', () => ({
  bq: {
    query: vi.fn(),
  },
}))

vi.mock('../../queries/statistics', () => ({
  longestSingleSession: vi.fn((userId, date) => `SELECT longest FROM entries WHERE user_id = '${userId}' AND date = '${date}'`),
}))

import { bq } from '../../config/config'

const mockBqQuery = vi.mocked(bq.query)
const userId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
const date = '2026-03-18'

beforeEach(() => {
  vi.clearAllMocks()
})

// ─── getStats ─────────────────────────────────────────────────

describe('getStats', () => {
  it('returns result for a known stat', async () => {
    const mockRow = { category_id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', duration_minutes: 90 }
    mockBqQuery.mockResolvedValueOnce([[mockRow]] as any)

    const result = await getStats(userId, date, ['longest_session'])
    expect(result).toEqual({ longest_session: mockRow })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  it('returns null for a stat with no data', async () => {
    mockBqQuery.mockResolvedValueOnce([[]] as any)

    const result = await getStats(userId, date, ['longest_session'])
    expect(result).toEqual({ longest_session: null })
  })

  it('returns error for an unknown stat', async () => {
    const result = await getStats(userId, date, ['unknown_stat'])
    expect(result).toEqual({ unknown_stat: { error: 'Unknown stat' } })
    expect(mockBqQuery).not.toHaveBeenCalled()
  })

  it('handles multiple stats in one call', async () => {
    const mockRow = { category_id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', duration_minutes: 90 }
    mockBqQuery.mockResolvedValueOnce([[mockRow]] as any)

    const result = await getStats(userId, date, ['longest_session', 'unknown_stat'])
    expect(result).toEqual({
      longest_session: mockRow,
      unknown_stat: { error: 'Unknown stat' },
    })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  it('throws if bq query fails', async () => {
    mockBqQuery.mockRejectedValueOnce(new Error('BQ error'))
    await expect(getStats(userId, date, ['longest_session'])).rejects.toThrow('BQ error')
  })
})