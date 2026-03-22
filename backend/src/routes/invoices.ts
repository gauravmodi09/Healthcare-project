import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { validate } from '../middleware/validate';
import { authenticate } from '../middleware/auth';
import { sendData, sendPaginated, buildPaginationMeta, parsePagination } from '../utils/response';
import { ApiError } from '../utils/errors';
import invoiceService from '../services/invoiceService';

const router = Router();

// ============================================================
// POST /api/v1/invoices/generate — Generate invoice for consultation
// ============================================================
const generateSchema = z.object({
  body: z.object({
    consultationId: z.string().min(1),
    amount: z.number().positive(),
    patient: z.object({
      id: z.string().min(1),
      name: z.string().min(1),
      phone: z.string().min(1),
      email: z.string().email().optional(),
      address: z.string().optional(),
    }),
    doctor: z.object({
      id: z.string().min(1),
      name: z.string().min(1),
      specialty: z.string().min(1),
      registrationNo: z.string().optional(),
    }),
    hospital: z.object({
      name: z.string().optional(),
      address: z.string().optional(),
      phone: z.string().optional(),
      email: z.string().optional(),
      gstin: z.string().optional(),
    }).optional(),
    notes: z.string().optional(),
  }),
});

router.post(
  '/generate',
  authenticate,
  validate(generateSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { consultationId, amount, patient, doctor, hospital, notes } = req.body;

      const invoice = invoiceService.generateInvoice(
        consultationId,
        amount,
        patient,
        doctor,
        hospital,
        notes,
      );

      sendData(res, invoice, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/invoices/:id — Get invoice details
// ============================================================
router.get(
  '/:id',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const invoice = invoiceService.getInvoiceById(req.params.id);
      if (!invoice) {
        throw ApiError.notFound('Invoice');
      }
      sendData(res, invoice);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/invoices — List invoices with filters
// ============================================================
router.get(
  '/',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { page, perPage } = parsePagination(req.query);
      const { doctorId, patientId, startDate, endDate, status } = req.query as Record<string, string | undefined>;

      const { invoices, total } = invoiceService.listInvoices({
        doctorId,
        patientId,
        startDate,
        endDate,
        status,
        page,
        perPage,
      });

      const meta = buildPaginationMeta(total, page, perPage);
      sendPaginated(res, invoices, meta);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/invoices/:id/pdf — Generate PDF (placeholder)
// ============================================================
router.get(
  '/:id/pdf',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const invoice = invoiceService.getInvoiceById(req.params.id);
      if (!invoice) {
        throw ApiError.notFound('Invoice');
      }

      // TODO: Integrate a PDF library (e.g. pdfkit, puppeteer) to generate actual PDF
      // For now, return a JSON representation with a note
      sendData(res, {
        message: 'PDF generation placeholder — integrate pdfkit or puppeteer for production',
        invoice,
        contentType: 'application/pdf',
      });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
