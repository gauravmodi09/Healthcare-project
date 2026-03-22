import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env';
import { checkConnection } from './config/db';
import { errorHandler } from './middleware/errorHandler';

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

const app = express();

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
  res.status(dbOk ? 200 : 503).json({
    status: dbOk ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    services: {
      database: dbOk ? 'connected' : 'disconnected',
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
app.listen(env.PORT, () => {
  console.log(`MedCare API running on port ${env.PORT}`);
  console.log(`Environment: ${env.NODE_ENV}`);
  console.log(`Health: http://localhost:${env.PORT}/health`);
});

export default app;
