import express from 'express';
import { supabaseAdmin } from '../lib/supabase.js';

const router = express.Router();

/**
 * GET /health
 * Endpoint health check komprehensif: memverifikasi server aktif dan database Supabase terkoneksi.
 */
router.get('/health', async (req, res) => {
  let dbStatus = 'disconnected';
  let dbError = null;

  try {
    // Ping tabel profiles di Supabase menggunakan service role
    const { error } = await supabaseAdmin
      .from('profiles')
      .select('count', { count: 'exact', head: true });

    if (error) {
      dbError = error.message;
      dbStatus = 'error';
    } else {
      dbStatus = 'connected';
    }
  } catch (err) {
    dbError = err.message;
    dbStatus = 'error';
  }

  const isHealthy = dbStatus === 'connected';

  res.status(isHealthy ? 200 : 503).json({
    status: isHealthy ? 'ok' : 'degraded',
    service: 'AI Personal Finance Backend',
    database: dbStatus,
    ...(dbError && { database_error: dbError }),
    uptime: `${Math.floor(process.uptime())}s`,
    timestamp: new Date().toISOString(),
  });
});

export default router;
