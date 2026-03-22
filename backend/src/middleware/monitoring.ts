import { Request, Response, NextFunction } from 'express';
import { v4 as uuid } from 'uuid';
import { checkConnection } from '../config/db';

// ── Metrics store ──
const metrics = {
  requestCount: 0,
  errorCount: 0,
  totalResponseTime: 0,
  startTime: Date.now(),
};

/**
 * Correlation ID + request logging middleware.
 * Adds `x-correlation-id` header to every request/response.
 */
export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const correlationId = (req.headers['x-correlation-id'] as string) || uuid();
  req.headers['x-correlation-id'] = correlationId;
  res.setHeader('x-correlation-id', correlationId);

  const start = Date.now();
  metrics.requestCount++;

  res.on('finish', () => {
    const duration = Date.now() - start;
    metrics.totalResponseTime += duration;

    const level = res.statusCode >= 400 ? 'warn' : 'info';
    const logData = {
      correlationId,
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.headers['user-agent']?.substring(0, 80),
    };

    if (res.statusCode >= 400) {
      metrics.errorCount++;
    }

    console[level === 'warn' ? 'warn' : 'log'](
      `[${level.toUpperCase()}] ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`,
      JSON.stringify(logData)
    );
  });

  next();
}

/**
 * Health check endpoint handler.
 * Returns system status, uptime, and dependency connectivity.
 */
export async function healthCheck(_req: Request, res: Response) {
  const uptime = Math.floor((Date.now() - metrics.startTime) / 1000);

  let dbConnected = false;
  try {
    dbConnected = await checkConnection();
  } catch {
    dbConnected = false;
  }

  let redisConnected = false;
  try {
    // Redis check — attempt a basic ping via the REDIS_URL
    const net = await import('net');
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    const url = new URL(redisUrl);
    redisConnected = await new Promise<boolean>((resolve) => {
      const socket = net.createConnection(
        { host: url.hostname, port: parseInt(url.port || '6379') },
        () => {
          socket.end();
          resolve(true);
        }
      );
      socket.on('error', () => resolve(false));
      socket.setTimeout(2000, () => {
        socket.destroy();
        resolve(false);
      });
    });
  } catch {
    redisConnected = false;
  }

  const allHealthy = dbConnected && redisConnected;
  const status = allHealthy ? 'healthy' : 'degraded';

  res.status(allHealthy ? 200 : 503).json({
    status,
    uptime: `${uptime}s`,
    version: process.env.npm_package_version || '1.0.0',
    checks: {
      database: dbConnected ? 'connected' : 'disconnected',
      redis: redisConnected ? 'connected' : 'disconnected',
    },
    metrics: {
      totalRequests: metrics.requestCount,
      errorCount: metrics.errorCount,
      errorRate: metrics.requestCount > 0
        ? `${((metrics.errorCount / metrics.requestCount) * 100).toFixed(2)}%`
        : '0%',
      avgResponseTime: metrics.requestCount > 0
        ? `${Math.round(metrics.totalResponseTime / metrics.requestCount)}ms`
        : '0ms',
    },
  });
}
