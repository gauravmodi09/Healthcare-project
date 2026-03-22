import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { sendData } from '../utils/response';
import { ApiError } from '../utils/errors';
import {
  saveDeviceToken,
  removeDeviceToken,
  removeAllUserTokens,
  getNotificationPreferences,
  updateNotificationPreferences,
} from '../services/pushNotification';

const router = Router();
router.use(authenticate);

// ============================================================
// POST /api/v1/notifications/register-token — Save device token
// ============================================================
const registerTokenSchema = z.object({
  body: z.object({
    device_token: z.string().min(1).max(512),
    platform: z.enum(['ios', 'android']).default('ios'),
  }),
});

router.post(
  '/register-token',
  validate(registerTokenSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { device_token, platform } = req.body;
      await saveDeviceToken(req.user!.sub, device_token, platform);
      sendData(res, { registered: true }, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// DELETE /api/v1/notifications/unregister — Remove device token
// ============================================================
const unregisterSchema = z.object({
  body: z.object({
    device_token: z.string().min(1).max(512).optional(),
    all: z.boolean().optional(),
  }),
});

router.delete(
  '/unregister',
  validate(unregisterSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { device_token, all } = req.body;

      if (all) {
        await removeAllUserTokens(req.user!.sub);
      } else if (device_token) {
        await removeDeviceToken(device_token);
      } else {
        throw ApiError.badRequest('Provide device_token or set all=true');
      }

      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/notifications/preferences — Get preferences
// ============================================================
router.get(
  '/preferences',
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const prefs = await getNotificationPreferences(req.user!.sub);
      sendData(res, prefs);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// PUT /api/v1/notifications/preferences — Update preferences
// ============================================================
const updatePrefsSchema = z.object({
  body: z.object({
    dose_reminders: z.boolean().optional(),
    missed_dose_alerts: z.boolean().optional(),
    messages: z.boolean().optional(),
    appointments: z.boolean().optional(),
    vital_alerts: z.boolean().optional(),
    queue_updates: z.boolean().optional(),
    marketing: z.boolean().optional(),
  }),
});

router.put(
  '/preferences',
  validate(updatePrefsSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await updateNotificationPreferences(req.user!.sub, req.body);
      sendData(res, updated);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
