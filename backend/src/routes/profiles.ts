import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne } from '../config/db';
import { authenticate } from '../middleware/auth';
import { requireRole } from '../middleware/rbac';
import { validate } from '../middleware/validate';
import { sendData, sendPaginated, parsePagination, buildPaginationMeta } from '../utils/response';
import { ApiError } from '../utils/errors';
import { Profile } from '../types';

const router = Router();

// All profile routes require patient auth
router.use(authenticate, requireRole('patient'));

// ============================================================
// GET /api/v1/profiles — List profiles for current user
// ============================================================
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.sub;
    const profiles = await query<Profile>(
      `SELECT * FROM profiles WHERE user_id = $1 AND is_active = TRUE ORDER BY relation = 'self' DESC, name ASC`,
      [userId]
    );
    sendData(res, profiles);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// GET /api/v1/profiles/:id — Get single profile
// ============================================================
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profile = await queryOne<Profile>(
      'SELECT * FROM profiles WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user!.sub]
    );
    if (!profile) throw ApiError.notFound('Profile');
    sendData(res, profile);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// POST /api/v1/profiles — Create a new family member profile
// ============================================================
const createProfileSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(200),
    date_of_birth: z.string().optional(),
    gender: z.enum(['male', 'female', 'other']).optional(),
    blood_group: z.string().max(10).optional(),
    avatar_emoji: z.string().max(10).optional(),
    relation: z.enum(['self', 'spouse', 'child', 'parent', 'sibling', 'other']),
    known_conditions: z.array(z.string()).optional(),
    allergies: z.array(z.string()).optional(),
    caregiver_name: z.string().max(200).optional(),
    caregiver_phone: z.string().max(15).optional(),
    abha_id: z.string().optional(),
  }),
});

router.post(
  '/',
  validate(createProfileSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user!.sub;
      const { name, date_of_birth, gender, blood_group, avatar_emoji, relation, known_conditions, allergies, caregiver_name, caregiver_phone, abha_id } = req.body;

      const id = uuid();
      const rows = await query<Profile>(
        `INSERT INTO profiles (id, user_id, name, date_of_birth, gender, blood_group, avatar_emoji, relation, known_conditions, allergies, caregiver_name, caregiver_phone, abha_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
         RETURNING *`,
        [id, userId, name, date_of_birth ?? null, gender ?? null, blood_group ?? null, avatar_emoji ?? '🩺', relation, known_conditions ?? [], allergies ?? [], caregiver_name ?? null, caregiver_phone ?? null, abha_id ?? null]
      );

      sendData(res, rows[0], 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// PATCH /api/v1/profiles/:id — Update profile
// ============================================================
const updateProfileSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(200).optional(),
    date_of_birth: z.string().optional(),
    gender: z.enum(['male', 'female', 'other']).optional(),
    blood_group: z.string().max(10).optional(),
    avatar_emoji: z.string().max(10).optional(),
    known_conditions: z.array(z.string()).optional(),
    allergies: z.array(z.string()).optional(),
    caregiver_name: z.string().max(200).optional(),
    caregiver_phone: z.string().max(15).optional(),
    abha_id: z.string().optional(),
  }).refine(obj => Object.keys(obj).length > 0, { message: 'At least one field required' }),
});

router.patch(
  '/:id',
  validate(updateProfileSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Verify ownership
      const existing = await queryOne<Profile>(
        'SELECT id FROM profiles WHERE id = $1 AND user_id = $2',
        [req.params.id, req.user!.sub]
      );
      if (!existing) throw ApiError.notFound('Profile');

      // Build dynamic SET clause
      const fields = req.body;
      const setClauses: string[] = [];
      const values: any[] = [];
      let paramIdx = 1;

      for (const [key, value] of Object.entries(fields)) {
        setClauses.push(`${key} = $${paramIdx}`);
        values.push(value);
        paramIdx++;
      }

      values.push(req.params.id);

      const rows = await query<Profile>(
        `UPDATE profiles SET ${setClauses.join(', ')} WHERE id = $${paramIdx} RETURNING *`,
        values
      );

      sendData(res, rows[0]);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// DELETE /api/v1/profiles/:id — Soft-delete (deactivate) profile
// ============================================================
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await query(
      `UPDATE profiles SET is_active = FALSE WHERE id = $1 AND user_id = $2 AND relation != 'self' RETURNING id`,
      [req.params.id, req.user!.sub]
    );

    if (result.length === 0) {
      throw ApiError.badRequest('Cannot delete self profile or profile not found');
    }

    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
