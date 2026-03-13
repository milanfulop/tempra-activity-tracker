import { createClient } from '@supabase/supabase-js'
import { Request, Response, NextFunction } from 'express'

// console.log("dotenv data: ", process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!)
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
)

export async function authMiddleware(req: Request, res: Response, next: NextFunction) {
    const token = req.headers.authorization?.replace('Bearer ', '')
  
  if (!token) return res.status(401).json({ error: 'Unauthorized' })

  const { data, error } = await supabase.auth.getUser(token)

  if (error || !data.user) return res.status(401).json({ error: 'Invalid token' })

  req.user = data.user
  next()
}