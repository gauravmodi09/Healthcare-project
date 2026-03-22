import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { query, queryOne, transaction } from '../config/db';
import { validate } from '../middleware/validate';
import { authenticate } from '../middleware/auth';
import { sendData } from '../utils/response';
import { ApiError } from '../utils/errors';

const router = Router();

// All referral routes require authentication
router.use(authenticate);

// ============================================================
// POST /api/v1/referrals/generate-code
// Generate a unique referral code for the authenticated user
// ============================================================
router.post(
  '/generate-code',
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user!.sub;

      // Check if user already has a referral code
      const existing = await queryOne<{ referral_code: string }>(
        'SELECT referral_code FROM referral_codes WHERE user_id = $1',
        [userId]
      );

      if (existing) {
        return sendData(res, { code: existing.referral_code });
      }

      // Fetch user name for personalized code
      const user = await queryOne<{ full_name: string }>(
        'SELECT full_name FROM users WHERE id = $1',
        [userId]
      );

      const namePart = (user?.full_name || 'USER')
        .replace(/[^A-Za-z]/g, '')
        .toUpperCase()
        .substring(0, 6);
      const yearPart = new Date().getFullYear();
      const code = `${namePart}${yearPart}`;

      // Ensure uniqueness — append random suffix if collision
      const collision = await queryOne(
        'SELECT 1 FROM referral_codes WHERE referral_code = $1',
        [code]
      );

      const finalCode = collision
        ? `${code}${Math.floor(Math.random() * 99)}`
        : code;

      await query(
        `INSERT INTO referral_codes (id, user_id, referral_code, created_at)
         VALUES ($1, $2, $3, NOW())`,
        [uuid(), userId, finalCode]
      );

      return sendData(res, { code: finalCode }, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/referrals/redeem
// Redeem a referral code — rewards both referrer and redeemer
// ============================================================
const redeemSchema = z.object({
  body: z.object({
    code: z.string().min(3).max(20),
  }),
});

router.post(
  '/redeem',
  validate(redeemSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user!.sub;
      const { code } = req.body;

      // Find the referral code
      const referral = await queryOne<{ user_id: string; referral_code: string }>(
        'SELECT user_id, referral_code FROM referral_codes WHERE referral_code = $1',
        [code]
      );

      if (!referral) {
        return next(ApiError.notFound('Referral code'));
      }

      // Cannot redeem own code
      if (referral.user_id === userId) {
        return next(ApiError.badRequest('Cannot redeem your own referral code'));
      }

      // Check if already redeemed by this user
      const alreadyRedeemed = await queryOne(
        'SELECT 1 FROM referral_redemptions WHERE redeemer_id = $1',
        [userId]
      );

      if (alreadyRedeemed) {
        return next(ApiError.conflict('You have already redeemed a referral code'));
      }

      // Process redemption in a transaction
      await transaction(async (client) => {
        // Record redemption
        await client.query(
          `INSERT INTO referral_redemptions (id, referral_code, referrer_id, redeemer_id, created_at)
           VALUES ($1, $2, $3, $4, NOW())`,
          [uuid(), code, referral.user_id, userId]
        );

        // Grant 1 month Pro to referrer
        await client.query(
          `INSERT INTO subscription_rewards (id, user_id, type, months, source, created_at)
           VALUES ($1, $2, 'pro_extension', 1, 'referral', NOW())`,
          [uuid(), referral.user_id]
        );

        // Grant 1 month Pro to redeemer
        await client.query(
          `INSERT INTO subscription_rewards (id, user_id, type, months, source, created_at)
           VALUES ($1, $2, 'pro_extension', 1, 'referral', NOW())`,
          [uuid(), userId]
        );
      });

      return sendData(res, {
        message: 'Referral redeemed! You and the referrer each get 1 month of Pro free.',
        reward_months: 1,
      });
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/referrals/stats
// Get referral statistics for the authenticated user
// ============================================================
router.get(
  '/stats',
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.user!.sub;

      // Get user's referral code
      const referral = await queryOne<{ referral_code: string }>(
        'SELECT referral_code FROM referral_codes WHERE user_id = $1',
        [userId]
      );

      if (!referral) {
        return sendData(res, {
          code: null,
          invites_sent: 0,
          friends_joined: 0,
          rewards_earned: 0,
        });
      }

      // Count redemptions (friends who joined)
      const stats = await queryOne<{ friends_joined: string }>(
        'SELECT COUNT(*)::int AS friends_joined FROM referral_redemptions WHERE referrer_id = $1',
        [userId]
      );

      // Count reward months earned
      const rewards = await queryOne<{ total_months: string }>(
        `SELECT COALESCE(SUM(months), 0)::int AS total_months
         FROM subscription_rewards
         WHERE user_id = $1 AND source = 'referral'`,
        [userId]
      );

      return sendData(res, {
        code: referral.referral_code,
        invites_sent: 0, // TODO: Track share events from client
        friends_joined: parseInt(stats?.friends_joined || '0'),
        rewards_earned: parseInt(rewards?.total_months || '0'),
      });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
