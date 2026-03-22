import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env';
import { checkConnection } from './config/db';
import { errorHandler } from './middleware/errorHandler';

// Service imports
import { initWebSocket, getConnectedCount } from './services/websocket';
import { initAPNProvider, shutdownAPNProvider } from './services/pushNotification';
import { startScheduledJobs, shutdownQueues, getQueueHealth } from './services/jobQueue';

// Route imports
import authRoutes from './routes/auth';
import profileRoutes from './routes/profiles';
import doctorRoutes from './routes/doctors';
import vitalRoutes from './routes/vitals';
import medicationRoutes from './routes/medications';
import messageRoutes from './routes/messages';
import appointmentRoutes from './routes/appointments';
import prescriptionRoutes from './routes/prescriptions';
import abdmRoutes from './routes/abdm';
import paymentRoutes from './routes/payments';
import notificationRoutes from './routes/notifications';
import achievementRoutes from './routes/achievements';
import invoiceRoutes from './routes/invoices';

const app = express();
const httpServer = createServer(app);

// ============================================================
// WebSocket server (Socket.IO)
// ============================================================
const io = initWebSocket(httpServer);

// ============================================================
// Push notification provider
// ============================================================
if (process.env.APN_KEY_ID && process.env.APN_TEAM_ID) {
  initAPNProvider();
} else {
  console.warn('[APN] Missing APN_KEY_ID / APN_TEAM_ID — push notifications disabled');
}

// ============================================================
// Middleware
// ============================================================
app.use(helmet());
app.use(cors({
  origin: env.NODE_ENV === 'production'
    ? ['https://medcare.app']
    : ['http://localhost:3000', 'http://localhost:3001'],
  credentials: true,
}));
app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ============================================================
// Health check
// ============================================================
app.get('/health', async (_req, res) => {
  const dbOk = await checkConnection();
  const wsClients = await getConnectedCount();
  let queueHealth = {};
  try {
    queueHealth = await getQueueHealth();
  } catch { /* redis may not be available */ }

  res.status(dbOk ? 200 : 503).json({
    status: dbOk ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    services: {
      database: dbOk ? 'connected' : 'disconnected',
      websocket: { connected_clients: wsClients },
      queues: queueHealth,
    },
  });
});

// ============================================================
// API v1 Routes
// ============================================================
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/profiles', profileRoutes);
app.use('/api/v1/doctors', doctorRoutes);
app.use('/api/v1/vitals', vitalRoutes);
app.use('/api/v1/medications', medicationRoutes);
app.use('/api/v1/messages', messageRoutes);
app.use('/api/v1/appointments', appointmentRoutes);
app.use('/api/v1/prescriptions', prescriptionRoutes);
app.use('/api/v1/abdm', abdmRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/achievements', achievementRoutes);
app.use('/api/v1/invoices', invoiceRoutes);

// ============================================================
// 404 handler
// ============================================================
app.use((_req, res) => {
  res.status(404).json({
    error: {
      code: 'not_found',
      message: 'Endpoint not found',
    },
  });
});

// ============================================================
// Centralized error handler (must be last)
// ============================================================
app.use(errorHandler);

// ============================================================
// Start server
// ============================================================
httpServer.listen(env.PORT, async () => {
  console.log(`MedCare API running on port ${env.PORT}`);
  console.log(`Environment: ${env.NODE_ENV}`);
  console.log(`Health: http://localhost:${env.PORT}/health`);

  // Start background job processors
  try {
    await startScheduledJobs();
    console.log('Background job queues started');
  } catch (err) {
    console.error('Failed to start job queues (Redis may not be available):', err);
  }
});

// ============================================================
// Graceful shutdown
// ============================================================
async function gracefulShutdown(signal: string) {
  console.log(`\n${signal} received — shutting down gracefully...`);
  shutdownAPNProvider();
  await shutdownQueues();
  httpServer.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

export default app;
