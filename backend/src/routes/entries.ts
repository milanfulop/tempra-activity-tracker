import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { getEntries, createEntry, updateEntry, deleteEntry } from '../services/entries';
import { requireUser } from '../utils/requireUser';

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId)  { 
      return;
  }

  try {
    const entries = await getEntries(userId);
    res.json(entries);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch entries' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId)  { 
      return;
  }

  try {
    const entries = await createEntry(userId);
    res.json(entries);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch entries' });
  }
});

export default router;