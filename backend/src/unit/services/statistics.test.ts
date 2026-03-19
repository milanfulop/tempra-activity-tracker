import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getStats } from '../../services/statistics'

vi.mock('../../config/config', () => ({
  bq: {
    query: vi.fn(),
  },
}))

vi.mock('../../queries/statistics', async (importOriginal) => {
  const actual = await importOriginal() as Record<string, unknown>
  return {
    ...actual,
    timeDistribution: vi.fn((userId, date) => `SELECT distribution FROM entries WHERE user_id = '${userId}' AND date = '${date}'`),
  }
})

import { bq } from '../../config/config'

const mockBqQuery = vi.mocked(bq.query)
const userId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
const date = '2026-03-18'

beforeEach(() => {
  vi.clearAllMocks()
})

// ─── getStats ─────────────────────────────────────────────────

describe('getStats', () => {
  it('returns single row for longest_session', async () => {
    const mockRow = { category_id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', duration_minutes: 90 }
    mockBqQuery.mockResolvedValueOnce([[mockRow]] as any)

    const result = await getStats(userId, date, ['longest_session'])
    expect(result).toEqual({ longest_session: mockRow })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  it('returns single row for tracked_time_percentage', async () => {
    const mockRow = { tracked_percent: 45.83, total_tracked_minutes: 660 }
    mockBqQuery.mockResolvedValueOnce([[mockRow]] as any)

    const result = await getStats(userId, date, ['tracked_time_percentage'])
    expect(result).toEqual({ tracked_time_percentage: mockRow })
  })

  it('returns array for time_distribution', async () => {
    const mockRows = [
      { category_id: 'cat-1', minutes: 60, percent_of_day: 4.17 },
      { category_id: 'untracked', minutes: 1380, percent_of_day: 95.83 },
    ]
    mockBqQuery.mockResolvedValueOnce([mockRows] as any)

    const result = await getStats(userId, date, ['time_distribution'])
    expect(result).toEqual({ time_distribution: mockRows })
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