-- MedCare Initial Schema
-- Follows postgres-patterns: timestamptz, text over varchar, proper indexing

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- USERS (patients who authenticate via phone OTP)
-- ============================================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(15) UNIQUE NOT NULL,
  phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users (phone);

-- ============================================================
-- HOSPITALS
-- ============================================================
CREATE TYPE hospital_type AS ENUM ('hospital', 'clinic', 'polyclinic');

CREATE TABLE hospitals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  state TEXT,
  type hospital_type NOT NULL DEFAULT 'clinic',
  specialties TEXT[] DEFAULT '{}',
  admin_doctor_id UUID,  -- FK added after doctors table
  abdm_facility_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hospitals_city ON hospitals (city);

-- ============================================================
-- DOCTORS
-- ============================================================
CREATE TABLE doctors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  specialty TEXT,
  registration_number TEXT,
  qualification TEXT,
  phone VARCHAR(15),
  profile_photo_url TEXT,
  consultation_fee_inr NUMERIC(10,2),
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  hospital_id UUID REFERENCES hospitals(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_doctors_email ON doctors (email);
CREATE INDEX idx_doctors_hospital ON doctors (hospital_id);
CREATE INDEX idx_doctors_specialty ON doctors (specialty);

-- Now add the FK from hospitals to doctors
ALTER TABLE hospitals
  ADD CONSTRAINT fk_hospitals_admin_doctor
  FOREIGN KEY (admin_doctor_id) REFERENCES doctors(id) ON DELETE SET NULL;

-- ============================================================
-- PROFILES (family members of a user/patient)
-- ============================================================
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE relation_type AS ENUM ('self', 'spouse', 'child', 'parent', 'sibling', 'other');

CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  date_of_birth DATE,
  gender gender_type,
  blood_group TEXT,
  avatar_emoji TEXT DEFAULT '🩺',
  relation relation_type NOT NULL DEFAULT 'self',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  known_conditions TEXT[] DEFAULT '{}',
  allergies TEXT[] DEFAULT '{}',
  caregiver_name TEXT,
  caregiver_phone VARCHAR(15),
  abha_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_user ON profiles (user_id);
CREATE INDEX idx_profiles_active ON profiles (user_id) WHERE is_active = TRUE;

-- ============================================================
-- PATIENT-DOCTOR LINKS
-- ============================================================
CREATE TYPE link_status AS ENUM ('pending', 'active', 'inactive');

CREATE TABLE patient_doctor_links (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  status link_status NOT NULL DEFAULT 'pending',
  linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  invite_code TEXT,
  UNIQUE(profile_id, doctor_id)
);

CREATE INDEX idx_pdl_profile ON patient_doctor_links (profile_id);
CREATE INDEX idx_pdl_doctor ON patient_doctor_links (doctor_id);
CREATE INDEX idx_pdl_invite ON patient_doctor_links (invite_code) WHERE invite_code IS NOT NULL;

-- ============================================================
-- EPISODES
-- ============================================================
CREATE TYPE episode_status AS ENUM ('active', 'resolved', 'ongoing');

CREATE TABLE episodes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  type TEXT,
  diagnosis TEXT,
  doctor_name TEXT,
  status episode_status NOT NULL DEFAULT 'active',
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_episodes_profile ON episodes (profile_id);
CREATE INDEX idx_episodes_doctor ON episodes (doctor_id);
CREATE INDEX idx_episodes_status ON episodes (profile_id, status);

-- ============================================================
-- MEDICINES
-- ============================================================
CREATE TYPE dose_form_type AS ENUM ('tablet', 'capsule', 'syrup', 'injection', 'drops', 'cream', 'inhaler', 'patch', 'other');
CREATE TYPE meal_timing_type AS ENUM ('before_meal', 'after_meal', 'with_meal', 'empty_stomach', 'any');

CREATE TABLE medicines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  episode_id UUID NOT NULL REFERENCES episodes(id) ON DELETE CASCADE,
  brand_name TEXT NOT NULL,
  generic_name TEXT,
  dosage TEXT,
  dose_form dose_form_type DEFAULT 'tablet',
  frequency TEXT,
  timing JSONB DEFAULT '[]',
  duration_days INTEGER,
  meal_timing meal_timing_type DEFAULT 'after_meal',
  instructions TEXT,
  manufacturer TEXT,
  mrp NUMERIC(10,2),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_critical BOOLEAN NOT NULL DEFAULT FALSE,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_medicines_episode ON medicines (episode_id);
CREATE INDEX idx_medicines_active ON medicines (episode_id) WHERE is_active = TRUE;

-- ============================================================
-- DOSE LOGS
-- ============================================================
CREATE TYPE dose_status AS ENUM ('pending', 'taken', 'missed', 'skipped', 'snoozed');

CREATE TABLE dose_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
  scheduled_time TIMESTAMPTZ NOT NULL,
  actual_time TIMESTAMPTZ,
  status dose_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dose_logs_medicine ON dose_logs (medicine_id);
CREATE INDEX idx_dose_logs_schedule ON dose_logs (medicine_id, scheduled_time);
CREATE INDEX idx_dose_logs_pending ON dose_logs (medicine_id, status) WHERE status = 'pending';

-- ============================================================
-- VITALS
-- ============================================================
CREATE TYPE vital_type AS ENUM ('bp', 'hr', 'spo2', 'weight', 'temp', 'glucose');
CREATE TYPE vital_source AS ENUM ('manual', 'healthkit', 'wearable');

CREATE TABLE vitals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type vital_type NOT NULL,
  value JSONB NOT NULL,
  source vital_source NOT NULL DEFAULT 'manual',
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vitals_profile ON vitals (profile_id);
CREATE INDEX idx_vitals_type ON vitals (profile_id, type);
CREATE INDEX idx_vitals_recorded ON vitals (profile_id, recorded_at DESC);

-- ============================================================
-- SYMPTOM LOGS
-- ============================================================
CREATE TABLE symptom_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  episode_id UUID REFERENCES episodes(id) ON DELETE SET NULL,
  overall_feeling TEXT,
  symptoms JSONB DEFAULT '[]',
  notes TEXT,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_symptom_logs_profile ON symptom_logs (profile_id);

-- ============================================================
-- LAB RESULTS
-- ============================================================
CREATE TABLE lab_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  test_name TEXT NOT NULL,
  body_system TEXT,
  value DECIMAL,
  unit TEXT,
  normal_range_low DECIMAL,
  normal_range_high DECIMAL,
  is_abnormal BOOLEAN NOT NULL DEFAULT FALSE,
  test_date DATE NOT NULL DEFAULT CURRENT_DATE,
  source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lab_results_profile ON lab_results (profile_id);
CREATE INDEX idx_lab_results_date ON lab_results (profile_id, test_date DESC);

-- ============================================================
-- MESSAGES
-- ============================================================
CREATE TYPE sender_type AS ENUM ('patient', 'doctor');
CREATE TYPE message_type AS ENUM ('text', 'image', 'document', 'voice');

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_type sender_type NOT NULL,
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  thread_id UUID NOT NULL DEFAULT uuid_generate_v4(),
  content TEXT,
  message_type message_type NOT NULL DEFAULT 'text',
  attachment_url TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  is_urgent BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_thread ON messages (thread_id, created_at);
CREATE INDEX idx_messages_receiver ON messages (receiver_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_messages_sender ON messages (sender_id, created_at DESC);

-- ============================================================
-- APPOINTMENTS
-- ============================================================
CREATE TYPE appointment_type AS ENUM ('in_person', 'video', 'audio');
CREATE TYPE appointment_status AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show');

CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  type appointment_type NOT NULL DEFAULT 'in_person',
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 30,
  status appointment_status NOT NULL DEFAULT 'scheduled',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_appointments_profile ON appointments (profile_id);
CREATE INDEX idx_appointments_doctor ON appointments (doctor_id);
CREATE INDEX idx_appointments_schedule ON appointments (doctor_id, scheduled_at);
CREATE INDEX idx_appointments_upcoming ON appointments (profile_id, status, scheduled_at)
  WHERE status = 'scheduled';

-- ============================================================
-- PRESCRIPTIONS
-- ============================================================
CREATE TABLE prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  episode_id UUID REFERENCES episodes(id) ON DELETE SET NULL,
  medicines JSONB NOT NULL DEFAULT '[]',
  diagnosis TEXT,
  notes TEXT,
  digital_signature TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_prescriptions_doctor ON prescriptions (doctor_id);
CREATE INDEX idx_prescriptions_profile ON prescriptions (profile_id);

-- ============================================================
-- DOCUMENTS
-- ============================================================
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  episode_id UUID REFERENCES episodes(id) ON DELETE SET NULL,
  category TEXT,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT,
  notes TEXT,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documents_profile ON documents (profile_id);

-- ============================================================
-- CUSTOM REMINDERS
-- ============================================================
CREATE TYPE repeat_option AS ENUM ('none', 'daily', 'weekly', 'monthly');

CREATE TABLE custom_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  notes TEXT,
  reminder_time TIMESTAMPTZ NOT NULL,
  repeat_option repeat_option NOT NULL DEFAULT 'none',
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reminders_profile ON custom_reminders (profile_id);
CREATE INDEX idx_reminders_pending ON custom_reminders (profile_id, reminder_time)
  WHERE is_completed = FALSE;

-- ============================================================
-- ACHIEVEMENTS
-- ============================================================
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_type TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(profile_id, achievement_type)
);

CREATE INDEX idx_achievements_profile ON achievements (profile_id);

-- ============================================================
-- NOTIFICATION TOKENS
-- ============================================================
CREATE TYPE platform_type AS ENUM ('ios', 'android');

CREATE TABLE notification_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_token TEXT NOT NULL,
  platform platform_type NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, device_token)
);

CREATE INDEX idx_notif_tokens_user ON notification_tokens (user_id);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
