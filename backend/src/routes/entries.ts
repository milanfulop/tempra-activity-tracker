import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { getEntries, createEntry, updateEntry, deleteEntry } from '../services/entries';

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id

  try {
    const entries = await getEntries(userId);
    res.json(entries);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch entries' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id

  try {
    const entries = await createEntry(userId);
    // upload logic here
    // res.json(entries);
  } catch (err) {
    res.status(500).json({ error: 'Failed to upload entries' });
  }
});

export default router;