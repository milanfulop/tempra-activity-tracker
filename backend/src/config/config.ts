import { createClient } from '@supabase/supabase-js';
import { Pool } from 'pg';
import { BigQuery } from '@google-cloud/bigquery';
import * as dotenv from 'dotenv';
dotenv.config();

if(!process.env.PORT) 
  console.error("CRITICAL: dotenv doesnt work")
const PORT = process.env.PORT;

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
)

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export const bq = new BigQuery({
  projectId: 'activity-tracker-statistics',
  credentials: JSON.parse(process.env.BQ_CREDENTIALS_JSON!),
});

export default {
  port: PORT,
};