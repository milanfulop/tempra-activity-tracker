import dotenv from 'dotenv';
dotenv.config();

import { supabase } from "./src/config/config"

async function getToken() {
  if (!process.env.TEST_EMAIL || !process.env.TEST_PASSWORD) return;

  const { data } = await supabase.auth.signInWithPassword({
    email: process.env.TEST_EMAIL,
    password: process.env.TEST_PASSWORD
  });
  console.log(data.session?.access_token);
}

getToken();