import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne, transaction } from '../config/db';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { sendData, sendPaginated, parsePagination, buildPaginationMeta } from '../utils/response';
import { ApiError } from '../utils/errors';
import { Medicine, DoseLog } from '../types';

const router = Router();
router.use(authenticate);

// ============================================================
// POST /api/v1/medications — Create a medicine
// ============================================================
const createMedicineSchema = z.object({
  body: z.object({
    episode_id: z.string().uuid(),
    brand_name: z.string().min(1).max(200),
    generic_name: z.string().optional(),
    dosage: z.string().optional(),
    dose_form: z.enum(['tablet', 'capsule', 'syrup', 'injection', 'drops', 'cream', 'inhaler', 'patch', 'other']).default('tablet'),
    frequency: z.string().optional(),
    timing: z.array(z.object({
      hour: z.number().min(0).max(23),
      minute: z.number().min(0).max(59),
      label: z.string().optional(),
    })).optional(),
    duration_days: z.number().int().positive().optional(),
    meal_timing: z.enum(['before_meal', 'after_meal', 'with_meal', 'empty_stomach', 'any']).default('after_meal'),
    instructions: z.string().optional(),
    manufacturer: z.string().optional(),
    mrp: z.number().positive().optional(),
    is_critical: z.boolean().default(false),
    start_date: z.string().optional(),
  }),
});

router.post(
  '/',
  validate(createMedicineSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const b = req.body;
      const id = uuid();

      const rows = await query<Medicine>(
        `INSERT INTO medicines (id, episode_id, brand_name, generic_name, dosage, dose_form, frequency, timing, duration_days, meal_timing, instructions, manufacturer, mrp, is_critical, start_date)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
         RETURNING *`,
        [id, b.episode_id, b.brand_name, b.generic_name ?? null, b.dosage ?? null, b.dose_form, b.frequency ?? null, JSON.stringify(b.timing ?? []), b.duration_days ?? null, b.meal_timing, b.instructions ?? null, b.manufacturer ?? null, b.mrp ?? null, b.is_critical, b.start_date ?? new Date().toISOString().split('T')[0]]
      );

      sendData(res, rows[0], 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/medications?episode_id= — List medicines
// ============================================================
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const episodeId = req.query.episode_id as string;
    const profileId = req.query.profile_id as string;
    const activeOnly = req.query.active !== 'false';

    const conditions: string[] = [];
    const params: any[] = [];
    let idx = 1;

    if (episodeId) {
      conditions.push(`m.episode_id = $${idx++}`);
      params.push(episodeId);
    }

    if (profileId) {
      conditions.push(`e.profile_id = $${idx++}`);
      params.push(profileId);
    }

    if (activeOnly) {
      conditions.push('m.is_active = TRUE');
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const medicines = await query<Medicine>(
      `SELECT m.*, e.title as episode_title, e.profile_id
       FROM medicines m
       JOIN episodes e ON m.episode_id = e.id
       ${where}
       ORDER BY m.is_critical DESC, m.brand_name ASC`,
      params
    );

    sendData(res, medicines);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// GET /api/v1/medications/:id
// ============================================================
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const med = await queryOne<Medicine>('SELECT * FROM medicines WHERE id = $1', [req.params.id]);
    if (!med) throw ApiError.notFound('Medicine');
    sendData(res, med);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// PATCH /api/v1/medications/:id — Update medicine
// ============================================================
const updateMedicineSchema = z.object({
  body: z.object({
    brand_name: z.string().min(1).optional(),
    generic_name: z.string().optional(),
    dosage: z.string().optional(),
    dose_form: z.enum(['tablet', 'capsule', 'syrup', 'injection', 'drops', 'cream', 'inhaler', 'patch', 'other']).optional(),
    frequency: z.string().optional(),
    timing: z.array(z.object({ hour: z.number(), minute: z.number(), label: z.string().optional() })).optional(),
    duration_days: z.number().int().positive().optional(),
    meal_timing: z.enum(['before_meal', 'after_meal', 'with_meal', 'empty_stomach', 'any']).optional(),
    instructions: z.string().optional(),
    is_active: z.boolean().optional(),
    is_critical: z.boolean().optional(),
  }).refine(obj => Object.keys(obj).length > 0, { message: 'At least one field required' }),
});

router.patch(
  '/:id',
  validate(updateMedicineSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const fields = req.body;
      const setClauses: string[] = [];
      const values: any[] = [];
      let paramIdx = 1;

      for (const [key, value] of Object.entries(fields)) {
        if (key === 'timing') {
          setClauses.push(`${key} = $${paramIdx++}`);
          values.push(JSON.stringify(value));
        } else {
          setClauses.push(`${key} = $${paramIdx++}`);
          values.push(value);
        }
      }

      values.push(req.params.id);

      const rows = await query<Medicine>(
        `UPDATE medicines SET ${setClauses.join(', ')} WHERE id = $${paramIdx} RETURNING *`,
        values
      );

      if (rows.length === 0) throw ApiError.notFound('Medicine');
      sendData(res, rows[0]);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// DELETE /api/v1/medications/:id — Deactivate medicine
// ============================================================
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await query(
      'UPDATE medicines SET is_active = FALSE WHERE id = $1 RETURNING id',
      [req.params.id]
    );
    if (result.length === 0) throw ApiError.notFound('Medicine');
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ============================================================
// DOSE LOGS
// ============================================================

// POST /api/v1/medications/:id/dose-logs — Log a dose
const createDoseLogSchema = z.object({
  body: z.object({
    scheduled_time: z.string().datetime(),
    actual_time: z.string().datetime().optional(),
    status: z.enum(['pending', 'taken', 'missed', 'skipped', 'snoozed']).default('taken'),
  }),
});

router.post(
  '/:id/dose-logs',
  validate(createDoseLogSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Verify medicine exists
      const med = await queryOne('SELECT id FROM medicines WHERE id = $1', [req.params.id]);
      if (!med) throw ApiError.notFound('Medicine');

      const { scheduled_time, actual_time, status } = req.body;
      const id = uuid();

      const rows = await query<DoseLog>(
        `INSERT INTO dose_logs (id, medicine_id, scheduled_time, actual_time, status)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [id, req.params.id, scheduled_time, actual_time ?? (status === 'taken' ? new Date().toISOString() : null), status]
      );

      sendData(res, rows[0], 201);
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/v1/medications/:id/dose-logs — List dose logs for medicine
router.get('/:id/dose-logs', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { page, perPage, offset } = parsePagination(req.query as any);

    const [{ count }] = await query<{ count: string }>(
      'SELECT COUNT(*) as count FROM dose_logs WHERE medicine_id = $1',
      [req.params.id]
    );

    const logs = await query<DoseLog>(
      `SELECT * FROM dose_logs WHERE medicine_id = $1
       ORDER BY scheduled_time DESC
       LIMIT $2 OFFSET $3`,
      [req.params.id, perPage, offset]
    );

    sendPaginated(res, logs, buildPaginationMeta(parseInt(count), page, perPage));
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/medications/dose-logs/:logId — Update dose log status
const updateDoseLogSchema = z.object({
  body: z.object({
    status: z.enum(['pending', 'taken', 'missed', 'skipped', 'snoozed']),
    actual_time: z.string().datetime().optional(),
  }),
});

router.patch(
  '/dose-logs/:logId',
  validate(updateDoseLogSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { status, actual_time } = req.body;

      const rows = await query<DoseLog>(
        `UPDATE dose_logs SET status = $1, actual_time = $2 WHERE id = $3 RETURNING *`,
        [status, actual_time ?? (status === 'taken' ? new Date().toISOString() : null), req.params.logId]
      );

      if (rows.length === 0) throw ApiError.notFound('Dose log');
      sendData(res, rows[0]);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
