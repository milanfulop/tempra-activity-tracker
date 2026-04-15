import express from 'express';
import { getAppVersion } from '../services/app_config';

const router = express.Router();

router.get('/version', async (_req, res) => {
  try {
    const version = await getAppVersion();
    res.json({ version });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch version' });
  }
});

export default router;