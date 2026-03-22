import { Request, Response, NextFunction } from 'express';
import { UserRole } from '../types';
import { ApiError } from '../utils/errors';

/**
 * Role-based access control middleware.
 * Must run AFTER authenticate middleware.
 *
 * Usage: router.get('/doctors', authenticate, requireRole('doctor'), handler)
 */
export function requireRole(...roles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(ApiError.unauthorized());
    }

    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden(`Requires role: ${roles.join(' or ')}`));
    }

    next();
  };
}

/**
 * Middleware that allows any authenticated user but sets role context.
 * Useful for endpoints accessible by both patients and doctors.
 */
export function requireAnyRole(req: Request, _res: Response, next: NextFunction) {
  if (!req.user) {
    return next(ApiError.unauthorized());
  }
  next();
}
