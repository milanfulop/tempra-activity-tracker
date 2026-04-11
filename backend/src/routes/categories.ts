import express from 'express';
import { authMiddleware } from '../middleware/auth';
import { getCategories, createCategory, updateCategory, deleteCategory } from '../services/categories';

const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  try {
    const categories = await getCategories(userId);
    res.json(categories);
  } catch (err) {
    console.error('getCategories error:', err);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  const { name, color, is_productive = false, is_sleep = false } = req.body;

  if (!name || !color) {
    res.status(400).json({ error: 'name and color are required' });
    return;
  }

  try {
    const category = await createCategory(userId, name, color, is_productive, is_sleep);
    res.json(category);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create category' });
  }
});

router.put('/:id', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  const categoryId = req.params.id as string;
  const { name, color, is_productive = false, is_sleep = false } = req.body;

  if (!name || !color) {
    res.status(400).json({ error: 'name and color are required' });
    return;
  }

  try {
    const category = await updateCategory(userId, categoryId, name, color, is_productive, is_sleep);
    res.json(category);
  } catch (err: any) {
    if (err.message === 'Category not found') {
      res.status(404).json({ error: 'Category not found' });
      return;
    }
    res.status(500).json({ error: 'Failed to update category' });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const userId = req.user!.id;
  const categoryId = req.params.id as string;

  try {
    await deleteCategory(userId, categoryId);
    res.status(204).send();
  } catch (err: any) {
    if (err.message === 'Category not found') {
      res.status(404).json({ error: 'Category not found' });
      return;
    }
    res.status(500).json({ error: 'Failed to delete category' });
  }
});

export default router;