import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { getStats } from '../services/statistics';

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  const { date, stats } = req.query;

  if (!date) {
    res.status(400).json({ error: 'date is required' });
    return;
  }

  if (!stats) {
    res.status(400).json({ error: 'stats is required' });
    return;
  }

  const statList = (stats as string).split(',');

  try {
    const result = await getStats(userId, date as string, statList);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

export default router;