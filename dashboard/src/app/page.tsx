"use client";

import {
  dashboardStats,
  patients,
  todayAppointments,
  revenueData,
  doctors,
} from "@/lib/mock-data";

function formatCurrency(amount: number): string {
  if (amount >= 100000) {
    return `${(amount / 100000).toFixed(1)}L`;
  }
  if (amount >= 1000) {
    return `${(amount / 1000).toFixed(0)}K`;
  }
  return amount.toString();
}

function StatusBadge({ status }: { status: string }) {
  const cls =
    status === "active"
      ? "badge-active"
      : status === "critical"
      ? "badge-critical"
      : status === "recovered"
      ? "badge-recovered"
      : "badge-inactive";
  return (
    <span className={`badge ${cls}`}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
}

function AppointmentBadge({ type }: { type: string }) {
  const cls =
    type === "walk-in"
      ? "badge-walk-in"
      : type === "emergency"
      ? "badge-emergency"
      : type === "follow-up"
      ? "badge-follow-up"
      : "badge-scheduled";
  return (
    <span className={`badge ${cls}`}>
      {type
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ")}
    </span>
  );
}

function AppointmentStatusBadge({ status }: { status: string }) {
  const cls =
    status === "completed"
      ? "badge-completed"
      : status === "in-progress"
      ? "badge-in-progress"
      : status === "waiting"
      ? "badge-waiting"
      : "badge-cancelled";
  return (
    <span className={`badge ${cls}`}>
      {status
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ")}
    </span>
  );
}

export default function DashboardPage() {
  const maxRevenue = Math.max(...revenueData.map((d) => d.revenue));
  const recentPatients = [...patients]
    .sort((a, b) => new Date(b.lastVisit).getTime() - new Date(a.lastVisit).getTime())
    .slice(0, 6);
  const activeDoctors = doctors.filter((d) => d.status === "active");

  const stats = [
    {
      label: "Total Patients",
      value: dashboardStats.totalPatients.toLocaleString("en-IN"),
      change: `+${dashboardStats.patientChange}%`,
      positive: true,
      icon: (
        <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
      ),
      bgColor: "bg-blue-50",
      iconColor: "text-blue-600",
    },
    {
      label: "Active Doctors",
      value: dashboardStats.activeDoctors.toString(),
      change: "On Duty",
      positive: true,
      icon: (
        <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      bgColor: "bg-green-50",
      iconColor: "text-green-600",
    },
    {
      label: "Today's Appointments",
      value: dashboardStats.todayAppointments.toString(),
      change: `${todayAppointments.filter((a) => a.status === "completed").length} Completed`,
      positive: true,
      icon: (
        <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
      ),
      bgColor: "bg-purple-50",
      iconColor: "text-purple-600",
    },
    {
      label: "Monthly Revenue",
      value: `₹${formatCurrency(dashboardStats.monthlyRevenue)}`,
      change: `+${dashboardStats.revenueChange}%`,
      positive: true,
      icon: (
        <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      bgColor: "bg-amber-50",
      iconColor: "text-amber-600",
    },
  ];

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500 mt-1">Overview of your hospital performance</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div key={stat.label} className="stat-card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{stat.label}</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
              </div>
              <div className={`w-12 h-12 ${stat.bgColor} rounded-xl flex items-center justify-center ${stat.iconColor}`}>
                {stat.icon}
              </div>
            </div>
            <div className="mt-3">
              <span className="text-sm text-green-600 font-medium">{stat.change}</span>
              <span className="text-sm text-gray-500 ml-1">vs last month</span>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Patients Table */}
        <div className="lg:col-span-2 table-container">
          <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">Recent Patients</h3>
            <a href="/patients" className="text-sm text-primary-500 hover:text-primary-600 font-medium">
              View All
            </a>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-50">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Patient</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Doctor</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Visit</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {recentPatients.map((patient) => (
                  <tr key={patient.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-medium text-xs">
                          {patient.name.split(" ").map((n) => n[0]).join("")}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900 text-sm">{patient.name}</p>
                          <p className="text-xs text-gray-500">{patient.condition}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{patient.doctorName}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{patient.lastVisit}</td>
                    <td className="px-6 py-4">
                      <StatusBadge status={patient.status} />
                    </td>
                    <td className="px-6 py-4">
                      <button className="text-sm text-primary-500 hover:text-primary-600 font-medium">View</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Appointment Queue */}
        <div className="table-container">
          <div className="px-6 py-4 border-b border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900">Appointment Queue</h3>
            <p className="text-sm text-gray-500 mt-0.5">
              {todayAppointments.filter((a) => a.status === "waiting").length} waiting &middot;{" "}
              {todayAppointments.filter((a) => a.type === "walk-in").length} walk-ins
            </p>
          </div>
          <div className="divide-y divide-gray-100 max-h-[420px] overflow-y-auto">
            {todayAppointments.map((apt) => (
              <div key={apt.id} className="px-6 py-3 hover:bg-gray-50 transition-colors">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-sm text-gray-900">{apt.patientName}</p>
                    <p className="text-xs text-gray-500">{apt.doctorName}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-gray-700">{apt.time}</p>
                    <AppointmentBadge type={apt.type} />
                  </div>
                </div>
                <div className="mt-1.5">
                  <AppointmentStatusBadge status={apt.status} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Chart */}
        <div className="stat-card">
          <h3 className="text-lg font-semibold text-gray-900 mb-1">Revenue Trend</h3>
          <p className="text-sm text-gray-500 mb-6">Monthly revenue over last 6 months</p>
          <div className="flex items-end gap-4 h-48">
            {revenueData.map((d) => {
              const heightPercent = (d.revenue / maxRevenue) * 100;
              return (
                <div key={d.month} className="flex-1 flex flex-col items-center gap-2">
                  <span className="text-xs font-medium text-gray-700">
                    ₹{formatCurrency(d.revenue)}
                  </span>
                  <div
                    className="w-full bg-primary-500 rounded-t-md hover:bg-primary-600 transition-colors cursor-default"
                    style={{ height: `${heightPercent}%` }}
                    title={`₹${d.revenue.toLocaleString("en-IN")}`}
                  />
                  <span className="text-xs text-gray-500">{d.month}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Doctor Utilization */}
        <div className="stat-card">
          <h3 className="text-lg font-semibold text-gray-900 mb-1">Doctor Utilization</h3>
          <p className="text-sm text-gray-500 mb-4">Appointments today by doctor</p>
          <div className="space-y-3">
            {activeDoctors
              .sort((a, b) => b.appointmentsToday - a.appointmentsToday)
              .map((doc) => {
                const maxApts = Math.max(...activeDoctors.map((d) => d.appointmentsToday));
                const pct = maxApts > 0 ? (doc.appointmentsToday / maxApts) * 100 : 0;
                return (
                  <div key={doc.id}>
                    <div className="flex items-center justify-between mb-1">
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 text-xs font-medium">
                          {doc.name.split(" ").slice(1).map((n) => n[0]).join("")}
                        </div>
                        <span className="text-sm font-medium text-gray-900">{doc.name}</span>
                      </div>
                      <span className="text-sm text-gray-600">{doc.appointmentsToday} appts</span>
                    </div>
                    <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-primary-500 rounded-full transition-all"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                );
              })}
          </div>
        </div>
      </div>
    </div>
  );
}
