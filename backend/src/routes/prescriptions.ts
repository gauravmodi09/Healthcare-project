import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne } from '../config/db';
import { authenticate } from '../middleware/auth';
import { requireRole } from '../middleware/rbac';
import { validate } from '../middleware/validate';
import { sendData, sendPaginated, parsePagination, buildPaginationMeta } from '../utils/response';
import { ApiError } from '../utils/errors';
import { Prescription } from '../types';

const router = Router();
router.use(authenticate);

// ============================================================
// POST /api/v1/prescriptions — Create prescription (doctor only)
// ============================================================
const createPrescriptionSchema = z.object({
  body: z.object({
    profile_id: z.string().uuid(),
    episode_id: z.string().uuid().optional(),
    medicines: z.array(z.object({
      brand_name: z.string(),
      generic_name: z.string().optional(),
      dosage: z.string().optional(),
      dose_form: z.string().optional(),
      frequency: z.string().optional(),
      duration_days: z.number().optional(),
      meal_timing: z.string().optional(),
      instructions: z.string().optional(),
    })).min(1),
    diagnosis: z.string().optional(),
    notes: z.string().optional(),
    digital_signature: z.string().optional(),
  }),
});

router.post(
  '/',
  requireRole('doctor'),
  validate(createPrescriptionSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { profile_id, episode_id, medicines, diagnosis, notes, digital_signature } = req.body;
      const doctorId = req.user!.sub;

      // Verify profile exists
      const profile = await queryOne('SELECT id FROM profiles WHERE id = $1', [profile_id]);
      if (!profile) throw ApiError.notFound('Profile');

      const id = uuid();
      const rows = await query<Prescription>(
        `INSERT INTO prescriptions (id, doctor_id, profile_id, episode_id, medicines, diagnosis, notes, digital_signature)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [id, doctorId, profile_id, episode_id ?? null, JSON.stringify(medicines), diagnosis ?? null, notes ?? null, digital_signature ?? null]
      );

      sendData(res, rows[0], 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/prescriptions — List prescriptions
// ============================================================
const listPrescriptionsSchema = z.object({
  query: z.object({
    profile_id: z.string().uuid().optional(),
    episode_id: z.string().uuid().optional(),
    page: z.string().optional(),
    per_page: z.string().optional(),
  }),
});

router.get(
  '/',
  validate(listPrescriptionsSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { page, perPage, offset } = parsePagination(req.query as any);
      const conditions: string[] = [];
      const params: any[] = [];
      let paramIdx = 1;

      // Scope by role
      if (req.user!.role === 'patient') {
        conditions.push(`rx.profile_id IN (SELECT id FROM profiles WHERE user_id = $${paramIdx++})`);
        params.push(req.user!.sub);
      } else {
        conditions.push(`rx.doctor_id = $${paramIdx++}`);
        params.push(req.user!.sub);
      }

      if (req.query.profile_id) {
        conditions.push(`rx.profile_id = $${paramIdx++}`);
        params.push(req.query.profile_id);
      }
      if (req.query.episode_id) {
        conditions.push(`rx.episode_id = $${paramIdx++}`);
        params.push(req.query.episode_id);
      }

      const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const [{ count }] = await query<{ count: string }>(
        `SELECT COUNT(*) as count FROM prescriptions rx ${where}`,
        [...params]
      );

      params.push(perPage, offset);
      const prescriptions = await query(
        `SELECT rx.*, d.name as doctor_name, d.specialty as doctor_specialty, p.name as patient_name
         FROM prescriptions rx
         JOIN doctors d ON rx.doctor_id = d.id
         JOIN profiles p ON rx.profile_id = p.id
         ${where}
         ORDER BY rx.created_at DESC
         LIMIT $${paramIdx++} OFFSET $${paramIdx}`,
        params
      );

      sendPaginated(res, prescriptions, buildPaginationMeta(parseInt(count), page, perPage));
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/prescriptions/:id — Get single prescription
// ============================================================
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const prescription = await queryOne(
      `SELECT rx.*, d.name as doctor_name, d.specialty as doctor_specialty,
              d.registration_number as doctor_registration, d.qualification as doctor_qualification,
              p.name as patient_name, p.date_of_birth, p.gender
       FROM prescriptions rx
       JOIN doctors d ON rx.doctor_id = d.id
       JOIN profiles p ON rx.profile_id = p.id
       WHERE rx.id = $1`,
      [req.params.id]
    );

    if (!prescription) throw ApiError.notFound('Prescription');

    // Access control
    if (req.user!.role === 'patient') {
      const ownsProfile = await queryOne(
        'SELECT id FROM profiles WHERE id = $1 AND user_id = $2',
        [prescription.profile_id, req.user!.sub]
      );
      if (!ownsProfile) throw ApiError.forbidden();
    } else if (req.user!.role === 'doctor' && prescription.doctor_id !== req.user!.sub) {
      throw ApiError.forbidden();
    }

    sendData(res, prescription);
  } catch (err) {
    next(err);
  }
});

export default router;
