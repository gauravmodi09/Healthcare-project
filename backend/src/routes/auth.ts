import { Router, Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne } from '../config/db';
import { validate } from '../middleware/validate';
import { authenticate, generateTokens, verifyRefreshToken } from '../middleware/auth';
import { sendData } from '../utils/response';
import { ApiError } from '../utils/errors';
import { User, Doctor } from '../types';

const router = Router();

// ============================================================
// In-memory OTP store (mock — replace with MSG91/Redis in prod)
// ============================================================
const otpStore = new Map<string, { otp: string; expiresAt: number }>();

function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// ============================================================
// POST /api/v1/auth/send-otp — Patient OTP request
// ============================================================
const sendOtpSchema = z.object({
  body: z.object({
    phone: z.string().min(10).max(15).regex(/^\+?[0-9]+$/, 'Invalid phone number'),
  }),
});

router.post(
  '/send-otp',
  validate(sendOtpSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { phone } = req.body;
      const otp = generateOtp();

      // Store OTP with 5-minute expiry
      otpStore.set(phone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });

      // In production: send via MSG91
      console.log(`[OTP] ${phone} => ${otp}`);

      sendData(res, { message: 'OTP sent', phone, ...(process.env.NODE_ENV === 'development' ? { otp } : {}) });
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/auth/verify-otp — Patient OTP verification + login
// ============================================================
const verifyOtpSchema = z.object({
  body: z.object({
    phone: z.string().min(10).max(15),
    otp: z.string().length(6),
  }),
});

router.post(
  '/verify-otp',
  validate(verifyOtpSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { phone, otp } = req.body;

      const stored = otpStore.get(phone);
      if (!stored || stored.otp !== otp || stored.expiresAt < Date.now()) {
        throw ApiError.unauthorized('Invalid or expired OTP');
      }

      otpStore.delete(phone);

      // Upsert user
      let user = await queryOne<User>(
        'SELECT * FROM users WHERE phone = $1',
        [phone]
      );

      let isNewUser = false;

      if (!user) {
        isNewUser = true;
        const id = uuid();
        const rows = await query<User>(
          `INSERT INTO users (id, phone, phone_verified) VALUES ($1, $2, TRUE)
           RETURNING *`,
          [id, phone]
        );
        user = rows[0];

        // Auto-create a "self" profile
        await query(
          `INSERT INTO profiles (id, user_id, name, relation)
           VALUES ($1, $2, $3, 'self')`,
          [uuid(), id, 'Me']
        );
      } else if (!user.phone_verified) {
        await query('UPDATE users SET phone_verified = TRUE WHERE id = $1', [user.id]);
        user.phone_verified = true;
      }

      const tokens = generateTokens(user.id, 'patient');

      sendData(res, {
        user: { id: user.id, phone: user.phone, phone_verified: user.phone_verified },
        is_new_user: isNewUser,
        ...tokens,
      }, isNewUser ? 201 : 200);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/auth/doctor/login — Doctor email/password login
// ============================================================
const doctorLoginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(6),
  }),
});

router.post(
  '/doctor/login',
  validate(doctorLoginSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, password } = req.body;

      const doctor = await queryOne<Doctor>(
        'SELECT * FROM doctors WHERE email = $1',
        [email]
      );

      if (!doctor) {
        throw ApiError.unauthorized('Invalid email or password');
      }

      const valid = await bcrypt.compare(password, doctor.password_hash);
      if (!valid) {
        throw ApiError.unauthorized('Invalid email or password');
      }

      const tokens = generateTokens(doctor.id, 'doctor');

      sendData(res, {
        doctor: {
          id: doctor.id,
          email: doctor.email,
          name: doctor.name,
          specialty: doctor.specialty,
          is_verified: doctor.is_verified,
        },
        ...tokens,
      });
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/auth/doctor/register — Doctor registration
// ============================================================
const doctorRegisterSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(8),
    name: z.string().min(1).max(200),
    specialty: z.string().optional(),
    registration_number: z.string().optional(),
    qualification: z.string().optional(),
    phone: z.string().min(10).max(15).optional(),
    consultation_fee_inr: z.number().positive().optional(),
  }),
});

router.post(
  '/doctor/register',
  validate(doctorRegisterSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, password, name, specialty, registration_number, qualification, phone, consultation_fee_inr } = req.body;

      // Check duplicate
      const existing = await queryOne('SELECT id FROM doctors WHERE email = $1', [email]);
      if (existing) {
        throw ApiError.conflict('Email already registered');
      }

      const passwordHash = await bcrypt.hash(password, 12);
      const id = uuid();

      const rows = await query<Doctor>(
        `INSERT INTO doctors (id, email, password_hash, name, specialty, registration_number, qualification, phone, consultation_fee_inr)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING *`,
        [id, email, passwordHash, name, specialty ?? null, registration_number ?? null, qualification ?? null, phone ?? null, consultation_fee_inr ?? null]
      );

      const doctor = rows[0];
      const tokens = generateTokens(doctor.id, 'doctor');

      sendData(res, {
        doctor: {
          id: doctor.id,
          email: doctor.email,
          name: doctor.name,
          specialty: doctor.specialty,
          is_verified: doctor.is_verified,
        },
        ...tokens,
      }, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/auth/refresh — Refresh access token
// ============================================================
const refreshSchema = z.object({
  body: z.object({
    refresh_token: z.string(),
  }),
});

router.post(
  '/refresh',
  validate(refreshSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { refresh_token } = req.body;
      const payload = verifyRefreshToken(refresh_token);
      const tokens = generateTokens(payload.sub, payload.role);
      sendData(res, tokens);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/auth/me — Get current user info
// ============================================================
router.get(
  '/me',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { sub, role } = req.user!;

      if (role === 'patient') {
        const user = await queryOne<User>('SELECT id, phone, phone_verified, created_at FROM users WHERE id = $1', [sub]);
        if (!user) throw ApiError.notFound('User');
        sendData(res, { ...user, role });
      } else {
        const doctor = await queryOne(
          'SELECT id, email, name, specialty, registration_number, qualification, phone, consultation_fee_inr, is_verified, hospital_id, created_at FROM doctors WHERE id = $1',
          [sub]
        );
        if (!doctor) throw ApiError.notFound('Doctor');
        sendData(res, { ...doctor, role });
      }
    } catch (err) {
      next(err);
    }
  }
);

export default router;
