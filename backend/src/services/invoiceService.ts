// ============================================================
// GST Invoice Service
// Generates GST-compliant invoices for medical consultations
// ============================================================

export interface PatientInfo {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address?: string;
}

export interface DoctorInfo {
  id: string;
  name: string;
  specialty: string;
  registrationNo?: string;
}

export interface HospitalInfo {
  name: string;
  address: string;
  phone: string;
  email: string;
  gstin: string;
  facilityId?: string;
}

export interface InvoiceLineItem {
  description: string;
  sacCode: string;
  quantity: number;
  rate: number;
  amount: number;
}

export interface TaxBreakdown {
  taxableAmount: number;
  cgstRate: number;
  cgstAmount: number;
  sgstRate: number;
  sgstAmount: number;
  totalTax: number;
  totalWithTax: number;
}

export interface Invoice {
  id: string;
  invoiceNumber: string;
  consultationId: string;
  date: string;
  dueDate: string;
  hospital: HospitalInfo;
  patient: PatientInfo;
  doctor: DoctorInfo;
  lineItems: InvoiceLineItem[];
  taxBreakdown: TaxBreakdown;
  subtotal: number;
  total: number;
  status: 'draft' | 'issued' | 'paid' | 'cancelled';
  paymentMode?: 'upi' | 'cash' | 'insurance' | 'card';
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

// In-memory store (replace with database in production)
let invoiceCounter = 42;
const invoiceStore: Map<string, Invoice> = new Map();

// Default hospital info
const defaultHospital: HospitalInfo = {
  name: 'Shree Sai Multi-Specialty Hospital',
  address: 'MG Road, Pune, Maharashtra 411001',
  phone: '+91 20 2612 3456',
  email: 'admin@shreesaihospital.in',
  gstin: '27AABCS1234D1ZE',
  facilityId: 'IN2760012345',
};

/**
 * Generate a sequential invoice number: INV-YYYY-NNNN
 */
function nextInvoiceNumber(): string {
  invoiceCounter += 1;
  const year = new Date().getFullYear();
  return `INV-${year}-${String(invoiceCounter).padStart(4, '0')}`;
}

/**
 * Calculate GST breakdown for medical consultation
 * SAC Code 9983: Other professional, technical and business services
 * GST Rate: 18% (9% CGST + 9% SGST for intra-state)
 */
function calculateGST(amount: number): TaxBreakdown {
  const cgstRate = 9;
  const sgstRate = 9;
  const taxableAmount = amount;
  const cgstAmount = Math.round((taxableAmount * cgstRate) / 100);
  const sgstAmount = Math.round((taxableAmount * sgstRate) / 100);
  const totalTax = cgstAmount + sgstAmount;

  return {
    taxableAmount,
    cgstRate,
    cgstAmount,
    sgstRate,
    sgstAmount,
    totalTax,
    totalWithTax: taxableAmount + totalTax,
  };
}

/**
 * Generate a GST-compliant invoice for a consultation
 */
export function generateInvoice(
  consultationId: string,
  amount: number,
  patientInfo: PatientInfo,
  doctorInfo: DoctorInfo,
  hospitalInfo?: Partial<HospitalInfo>,
  notes?: string,
): Invoice {
  const hospital = { ...defaultHospital, ...hospitalInfo };
  const now = new Date();
  const invoiceNumber = nextInvoiceNumber();
  const id = `inv_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  const lineItems: InvoiceLineItem[] = [
    {
      description: `Medical Consultation - ${doctorInfo.specialty}`,
      sacCode: '9983',
      quantity: 1,
      rate: amount,
      amount,
    },
  ];

  const taxBreakdown = calculateGST(amount);

  const invoice: Invoice = {
    id,
    invoiceNumber,
    consultationId,
    date: now.toISOString().split('T')[0],
    dueDate: now.toISOString().split('T')[0], // Due on issue for consultations
    hospital,
    patient: patientInfo,
    doctor: doctorInfo,
    lineItems,
    taxBreakdown,
    subtotal: amount,
    total: taxBreakdown.totalWithTax,
    status: 'issued',
    notes,
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  };

  invoiceStore.set(id, invoice);
  return invoice;
}

/**
 * Get an invoice by ID
 */
export function getInvoiceById(id: string): Invoice | undefined {
  return invoiceStore.get(id);
}

/**
 * List invoices with optional filters
 */
export function listInvoices(filters?: {
  doctorId?: string;
  patientId?: string;
  startDate?: string;
  endDate?: string;
  status?: string;
  page?: number;
  perPage?: number;
}): { invoices: Invoice[]; total: number } {
  let results = Array.from(invoiceStore.values());

  if (filters?.doctorId) {
    results = results.filter((inv) => inv.doctor.id === filters.doctorId);
  }
  if (filters?.patientId) {
    results = results.filter((inv) => inv.patient.id === filters.patientId);
  }
  if (filters?.startDate) {
    results = results.filter((inv) => inv.date >= filters.startDate!);
  }
  if (filters?.endDate) {
    results = results.filter((inv) => inv.date <= filters.endDate!);
  }
  if (filters?.status) {
    results = results.filter((inv) => inv.status === filters.status);
  }

  // Sort by date descending
  results.sort((a, b) => b.createdAt.localeCompare(a.createdAt));

  const total = results.length;
  const page = filters?.page ?? 1;
  const perPage = filters?.perPage ?? 20;
  const offset = (page - 1) * perPage;
  const paginated = results.slice(offset, offset + perPage);

  return { invoices: paginated, total };
}

export default {
  generateInvoice,
  getInvoiceById,
  listInvoices,
};
