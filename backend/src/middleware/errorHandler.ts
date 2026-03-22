import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/errors';

/**
 * Centralized error handler — must be registered last.
 * Converts ApiError instances to structured JSON; hides internals for unexpected errors.
 */
export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        ...(err.details ? { details: err.details } : {}),
      },
    });
  }

  // Unexpected error — log but don't expose details
  console.error('Unhandled error:', err);

  return res.status(500).json({
    error: {
      code: 'internal_error',
      message: 'Internal server error',
    },
  });
}
