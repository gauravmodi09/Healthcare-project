"use client";

import { useState, useMemo } from "react";
import { todayAppointments, doctors } from "@/lib/mock-data";

function AppointmentTypeBadge({ type }: { type: string }) {
  const cls =
    type === "walk-in"
      ? "text-orange-700 bg-orange-100"
      : type === "emergency"
      ? "text-red-700 bg-red-100"
      : type === "follow-up"
      ? "text-blue-700 bg-blue-100"
      : type === "scheduled"
      ? "text-purple-700 bg-purple-100"
      : "text-gray-700 bg-gray-100";
  return (
    <span className={`badge ${cls}`}>
      {type
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ")}
    </span>
  );
}

function StatusBadge({ status }: { status: string }) {
  const cls =
    status === "completed"
      ? "text-green-700 bg-green-100"
      : status === "in-progress"
      ? "text-blue-700 bg-blue-100"
      : status === "waiting"
      ? "text-yellow-700 bg-yellow-100"
      : status === "no-show"
      ? "text-red-700 bg-red-100"
      : "text-gray-700 bg-gray-100";
  return (
    <span className={`badge ${cls}`}>
      {status
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ")}
    </span>
  );
}

export default function AppointmentsPage() {
  const [filterDoctor, setFilterDoctor] = useState("");
  const [filterStatus, setFilterStatus] = useState("");
  const [filterType, setFilterType] = useState("");
  const [appointments, setAppointments] = useState(todayAppointments);

  const filtered = useMemo(() => {
    return appointments.filter((a) => {
      const matchDoctor = !filterDoctor || a.doctorId === filterDoctor;
      const matchStatus = !filterStatus || a.status === filterStatus;
      const matchType = !filterType || a.type === filterType;
      return matchDoctor && matchStatus && matchType;
    });
  }, [appointments, filterDoctor, filterStatus, filterType]);

  const walkInQueue = useMemo(() => {
    return appointments.filter((a) => a.type === "walk-in" && (a.status === "waiting" || a.status === "in-progress"));
  }, [appointments]);

  const updateStatus = (id: string, newStatus: "in-progress" | "completed" | "no-show") => {
    setAppointments((prev) =>
      prev.map((a) => (a.id === id ? { ...a, status: newStatus } : a))
    );
  };

  const waitingCount = appointments.filter((a) => a.status === "waiting").length;
  const inProgressCount = appointments.filter((a) => a.status === "in-progress").length;
  const completedCount = appointments.filter((a) => a.status === "completed").length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Appointments</h1>
          <p className="text-gray-500 mt-1">
            Today &middot; {appointments.length} total &middot; {waitingCount} waiting &middot; {inProgressCount} in progress &middot; {completedCount} completed
          </p>
        </div>
        <button className="btn-primary">+ New Appointment</button>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {[
          { label: "Total", value: appointments.length, color: "bg-blue-50 text-blue-600" },
          { label: "Waiting", value: waitingCount, color: "bg-yellow-50 text-yellow-600" },
          { label: "In Progress", value: inProgressCount, color: "bg-purple-50 text-purple-600" },
          { label: "Completed", value: completedCount, color: "bg-green-50 text-green-600" },
        ].map((s) => (
          <div key={s.label} className="stat-card">
            <p className="text-sm text-gray-500">{s.label}</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{s.value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main appointment list */}
        <div className="lg:col-span-2 space-y-4">
          {/* Filters */}
          <div className="flex flex-wrap gap-3">
            <select
              value={filterDoctor}
              onChange={(e) => setFilterDoctor(e.target.value)}
              className="input w-auto min-w-[200px]"
            >
              <option value="">All Doctors</option>
              {doctors.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.name}
                </option>
              ))}
            </select>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="input w-auto min-w-[160px]"
            >
              <option value="">All Statuses</option>
              <option value="waiting">Waiting</option>
              <option value="in-progress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
              <option value="no-show">No Show</option>
            </select>
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="input w-auto min-w-[160px]"
            >
              <option value="">All Types</option>
              <option value="scheduled">Scheduled</option>
              <option value="walk-in">Walk-In</option>
              <option value="follow-up">Follow-Up</option>
              <option value="emergency">Emergency</option>
            </select>
          </div>

          {/* Table */}
          <div className="table-container">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50">
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Patient</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Doctor</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {filtered.map((apt) => (
                    <tr key={apt.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 text-sm font-medium text-gray-900">{apt.time}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-medium text-xs">
                            {apt.patientName.split(" ").map((n) => n[0]).join("")}
                          </div>
                          <span className="text-sm font-medium text-gray-900">{apt.patientName}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">{apt.doctorName}</td>
                      <td className="px-6 py-4">
                        <AppointmentTypeBadge type={apt.type} />
                      </td>
                      <td className="px-6 py-4">
                        <StatusBadge status={apt.status} />
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex gap-2">
                          {apt.status === "waiting" && (
                            <button
                              onClick={() => updateStatus(apt.id, "in-progress")}
                              className="text-xs font-medium px-3 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors"
                            >
                              Check In
                            </button>
                          )}
                          {(apt.status === "waiting" || apt.status === "in-progress") && (
                            <button
                              onClick={() => updateStatus(apt.id, "no-show")}
                              className="text-xs font-medium px-3 py-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                            >
                              No Show
                            </button>
                          )}
                          {apt.status === "in-progress" && (
                            <button
                              onClick={() => updateStatus(apt.id, "completed")}
                              className="text-xs font-medium px-3 py-1.5 rounded-lg bg-green-50 text-green-600 hover:bg-green-100 transition-colors"
                            >
                              Complete
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                  {filtered.length === 0 && (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-gray-400">
                        No appointments match your filters.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Walk-in Queue Panel */}
        <div className="table-container h-fit">
          <div className="px-6 py-4 border-b border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900">Walk-in Queue</h3>
            <p className="text-sm text-gray-500 mt-0.5">
              {walkInQueue.length} in queue
            </p>
          </div>
          <div className="divide-y divide-gray-100">
            {walkInQueue.length === 0 ? (
              <div className="px-6 py-8 text-center text-gray-400 text-sm">
                No walk-ins in queue
              </div>
            ) : (
              walkInQueue.map((apt, idx) => (
                <div key={apt.id} className="px-6 py-3 hover:bg-gray-50 transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-7 h-7 bg-orange-100 rounded-full flex items-center justify-center text-orange-600 font-bold text-xs">
                        {idx + 1}
                      </div>
                      <div>
                        <p className="font-medium text-sm text-gray-900">{apt.patientName}</p>
                        <p className="text-xs text-gray-500">{apt.doctorName}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-gray-500">{apt.time}</p>
                      <StatusBadge status={apt.status} />
                    </div>
                  </div>
                  {apt.status === "waiting" && (
                    <div className="mt-2 flex gap-2">
                      <button
                        onClick={() => updateStatus(apt.id, "in-progress")}
                        className="text-xs font-medium px-2.5 py-1 rounded-md bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors"
                      >
                        Check In
                      </button>
                      <button
                        onClick={() => updateStatus(apt.id, "no-show")}
                        className="text-xs font-medium px-2.5 py-1 rounded-md bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                      >
                        No Show
                      </button>
                    </div>
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
