import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { getEntries, createEntry, deleteEntry } from '../services/entries';

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id
  const { date } = req.query;

  if(date == null) {
    res.status(400).json({error: 'Date is required'});
    return;
  }

  try {
    const entries = await getEntries(userId, date as string);
    res.json(entries);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch entries' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  const { start_time, end_time, category } = req.body;

  if (!start_time || !end_time || !category) {
    return res.status(400).json({ error: 'start_time, end_time, and category are required' });
  }

  try {
    const entry = await createEntry(userId, start_time, end_time, category);
    res.json(entry);
  } catch (err) {
    console.error('createEntry error:', err); // ← add this
    res.status(500).json({ error: 'Failed to create entry' });
  }
});

router.delete('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  const { start_time, end_time } = req.body;

  if (!start_time || !end_time) {
    return res.status(400).json({
      error: 'start_time and end_time are required',
    });
  }

  try {
    await deleteEntry(userId, start_time, end_time);
    res.json({ success: true });
  } catch (err) {
    console.error('deleteEntry error:', err);
    res.status(500).json({ error: 'Failed to delete entry' });
  }
});

export default router;