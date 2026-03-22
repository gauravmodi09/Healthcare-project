import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { query, queryOne } from '../config/db';
import { authenticate } from '../middleware/auth';
import { requireRole } from '../middleware/rbac';
import { validate } from '../middleware/validate';
import { sendData, sendPaginated, parsePagination, buildPaginationMeta } from '../utils/response';
import { ApiError } from '../utils/errors';
import { Doctor } from '../types';

const router = Router();

// ============================================================
// GET /api/v1/doctors — List/search doctors (authenticated)
// ============================================================
const listDoctorsSchema = z.object({
  query: z.object({
    specialty: z.string().optional(),
    city: z.string().optional(),
    q: z.string().optional(),
    page: z.string().optional(),
    per_page: z.string().optional(),
  }),
});

router.get(
  '/',
  authenticate,
  validate(listDoctorsSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { page, perPage, offset } = parsePagination(req.query as any);
      const conditions: string[] = ['d.is_verified = TRUE'];
      const params: any[] = [];
      let paramIdx = 1;

      if (req.query.specialty) {
        conditions.push(`d.specialty = $${paramIdx++}`);
        params.push(req.query.specialty);
      }

      if (req.query.city) {
        conditions.push(`h.city = $${paramIdx++}`);
        params.push(req.query.city);
      }

      if (req.query.q) {
        conditions.push(`d.name ILIKE $${paramIdx++}`);
        params.push(`%${req.query.q}%`);
      }

      const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      // Count
      const countParams = [...params];
      const [{ count }] = await query<{ count: string }>(
        `SELECT COUNT(*) as count FROM doctors d LEFT JOIN hospitals h ON d.hospital_id = h.id ${where}`,
        countParams
      );

      // Fetch
      params.push(perPage, offset);
      const doctors = await query(
        `SELECT d.id, d.name, d.specialty, d.qualification, d.registration_number, d.consultation_fee_inr, d.profile_photo_url,
                h.name as hospital_name, h.city as hospital_city
         FROM doctors d
         LEFT JOIN hospitals h ON d.hospital_id = h.id
         ${where}
         ORDER BY d.name ASC
         LIMIT $${paramIdx++} OFFSET $${paramIdx}`,
        params
      );

      sendPaginated(res, doctors, buildPaginationMeta(parseInt(count), page, perPage));
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/doctors/:id — Get single doctor (public info)
// ============================================================
router.get(
  '/:id',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const doctor = await queryOne(
        `SELECT d.id, d.name, d.email, d.specialty, d.qualification, d.registration_number,
                d.consultation_fee_inr, d.profile_photo_url, d.is_verified,
                h.name as hospital_name, h.city as hospital_city, h.address as hospital_address
         FROM doctors d
         LEFT JOIN hospitals h ON d.hospital_id = h.id
         WHERE d.id = $1`,
        [req.params.id]
      );

      if (!doctor) throw ApiError.notFound('Doctor');
      sendData(res, doctor);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// PATCH /api/v1/doctors/me — Update own doctor profile
// ============================================================
const updateDoctorSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(200).optional(),
    specialty: z.string().optional(),
    qualification: z.string().optional(),
    phone: z.string().max(15).optional(),
    consultation_fee_inr: z.number().positive().optional(),
    profile_photo_url: z.string().url().optional(),
  }).refine(obj => Object.keys(obj).length > 0, { message: 'At least one field required' }),
});

router.patch(
  '/me',
  authenticate,
  requireRole('doctor'),
  validate(updateDoctorSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const fields = req.body;
      const setClauses: string[] = [];
      const values: any[] = [];
      let paramIdx = 1;

      for (const [key, value] of Object.entries(fields)) {
        setClauses.push(`${key} = $${paramIdx++}`);
        values.push(value);
      }

      values.push(req.user!.sub);

      const rows = await query(
        `UPDATE doctors SET ${setClauses.join(', ')} WHERE id = $${paramIdx}
         RETURNING id, email, name, specialty, qualification, phone, consultation_fee_inr, profile_photo_url, is_verified`,
        values
      );

      if (rows.length === 0) throw ApiError.notFound('Doctor');
      sendData(res, rows[0]);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/doctors/me/patients — Doctor's linked patients
// ============================================================
router.get(
  '/me/patients',
  authenticate,
  requireRole('doctor'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patients = await query(
        `SELECT p.id, p.name, p.date_of_birth, p.gender, p.blood_group, p.avatar_emoji,
                p.known_conditions, p.allergies, pdl.status, pdl.linked_at
         FROM patient_doctor_links pdl
         JOIN profiles p ON pdl.profile_id = p.id
         WHERE pdl.doctor_id = $1 AND pdl.status = 'active'
         ORDER BY pdl.linked_at DESC`,
        [req.user!.sub]
      );

      sendData(res, patients);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
