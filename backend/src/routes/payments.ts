import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { validate } from '../middleware/validate';
import { authenticate } from '../middleware/auth';
import { sendData } from '../utils/response';
import { ApiError } from '../utils/errors';
import razorpayService from '../services/razorpay';

const router = Router();

// ============================================================
// POST /api/v1/payments/create-order — Create a Razorpay order
// ============================================================
const createOrderSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
    currency: z.string().default('INR'),
    description: z.string().optional(),
  }),
});

router.post(
  '/create-order',
  authenticate,
  validate(createOrderSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { amount, currency } = req.body;
      const order = await razorpayService.createOrder(amount, currency);
      sendData(res, order, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/payments/verify — Verify payment signature
// ============================================================
const verifySchema = z.object({
  body: z.object({
    orderId: z.string().min(1),
    paymentId: z.string().min(1),
    signature: z.string().min(1),
  }),
});

router.post(
  '/verify',
  authenticate,
  validate(verifySchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { orderId, paymentId, signature } = req.body;

      const isValid = razorpayService.verifyPaymentSignature(orderId, paymentId, signature);
      if (!isValid) {
        throw ApiError.unauthorized('Invalid payment signature');
      }

      // TODO: update payment record in database as verified
      // await query('UPDATE payments SET status = $1 WHERE order_id = $2', ['captured', orderId]);

      sendData(res, {
        verified: true,
        orderId,
        paymentId,
      });
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/payments/subscribe — Create a subscription
// ============================================================
const subscribeSchema = z.object({
  body: z.object({
    planId: z.string().min(1),
    customerId: z.string().optional(),
  }),
});

router.post(
  '/subscribe',
  authenticate,
  validate(subscribeSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { planId, customerId } = req.body;
      const subscription = await razorpayService.createSubscription(planId, customerId);
      sendData(res, subscription, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/payments/qr-code — Generate UPI QR for in-clinic
// ============================================================
const qrCodeSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
    description: z.string().min(1),
  }),
});

router.post(
  '/qr-code',
  authenticate,
  validate(qrCodeSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { amount, description } = req.body;
      const qr = await razorpayService.generateQRCode(amount, description);
      sendData(res, qr, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/payments/history — Get payment history
// ============================================================
router.get(
  '/history',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      // TODO: fetch from database using req.user!.sub
      // const payments = await query(
      //   'SELECT * FROM payments WHERE user_id = $1 ORDER BY created_at DESC',
      //   [req.user!.sub]
      // );

      // Placeholder until database table is created
      sendData(res, {
        payments: [],
        total: 0,
      });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
