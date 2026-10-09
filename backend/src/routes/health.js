import express from 'express';

const router = express.Router();

/**
 * GET /health
 * Endpoint health check untuk memverifikasi server backend aktif dan sehat.
 */
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'AI Personal Finance Backend',
    uptime: `${Math.floor(process.uptime())}s`,
    timestamp: new Date().toISOString(),
  });
});

export default router;
