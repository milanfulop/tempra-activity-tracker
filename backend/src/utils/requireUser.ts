import { Request, Response } from 'express';

function requireUser(req: Request, res: Response): string | null {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return null;
    }
    return req.user.id;
}

export { requireUser };