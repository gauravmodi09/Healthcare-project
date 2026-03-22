"use client";

import { useState } from "react";
import { doctors } from "@/lib/mock-data";
import { Doctor } from "@/types";

function DoctorStatusBadge({ status }: { status: string }) {
  const cls =
    status === "active"
      ? "badge-active"
      : status === "on-leave"
      ? "badge-waiting"
      : "badge-inactive";
  const label =
    status === "on-leave"
      ? "On Leave"
      : status.charAt(0).toUpperCase() + status.slice(1);
  return <span className={`badge ${cls}`}>{label}</span>;
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((star) => (
        <svg
          key={star}
          className={`w-4 h-4 ${star <= Math.round(rating) ? "text-amber-400" : "text-gray-200"}`}
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
        </svg>
      ))}
      <span className="text-sm text-gray-600 ml-1">{rating}</span>
    </div>
  );
}

function DoctorModal({
  doctor,
  onClose,
}: {
  doctor: Doctor;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-xl max-w-lg w-full mx-4 p-6 z-10">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <div className="flex items-center gap-4 mb-6">
          <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-bold text-xl">
            {doctor.name.split(" ").slice(1).map((n) => n[0]).join("")}
          </div>
          <div>
            <h2 className="text-xl font-bold text-gray-900">{doctor.name}</h2>
            <p className="text-primary-500 font-medium">{doctor.specialty}</p>
            <DoctorStatusBadge status={doctor.status} />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="bg-gray-50 rounded-lg p-3">
            <p className="text-xs text-gray-500">Patients</p>
            <p className="text-lg font-bold text-gray-900">{doctor.patientsCount}</p>
          </div>
          <div className="bg-gray-50 rounded-lg p-3">
            <p className="text-xs text-gray-500">Today&apos;s Appointments</p>
            <p className="text-lg font-bold text-gray-900">{doctor.appointmentsToday}</p>
          </div>
          <div className="bg-gray-50 rounded-lg p-3">
            <p className="text-xs text-gray-500">Rating</p>
            <StarRating rating={doctor.rating} />
          </div>
          <div className="bg-gray-50 rounded-lg p-3">
            <p className="text-xs text-gray-500">Joined</p>
            <p className="text-lg font-bold text-gray-900">{doctor.joinedAt}</p>
          </div>
        </div>

        <div className="mb-6">
          <h3 className="text-sm font-semibold text-gray-700 mb-2">Available Days</h3>
          <div className="flex gap-2">
            {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) => (
              <span
                key={day}
                className={`w-10 h-10 rounded-lg flex items-center justify-center text-xs font-medium ${
                  doctor.availableDays.includes(day)
                    ? "bg-primary-100 text-primary-600"
                    : "bg-gray-100 text-gray-400"
                }`}
              >
                {day}
              </span>
            ))}
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
            </svg>
            {doctor.phone}
          </div>
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            {doctor.email}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function DoctorsPage() {
  const [selectedDoctor, setSelectedDoctor] = useState<Doctor | null>(null);
  const [showInvite, setShowInvite] = useState(false);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Doctors</h1>
          <p className="text-gray-500 mt-1">{doctors.length} doctors on staff</p>
        </div>
        <button onClick={() => setShowInvite(!showInvite)} className="btn-primary">
          + Invite Doctor
        </button>
      </div>

      {/* Invite form */}
      {showInvite && (
        <div className="stat-card">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Invite a New Doctor</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <input type="text" placeholder="Doctor's full name" className="input" />
            <input type="email" placeholder="Email address" className="input" />
            <select className="input">
              <option value="">Select Specialty</option>
              <option>Cardiology</option>
              <option>Orthopedics</option>
              <option>Dermatology</option>
              <option>General Medicine</option>
              <option>Pediatrics</option>
              <option>ENT</option>
              <option>Gynecology</option>
              <option>Neurology</option>
            </select>
          </div>
          <div className="flex gap-3 mt-4">
            <button className="btn-primary">Send Invitation</button>
            <button onClick={() => setShowInvite(false)} className="btn-secondary">
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Doctor Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {doctors.map((doctor) => (
          <div
            key={doctor.id}
            onClick={() => setSelectedDoctor(doctor)}
            className="stat-card cursor-pointer hover:border-primary-200"
          >
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-bold text-lg">
                {doctor.name.split(" ").slice(1).map((n) => n[0]).join("")}
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-gray-900 truncate">{doctor.name}</h3>
                <p className="text-sm text-primary-500">{doctor.specialty}</p>
              </div>
            </div>

            <div className="flex items-center justify-between mb-3">
              <DoctorStatusBadge status={doctor.status} />
              <StarRating rating={doctor.rating} />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="bg-gray-50 rounded-lg p-2.5 text-center">
                <p className="text-lg font-bold text-gray-900">{doctor.patientsCount}</p>
                <p className="text-xs text-gray-500">Patients</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-2.5 text-center">
                <p className="text-lg font-bold text-gray-900">{doctor.appointmentsToday}</p>
                <p className="text-xs text-gray-500">Today</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Doctor Detail Modal */}
      {selectedDoctor && (
        <DoctorModal
          doctor={selectedDoctor}
          onClose={() => setSelectedDoctor(null)}
        />
      )}
    </div>
  );
}
