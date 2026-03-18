import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { getCategories, createCategory } from '../services/categories';

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;

  try {
    const categories = await getCategories(userId);
    res.json(categories);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  const { name, color } = req.body;

  if (!name || !color) {
    res.status(400).json({ error: 'name and color are required' });
    return;
  }

  try {
    const category = await createCategory(userId, name, color);
    res.json(category);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create category' });
  }
});

export default router;