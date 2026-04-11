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
    dailySummary: vi.fn((userId, date) => `SELECT summary FROM entries WHERE user_id = '${userId}' AND date = '${date}'`),
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

  // ── daily_summary ─────────────────────────────────────────

  it('returns single row for daily_summary', async () => {
    const mockRow = {
      tracked_percent: 75.0,
      total_tracked_minutes: 1080,
      productive_percent: 50.0,
      total_productive_minutes: 720,
      longest_category_id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
      longest_start_time: '09:00:00',
      longest_end_time: '12:00:00',
      longest_duration_minutes: 180,
      longest_is_productive: true,
    }
    mockBqQuery.mockResolvedValueOnce([[mockRow]] as any)

    const result = await getStats(userId, date, ['daily_summary'])

    expect(result).toEqual({ daily_summary: mockRow })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  it('returns null for daily_summary when no data', async () => {
    mockBqQuery.mockResolvedValueOnce([[]] as any)

    const result = await getStats(userId, date, ['daily_summary'])

    expect(result).toEqual({ daily_summary: null })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  // ── time_distribution ─────────────────────────────────────

  it('returns array for time_distribution', async () => {
    const mockRows = [
      { category_id: 'cat-1', category_name: 'Work', category_color: '#FF5733', is_productive: true, is_sleep: false, minutes: 480, percent_of_day: 33.33 },
      { category_id: 'cat-2', category_name: 'Sleep', category_color: '#3333FF', is_productive: false, is_sleep: true, minutes: 480, percent_of_day: 33.33 },
      { category_id: 'untracked', category_name: 'Untracked', category_color: '#888888', is_productive: false, is_sleep: false, minutes: 480, percent_of_day: 33.33 },
    ]
    mockBqQuery.mockResolvedValueOnce([mockRows] as any)

    const result = await getStats(userId, date, ['time_distribution'])

    expect(result).toEqual({ time_distribution: mockRows })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  it('returns empty array for time_distribution when no data', async () => {
    mockBqQuery.mockResolvedValueOnce([[]] as any)

    const result = await getStats(userId, date, ['time_distribution'])

    expect(result).toEqual({ time_distribution: [] })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  // ── unknown stat ──────────────────────────────────────────

  it('returns error object for an unknown stat', async () => {
    const result = await getStats(userId, date, ['unknown_stat'])

    expect(result).toEqual({ unknown_stat: { error: 'Unknown stat' } })
    expect(mockBqQuery).not.toHaveBeenCalled()
  })

  // ── multiple stats ────────────────────────────────────────

  it('handles multiple valid stats in one call', async () => {
    const summaryRow = {
      tracked_percent: 75.0,
      total_tracked_minutes: 1080,
      productive_percent: 50.0,
      total_productive_minutes: 720,
      longest_category_id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
      longest_start_time: '09:00:00',
      longest_end_time: '12:00:00',
      longest_duration_minutes: 180,
      longest_is_productive: true,
    }
    const distributionRows = [
      { category_id: 'cat-1', category_name: 'Work', category_color: '#FF5733', is_productive: true, is_sleep: false, minutes: 480, percent_of_day: 33.33 },
    ]

    mockBqQuery
      .mockResolvedValueOnce([[summaryRow]] as any)
      .mockResolvedValueOnce([distributionRows] as any)

    const result = await getStats(userId, date, ['daily_summary', 'time_distribution'])

    expect(result).toEqual({
      daily_summary: summaryRow,
      time_distribution: distributionRows,
    })
    expect(mockBqQuery).toHaveBeenCalledTimes(2)
  })

  it('handles mix of valid stats and unknown stats', async () => {
    const summaryRow = {
      tracked_percent: 75.0,
      total_tracked_minutes: 1080,
      productive_percent: 50.0,
      total_productive_minutes: 720,
      longest_category_id: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
      longest_start_time: '09:00:00',
      longest_end_time: '12:00:00',
      longest_duration_minutes: 180,
      longest_is_productive: true,
    }
    mockBqQuery.mockResolvedValueOnce([[summaryRow]] as any)

    const result = await getStats(userId, date, ['daily_summary', 'unknown_stat'])

    expect(result).toEqual({
      daily_summary: summaryRow,
      unknown_stat: { error: 'Unknown stat' },
    })
    expect(mockBqQuery).toHaveBeenCalledTimes(1)
  })

  it('handles all unknown stats without calling bq', async () => {
    const result = await getStats(userId, date, ['unknown_a', 'unknown_b'])

    expect(result).toEqual({
      unknown_a: { error: 'Unknown stat' },
      unknown_b: { error: 'Unknown stat' },
    })
    expect(mockBqQuery).not.toHaveBeenCalled()
  })

  it('handles empty stats array', async () => {
    const result = await getStats(userId, date, [])

    expect(result).toEqual({})
    expect(mockBqQuery).not.toHaveBeenCalled()
  })

  // ── error handling ────────────────────────────────────────

  it('throws if bq query fails', async () => {
    mockBqQuery.mockRejectedValueOnce(new Error('BQ error'))

    await expect(getStats(userId, date, ['daily_summary'])).rejects.toThrow('BQ error')
  })

  it('throws if one of multiple bq queries fails', async () => {
    mockBqQuery
      .mockResolvedValueOnce([[{ tracked_percent: 75 }]] as any)
      .mockRejectedValueOnce(new Error('BQ error on second query'))

    await expect(
      getStats(userId, date, ['daily_summary', 'time_distribution'])
    ).rejects.toThrow('BQ error on second query')
  })
})