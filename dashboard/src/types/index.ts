export interface Hospital {
  id: string;
  name: string;
  address: string;
  phone: string;
  email: string;
  logo?: string;
  adminName: string;
  adminAvatar?: string;
  createdAt: string;
}

export interface Doctor {
  id: string;
  name: string;
  specialty: string;
  phone: string;
  email: string;
  photo?: string;
  hospitalId: string;
  patientsCount: number;
  rating: number;
  availableDays: string[];
  appointmentsToday: number;
  status: "active" | "on-leave" | "inactive";
  joinedAt: string;
}

export interface Patient {
  id: string;
  name: string;
  age: number;
  gender: "male" | "female" | "other";
  phone: string;
  email?: string;
  doctorId: string;
  doctorName: string;
  condition: string;
  medicines: string[];
  lastVisit: string;
  nextVisit?: string;
  adherencePercent: number;
  status: "active" | "inactive" | "critical" | "recovered";
  createdAt: string;
}

export interface Appointment {
  id: string;
  patientId: string;
  patientName: string;
  doctorId: string;
  doctorName: string;
  date: string;
  time: string;
  type: "scheduled" | "walk-in" | "follow-up" | "emergency";
  status: "waiting" | "in-progress" | "completed" | "cancelled" | "no-show";
  notes?: string;
}

export interface RevenueData {
  month: string;
  revenue: number;
  patients: number;
}

export interface DashboardStats {
  totalPatients: number;
  activeDoctors: number;
  todayAppointments: number;
  monthlyRevenue: number;
  revenueChange: number;
  patientChange: number;
}

export interface DemographicData {
  ageGroup: string;
  count: number;
  percentage: number;
}

export interface ConditionData {
  condition: string;
  count: number;
  percentage: number;
}
