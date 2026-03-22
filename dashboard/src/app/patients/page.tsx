"use client";

import { useState, useMemo } from "react";
import { patients, doctors } from "@/lib/mock-data";

const ITEMS_PER_PAGE = 8;

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

function AdherenceBadge({ percent }: { percent: number }) {
  const color =
    percent >= 90
      ? "text-green-700 bg-green-100"
      : percent >= 70
      ? "text-yellow-700 bg-yellow-100"
      : "text-red-700 bg-red-100";
  return <span className={`badge ${color}`}>{percent}%</span>;
}

export default function PatientsPage() {
  const [search, setSearch] = useState("");
  const [filterDoctor, setFilterDoctor] = useState("");
  const [filterStatus, setFilterStatus] = useState("");
  const [currentPage, setCurrentPage] = useState(1);

  const filtered = useMemo(() => {
    return patients.filter((p) => {
      const matchSearch =
        !search ||
        p.name.toLowerCase().includes(search.toLowerCase()) ||
        p.condition.toLowerCase().includes(search.toLowerCase()) ||
        p.phone.includes(search);
      const matchDoctor = !filterDoctor || p.doctorId === filterDoctor;
      const matchStatus = !filterStatus || p.status === filterStatus;
      return matchSearch && matchDoctor && matchStatus;
    });
  }, [search, filterDoctor, filterStatus]);

  const totalPages = Math.ceil(filtered.length / ITEMS_PER_PAGE);
  const paginated = filtered.slice(
    (currentPage - 1) * ITEMS_PER_PAGE,
    currentPage * ITEMS_PER_PAGE
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Patients</h1>
          <p className="text-gray-500 mt-1">
            {filtered.length} patient{filtered.length !== 1 ? "s" : ""} found
          </p>
        </div>
        <button className="btn-primary">+ Add Patient</button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        <div className="flex-1 min-w-[240px]">
          <div className="relative">
            <svg
              className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              type="text"
              placeholder="Search by name, condition, or phone..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setCurrentPage(1);
              }}
              className="input pl-10"
            />
          </div>
        </div>
        <select
          value={filterDoctor}
          onChange={(e) => {
            setFilterDoctor(e.target.value);
            setCurrentPage(1);
          }}
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
          onChange={(e) => {
            setFilterStatus(e.target.value);
            setCurrentPage(1);
          }}
          className="input w-auto min-w-[160px]"
        >
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="critical">Critical</option>
          <option value="recovered">Recovered</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      {/* Table */}
      <div className="table-container">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50">
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Patient</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Phone</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Doctor</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Condition</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Visit</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Adherence</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {paginated.map((patient) => (
                <tr key={patient.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-medium text-xs">
                        {patient.name.split(" ").map((n) => n[0]).join("")}
                      </div>
                      <div>
                        <p className="font-medium text-gray-900 text-sm">{patient.name}</p>
                        <p className="text-xs text-gray-500">
                          {patient.age}y, {patient.gender.charAt(0).toUpperCase() + patient.gender.slice(1)}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">{patient.phone}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{patient.doctorName}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{patient.condition}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{patient.lastVisit}</td>
                  <td className="px-6 py-4">
                    <AdherenceBadge percent={patient.adherencePercent} />
                  </td>
                  <td className="px-6 py-4">
                    <StatusBadge status={patient.status} />
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <button className="text-sm text-primary-500 hover:text-primary-600 font-medium">View</button>
                      <button className="text-sm text-gray-400 hover:text-gray-600 font-medium">Edit</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="px-6 py-4 border-t border-gray-100 flex items-center justify-between">
            <p className="text-sm text-gray-500">
              Showing {(currentPage - 1) * ITEMS_PER_PAGE + 1} to{" "}
              {Math.min(currentPage * ITEMS_PER_PAGE, filtered.length)} of {filtered.length} patients
            </p>
            <div className="flex gap-2">
              <button
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                disabled={currentPage === 1}
                className="btn-secondary text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                <button
                  key={page}
                  onClick={() => setCurrentPage(page)}
                  className={`w-9 h-9 rounded-lg text-sm font-medium transition-colors ${
                    page === currentPage
                      ? "bg-primary-500 text-white"
                      : "text-gray-600 hover:bg-gray-100"
                  }`}
                >
                  {page}
                </button>
              ))}
              <button
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                disabled={currentPage === totalPages}
                className="btn-secondary text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
