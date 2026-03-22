import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne } from '../config/db';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { sendData, sendPaginated, parsePagination, buildPaginationMeta } from '../utils/response';
import { ApiError } from '../utils/errors';
import { Appointment } from '../types';

const router = Router();
router.use(authenticate);

// ============================================================
// POST /api/v1/appointments — Create appointment
// ============================================================
const createAppointmentSchema = z.object({
  body: z.object({
    profile_id: z.string().uuid(),
    doctor_id: z.string().uuid(),
    type: z.enum(['in_person', 'video', 'audio']).default('in_person'),
    scheduled_at: z.string().datetime(),
    duration_minutes: z.number().int().min(5).max(120).default(30),
    notes: z.string().max(1000).optional(),
  }),
});

router.post(
  '/',
  validate(createAppointmentSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { profile_id, doctor_id, type, scheduled_at, duration_minutes, notes } = req.body;

      // Verify doctor exists
      const doctor = await queryOne('SELECT id, name FROM doctors WHERE id = $1', [doctor_id]);
      if (!doctor) throw ApiError.notFound('Doctor');

      // Check for scheduling conflicts (same doctor, overlapping time)
      const scheduledDate = new Date(scheduled_at);
      const endDate = new Date(scheduledDate.getTime() + duration_minutes * 60000);

      const conflict = await queryOne(
        `SELECT id FROM appointments
         WHERE doctor_id = $1
         AND status = 'scheduled'
         AND scheduled_at < $2
         AND (scheduled_at + (duration_minutes || ' minutes')::interval) > $3`,
        [doctor_id, endDate.toISOString(), scheduled_at]
      );

      if (conflict) {
        throw ApiError.conflict('Doctor has a scheduling conflict at this time');
      }

      const id = uuid();
      const rows = await query<Appointment>(
        `INSERT INTO appointments (id, profile_id, doctor_id, type, scheduled_at, duration_minutes, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [id, profile_id, doctor_id, type, scheduled_at, duration_minutes, notes ?? null]
      );

      sendData(res, rows[0], 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/appointments — List appointments
// ============================================================
const listAppointmentsSchema = z.object({
  query: z.object({
    profile_id: z.string().uuid().optional(),
    status: z.enum(['scheduled', 'completed', 'cancelled', 'no_show']).optional(),
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
    page: z.string().optional(),
    per_page: z.string().optional(),
  }),
});

router.get(
  '/',
  validate(listAppointmentsSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { page, perPage, offset } = parsePagination(req.query as any);
      const conditions: string[] = [];
      const params: any[] = [];
      let paramIdx = 1;

      // Scope by role
      if (req.user!.role === 'patient') {
        // Get all profiles for this user
        conditions.push(`a.profile_id IN (SELECT id FROM profiles WHERE user_id = $${paramIdx++})`);
        params.push(req.user!.sub);
      } else {
        conditions.push(`a.doctor_id = $${paramIdx++}`);
        params.push(req.user!.sub);
      }

      if (req.query.profile_id) {
        conditions.push(`a.profile_id = $${paramIdx++}`);
        params.push(req.query.profile_id);
      }
      if (req.query.status) {
        conditions.push(`a.status = $${paramIdx++}`);
        params.push(req.query.status);
      }
      if (req.query.from) {
        conditions.push(`a.scheduled_at >= $${paramIdx++}`);
        params.push(req.query.from);
      }
      if (req.query.to) {
        conditions.push(`a.scheduled_at <= $${paramIdx++}`);
        params.push(req.query.to);
      }

      const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const [{ count }] = await query<{ count: string }>(
        `SELECT COUNT(*) as count FROM appointments a ${where}`,
        [...params]
      );

      params.push(perPage, offset);
      const appointments = await query(
        `SELECT a.*, d.name as doctor_name, d.specialty as doctor_specialty, p.name as patient_name
         FROM appointments a
         JOIN doctors d ON a.doctor_id = d.id
         JOIN profiles p ON a.profile_id = p.id
         ${where}
         ORDER BY a.scheduled_at ASC
         LIMIT $${paramIdx++} OFFSET $${paramIdx}`,
        params
      );

      sendPaginated(res, appointments, buildPaginationMeta(parseInt(count), page, perPage));
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/appointments/:id
// ============================================================
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const appointment = await queryOne(
      `SELECT a.*, d.name as doctor_name, d.specialty as doctor_specialty, p.name as patient_name
       FROM appointments a
       JOIN doctors d ON a.doctor_id = d.id
       JOIN profiles p ON a.profile_id = p.id
       WHERE a.id = $1`,
      [req.params.id]
    );

    if (!appointment) throw ApiError.notFound('Appointment');
    sendData(res, appointment);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// PATCH /api/v1/appointments/:id — Update status or reschedule
// ============================================================
const updateAppointmentSchema = z.object({
  body: z.object({
    status: z.enum(['scheduled', 'completed', 'cancelled', 'no_show']).optional(),
    scheduled_at: z.string().datetime().optional(),
    duration_minutes: z.number().int().min(5).max(120).optional(),
    notes: z.string().max(1000).optional(),
  }).refine(obj => Object.keys(obj).length > 0, { message: 'At least one field required' }),
});

router.patch(
  '/:id',
  validate(updateAppointmentSchema),
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

      values.push(req.params.id);

      const rows = await query<Appointment>(
        `UPDATE appointments SET ${setClauses.join(', ')} WHERE id = $${paramIdx} RETURNING *`,
        values
      );

      if (rows.length === 0) throw ApiError.notFound('Appointment');
      sendData(res, rows[0]);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/appointments/:id/cancel — Cancel appointment
// ============================================================
router.post('/:id/cancel', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const rows = await query<Appointment>(
      `UPDATE appointments SET status = 'cancelled' WHERE id = $1 AND status = 'scheduled' RETURNING *`,
      [req.params.id]
    );

    if (rows.length === 0) throw ApiError.badRequest('Appointment not found or cannot be cancelled');
    sendData(res, rows[0]);
  } catch (err) {
    next(err);
  }
});

export default router;
