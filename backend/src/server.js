import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import healthRoutes from './routes/health.js';

// Muat konfigurasi environment dari root project jika ada
dotenv.config({ path: '../.env' });
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/', healthRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({
    name: 'AI Personal Finance API',
    status: 'running',
    healthCheck: '/health',
  });
});

// Start Server
app.listen(PORT, () => {
  console.log(`[Finance Backend] Server running on http://localhost:${PORT}`);
  console.log(`[Finance Backend] Health check endpoint: http://localhost:${PORT}/health`);
});

export default app;
