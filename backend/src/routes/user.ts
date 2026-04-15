import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { getProfile } from '../services/user';

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;

  try {
    const profile = await getProfile(userId);
    res.json({ created_at: profile.created_at });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

export default router;