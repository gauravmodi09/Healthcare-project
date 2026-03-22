// ============================================================
// Domain Types — mirror the PostgreSQL schema
// ============================================================

export interface User {
  id: string;
  phone: string;
  phone_verified: boolean;
  created_at: string;
  updated_at: string;
}

export type Gender = 'male' | 'female' | 'other';
export type Relation = 'self' | 'spouse' | 'child' | 'parent' | 'sibling' | 'other';

export interface Profile {
  id: string;
  user_id: string;
  name: string;
  date_of_birth: string | null;
  gender: Gender | null;
  blood_group: string | null;
  avatar_emoji: string;
  relation: Relation;
  is_active: boolean;
  known_conditions: string[];
  allergies: string[];
  caregiver_name: string | null;
  caregiver_phone: string | null;
  abha_id: string | null;
  created_at: string;
}

export interface Doctor {
  id: string;
  email: string;
  password_hash: string;
  name: string;
  specialty: string | null;
  registration_number: string | null;
  qualification: string | null;
  phone: string | null;
  profile_photo_url: string | null;
  consultation_fee_inr: number | null;
  is_verified: boolean;
  hospital_id: string | null;
  created_at: string;
}

export type HospitalType = 'hospital' | 'clinic' | 'polyclinic';

export interface Hospital {
  id: string;
  name: string;
  address: string | null;
  city: string | null;
  state: string | null;
  type: HospitalType;
  specialties: string[];
  admin_doctor_id: string | null;
  abdm_facility_id: string | null;
  created_at: string;
}

export type LinkStatus = 'pending' | 'active' | 'inactive';

export interface PatientDoctorLink {
  id: string;
  profile_id: string;
  doctor_id: string;
  status: LinkStatus;
  linked_at: string;
  invite_code: string | null;
}

export type EpisodeStatus = 'active' | 'resolved' | 'ongoing';

export interface Episode {
  id: string;
  profile_id: string;
  doctor_id: string | null;
  title: string;
  type: string | null;
  diagnosis: string | null;
  doctor_name: string | null;
  status: EpisodeStatus;
  start_date: string;
  end_date: string | null;
  created_at: string;
}

export type DoseForm = 'tablet' | 'capsule' | 'syrup' | 'injection' | 'drops' | 'cream' | 'inhaler' | 'patch' | 'other';
export type MealTiming = 'before_meal' | 'after_meal' | 'with_meal' | 'empty_stomach' | 'any';

export interface Medicine {
  id: string;
  episode_id: string;
  brand_name: string;
  generic_name: string | null;
  dosage: string | null;
  dose_form: DoseForm;
  frequency: string | null;
  timing: any;
  duration_days: number | null;
  meal_timing: MealTiming;
  instructions: string | null;
  manufacturer: string | null;
  mrp: number | null;
  is_active: boolean;
  is_critical: boolean;
  start_date: string;
  created_at: string;
}

export type DoseStatus = 'pending' | 'taken' | 'missed' | 'skipped' | 'snoozed';

export interface DoseLog {
  id: string;
  medicine_id: string;
  scheduled_time: string;
  actual_time: string | null;
  status: DoseStatus;
  created_at: string;
}

export type VitalType = 'bp' | 'hr' | 'spo2' | 'weight' | 'temp' | 'glucose';
export type VitalSource = 'manual' | 'healthkit' | 'wearable';

export interface Vital {
  id: string;
  profile_id: string;
  type: VitalType;
  value: any;
  source: VitalSource;
  recorded_at: string;
  created_at: string;
}

export type SenderType = 'patient' | 'doctor';
export type MessageType = 'text' | 'image' | 'document' | 'voice';

export interface Message {
  id: string;
  sender_type: SenderType;
  sender_id: string;
  receiver_id: string;
  thread_id: string;
  content: string | null;
  message_type: MessageType;
  attachment_url: string | null;
  is_read: boolean;
  is_urgent: boolean;
  created_at: string;
}

export type AppointmentType = 'in_person' | 'video' | 'audio';
export type AppointmentStatus = 'scheduled' | 'completed' | 'cancelled' | 'no_show';

export interface Appointment {
  id: string;
  profile_id: string;
  doctor_id: string;
  type: AppointmentType;
  scheduled_at: string;
  duration_minutes: number;
  status: AppointmentStatus;
  notes: string | null;
  created_at: string;
}

export interface Prescription {
  id: string;
  doctor_id: string;
  profile_id: string;
  episode_id: string | null;
  medicines: any;
  diagnosis: string | null;
  notes: string | null;
  digital_signature: string | null;
  created_at: string;
}

// ============================================================
// Auth types
// ============================================================

export type UserRole = 'patient' | 'doctor';

export interface JwtPayload {
  sub: string;        // user or doctor id
  role: UserRole;
  iat?: number;
  exp?: number;
}

// ============================================================
// API envelope (follows api-design skill)
// ============================================================

export interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;
}

export interface PaginationMeta {
  total: number;
  page: number;
  per_page: number;
  total_pages: number;
}

export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Array<{
      field: string;
      message: string;
      code: string;
    }>;
  };
}

// ============================================================
// Express augmentation
// ============================================================

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}
