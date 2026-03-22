import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { JwtPayload } from '../types';
import { ApiError } from '../utils/errors';

/**
 * JWT verification middleware.
 * Extracts Bearer token, verifies, and sets req.user.
 */
export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return next(ApiError.unauthorized('Missing authorization token'));
  }

  const token = header.slice(7);

  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as JwtPayload;
    req.user = payload;
    next();
  } catch (err) {
    return next(ApiError.unauthorized('Invalid or expired token'));
  }
}

/** Generate access + refresh token pair */
export function generateTokens(sub: string, role: 'patient' | 'doctor') {
  const accessToken = jwt.sign({ sub, role }, env.JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = jwt.sign({ sub, role }, env.JWT_REFRESH_SECRET, { expiresIn: '30d' });
  return { accessToken, refreshToken };
}

/** Verify a refresh token */
export function verifyRefreshToken(token: string): JwtPayload {
  try {
    return jwt.verify(token, env.JWT_REFRESH_SECRET) as JwtPayload;
  } catch {
    throw ApiError.unauthorized('Invalid refresh token');
  }
}
