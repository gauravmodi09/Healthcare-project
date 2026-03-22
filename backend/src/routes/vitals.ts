import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne } from '../config/db';
import { authenticate } from '../middleware/auth';
import { requireRole } from '../middleware/rbac';
import { validate } from '../middleware/validate';
import { sendData, sendPaginated, parsePagination, buildPaginationMeta } from '../utils/response';
import { ApiError } from '../utils/errors';
import { Vital } from '../types';

const router = Router();
router.use(authenticate);

// ============================================================
// Helper: verify profile ownership for patients
// ============================================================
async function verifyProfileAccess(profileId: string, userId: string, role: string) {
  if (role === 'patient') {
    const profile = await queryOne('SELECT id FROM profiles WHERE id = $1 AND user_id = $2', [profileId, userId]);
    if (!profile) throw ApiError.forbidden('Not your profile');
  }
  // Doctors can access linked patient profiles (simplified — full impl would check patient_doctor_links)
}

// ============================================================
// POST /api/v1/vitals — Record a vital
// ============================================================
const createVitalSchema = z.object({
  body: z.object({
    profile_id: z.string().uuid(),
    type: z.enum(['bp', 'hr', 'spo2', 'weight', 'temp', 'glucose']),
    value: z.union([
      z.object({ systolic: z.number(), diastolic: z.number() }),  // bp
      z.object({ bpm: z.number() }),                              // hr
      z.object({ percentage: z.number() }),                        // spo2
      z.object({ kg: z.number() }),                                // weight
      z.object({ celsius: z.number() }),                           // temp
      z.object({ mg_dl: z.number(), fasting: z.boolean().optional() }), // glucose
    ]),
    source: z.enum(['manual', 'healthkit', 'wearable']).default('manual'),
    recorded_at: z.string().datetime().optional(),
  }),
});

router.post(
  '/',
  validate(createVitalSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { profile_id, type, value, source, recorded_at } = req.body;
      await verifyProfileAccess(profile_id, req.user!.sub, req.user!.role);

      const id = uuid();
      const rows = await query<Vital>(
        `INSERT INTO vitals (id, profile_id, type, value, source, recorded_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [id, profile_id, type, JSON.stringify(value), source, recorded_at ?? new Date().toISOString()]
      );

      sendData(res, rows[0], 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/vitals?profile_id=&type=&page=&per_page=
// ============================================================
const listVitalsSchema = z.object({
  query: z.object({
    profile_id: z.string().uuid(),
    type: z.enum(['bp', 'hr', 'spo2', 'weight', 'temp', 'glucose']).optional(),
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
    page: z.string().optional(),
    per_page: z.string().optional(),
  }),
});

router.get(
  '/',
  validate(listVitalsSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { profile_id, type, from, to } = req.query as any;
      await verifyProfileAccess(profile_id, req.user!.sub, req.user!.role);

      const { page, perPage, offset } = parsePagination(req.query as any);

      const conditions = ['profile_id = $1'];
      const params: any[] = [profile_id];
      let paramIdx = 2;

      if (type) {
        conditions.push(`type = $${paramIdx++}`);
        params.push(type);
      }
      if (from) {
        conditions.push(`recorded_at >= $${paramIdx++}`);
        params.push(from);
      }
      if (to) {
        conditions.push(`recorded_at <= $${paramIdx++}`);
        params.push(to);
      }

      const where = conditions.join(' AND ');

      const [{ count }] = await query<{ count: string }>(
        `SELECT COUNT(*) as count FROM vitals WHERE ${where}`,
        [...params]
      );

      params.push(perPage, offset);
      const vitals = await query<Vital>(
        `SELECT * FROM vitals WHERE ${where} ORDER BY recorded_at DESC LIMIT $${paramIdx++} OFFSET $${paramIdx}`,
        params
      );

      sendPaginated(res, vitals, buildPaginationMeta(parseInt(count), page, perPage));
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/vitals/:id — Single vital
// ============================================================
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const vital = await queryOne<Vital>('SELECT * FROM vitals WHERE id = $1', [req.params.id]);
    if (!vital) throw ApiError.notFound('Vital');
    await verifyProfileAccess(vital.profile_id, req.user!.sub, req.user!.role);
    sendData(res, vital);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// DELETE /api/v1/vitals/:id
// ============================================================
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const vital = await queryOne<Vital>('SELECT * FROM vitals WHERE id = $1', [req.params.id]);
    if (!vital) throw ApiError.notFound('Vital');
    await verifyProfileAccess(vital.profile_id, req.user!.sub, req.user!.role);

    await query('DELETE FROM vitals WHERE id = $1', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ============================================================
// GET /api/v1/vitals/latest/:profileId — Latest of each type
// ============================================================
router.get('/latest/:profileId', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profileId = req.params.profileId;
    await verifyProfileAccess(profileId, req.user!.sub, req.user!.role);

    const vitals = await query<Vital>(
      `SELECT DISTINCT ON (type) *
       FROM vitals
       WHERE profile_id = $1
       ORDER BY type, recorded_at DESC`,
      [profileId]
    );

    sendData(res, vitals);
  } catch (err) {
    next(err);
  }
});

export default router;
