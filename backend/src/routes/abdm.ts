import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { validate } from '../middleware/validate';
import { authenticate } from '../middleware/auth';
import { sendData } from '../utils/response';
import { ApiError } from '../utils/errors';
import abdmService from '../services/abdm';

const router = Router();

// ============================================================
// POST /api/v1/abdm/create-abha — Start ABHA creation via Aadhaar
// ============================================================
const createABHASchema = z.object({
  body: z.object({
    aadhaarNumber: z.string().length(12).regex(/^\d{12}$/, 'Must be 12-digit Aadhaar'),
    method: z.enum(['aadhaar', 'mobile']).default('aadhaar'),
    mobile: z.string().min(10).max(10).optional(),
  }),
});

router.post(
  '/create-abha',
  authenticate,
  validate(createABHASchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { aadhaarNumber, method, mobile } = req.body;

      let result;
      if (method === 'mobile' && mobile) {
        result = await abdmService.createABHAViaMobile(mobile);
      } else {
        result = await abdmService.createABHAViaAadhaar(aadhaarNumber);
      }

      sendData(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/abdm/verify-otp — Verify OTP and complete ABHA creation
// ============================================================
const verifyOTPSchema = z.object({
  body: z.object({
    txnId: z.string().min(1),
    otp: z.string().length(6),
  }),
});

router.post(
  '/verify-otp',
  authenticate,
  validate(verifyOTPSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { txnId, otp } = req.body;
      const result = await abdmService.verifyAadhaarOTP(txnId, otp);
      sendData(res, result, 201);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// GET /api/v1/abdm/profile/:abhaId — Get ABHA profile
// ============================================================
router.get(
  '/profile/:abhaId',
  authenticate,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { abhaId } = req.params;
      if (!abhaId) throw ApiError.badRequest('ABHA ID is required');

      const profile = await abdmService.verifyABHA(abhaId);
      sendData(res, profile);
    } catch (err) {
      next(err);
    }
  }
);

// ============================================================
// POST /api/v1/abdm/share-record — Share health record as FHIR bundle
// ============================================================
const shareRecordSchema = z.object({
  body: z.object({
    recordType: z.enum(['prescription', 'diagnostic', 'wellness']),
    patientName: z.string().min(1),
    patientAbhaId: z.string().min(1),
    // Prescription fields
    doctorName: z.string().optional(),
    medications: z
      .array(
        z.object({
          name: z.string(),
          dosage: z.string(),
          frequency: z.string(),
          duration: z.string(),
        })
      )
      .optional(),
    // Diagnostic fields
    reportName: z.string().optional(),
    observations: z
      .array(
        z.object({
          name: z.string(),
          value: z.number(),
          unit: z.string(),
          referenceRange: z.string().optional(),
        })
      )
      .optional(),
    // Wellness fields
    vitals: z
      .array(
        z.object({
          type: z.string(),
          value: z.number(),
          unit: z.string(),
        })
      )
      .optional(),
  }),
});

router.post(
  '/share-record',
  authenticate,
  validate(shareRecordSchema),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { recordType, patientName, patientAbhaId } = req.body;
      let bundle;

      switch (recordType) {
        case 'prescription': {
          const { doctorName, medications } = req.body;
          if (!doctorName || !medications?.length) {
            throw ApiError.badRequest('doctorName and medications are required for prescriptions');
          }
          bundle = abdmService.buildPrescriptionBundle({
            patientName,
            patientAbhaId,
            doctorName,
            medications,
          });
          break;
        }
        case 'diagnostic': {
          const { reportName, observations } = req.body;
          if (!reportName || !observations?.length) {
            throw ApiError.badRequest('reportName and observations are required for diagnostic reports');
          }
          bundle = abdmService.buildDiagnosticReportBundle({
            patientName,
            patientAbhaId,
            reportName,
            observations,
          });
          break;
        }
        case 'wellness': {
          const { vitals } = req.body;
          if (!vitals?.length) {
            throw ApiError.badRequest('vitals are required for wellness records');
          }
          bundle = abdmService.buildWellnessRecordBundle({
            patientName,
            patientAbhaId,
            vitals,
          });
          break;
        }
      }

      sendData(res, { bundle });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
