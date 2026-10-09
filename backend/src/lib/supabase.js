import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Muat .env secara robust baik saat dijalankan dari folder backend maupun root
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootEnvPath = path.resolve(__dirname, '../../../.env');

dotenv.config({ path: rootEnvPath });
dotenv.config();

// Sanitasi SUPABASE_URL: hilangkan duplikasi prefix, /rest/v1, atau trailing slash
let rawUrl = (process.env.SUPABASE_URL || '').trim();
if (rawUrl.startsWith('SUPABASE_URL=')) {
  rawUrl = rawUrl.substring('SUPABASE_URL='.length).trim();
}
const cleanUrl = rawUrl.replace(/\/rest\/v1\/?$/, '').replace(/\/+$/, '');

const anonKey = (process.env.SUPABASE_ANON_KEY || '').trim();
const serviceRoleKey = (process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();

if (!cleanUrl || !serviceRoleKey) {
  console.warn('[Supabase Warning] SUPABASE_URL atau SUPABASE_SERVICE_ROLE_KEY belum terisi dengan benar di .env');
}

/**
 * 1. Admin Client (Service Role)
 * Digunakan untuk:
 * - Webhook WhatsApp (karena tidak ada sesi login browser/JWT).
 * - Background maintenance.
 * ATURAN ARSITEKTUR: Service Role melewati RLS, jadi query WAJIB selalu memfilter `user_id` secara eksplisit!
 */
export const supabaseAdmin = createClient(cleanUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

/**
 * 2. User Client Factory (Meneruskan JWT User)
 * Digunakan untuk:
 * - Request dari Web Dashboard yang melewati backend Express.
 * Backend meneruskan Bearer Token JWT milik user sehingga PostgreSQL RLS (auth.uid()) tetap berlaku ketat!
 *
 * @param {string} userJwtToken - Token JWT dari header Authorization request
 */
export function createUserClient(userJwtToken) {
  return createClient(cleanUrl, anonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: {
        Authorization: `Bearer ${userJwtToken}`,
      },
    },
  });
}
