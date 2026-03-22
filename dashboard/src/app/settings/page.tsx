"use client";

import { useState } from "react";
import {
  hospital,
  staffMembers,
  departments,
  workingHours,
  doctors,
} from "@/lib/mock-data";

function RoleBadge({ role }: { role: string }) {
  const cls =
    role === "doctor"
      ? "text-blue-700 bg-blue-100"
      : role === "nurse"
      ? "text-green-700 bg-green-100"
      : role === "receptionist"
      ? "text-purple-700 bg-purple-100"
      : role === "lab-tech"
      ? "text-amber-700 bg-amber-100"
      : role === "pharmacist"
      ? "text-teal-700 bg-teal-100"
      : "text-gray-700 bg-gray-100";
  return (
    <span className={`badge ${cls}`}>
      {role
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ")}
    </span>
  );
}

function StatusBadge({ status }: { status: string }) {
  const cls =
    status === "active"
      ? "text-green-700 bg-green-100"
      : status === "on-leave"
      ? "text-yellow-700 bg-yellow-100"
      : "text-red-700 bg-red-100";
  return (
    <span className={`badge ${cls}`}>
      {status
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ")}
    </span>
  );
}

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<"profile" | "hours" | "departments" | "staff" | "compliance">("profile");

  // Hospital profile form state
  const [hospitalName, setHospitalName] = useState(hospital.name);
  const [hospitalAddress, setHospitalAddress] = useState(hospital.address);
  const [hospitalPhone, setHospitalPhone] = useState(hospital.phone);
  const [hospitalEmail, setHospitalEmail] = useState(hospital.email);
  const [specialties, setSpecialties] = useState(
    [...new Set(doctors.map((d) => d.specialty))].join(", ")
  );

  // Working hours state
  const [hours, setHours] = useState(workingHours);

  // Departments state
  const [depts, setDepts] = useState(departments);
  const [newDeptName, setNewDeptName] = useState("");

  // DPDPA consent settings
  const [consentDataCollection, setConsentDataCollection] = useState(true);
  const [consentDataSharing, setConsentDataSharing] = useState(false);
  const [consentMarketing, setConsentMarketing] = useState(false);
  const [dataRetentionYears, setDataRetentionYears] = useState("7");

  const tabs = [
    { id: "profile" as const, name: "Hospital Profile" },
    { id: "hours" as const, name: "Working Hours" },
    { id: "departments" as const, name: "Departments" },
    { id: "staff" as const, name: "Staff" },
    { id: "compliance" as const, name: "Compliance" },
  ];

  const updateHours = (idx: number, field: "open" | "close" | "isOpen", value: string | boolean) => {
    setHours((prev) =>
      prev.map((h, i) => (i === idx ? { ...h, [field]: value } : h))
    );
  };

  const addDepartment = () => {
    if (!newDeptName.trim()) return;
    setDepts((prev) => [
      ...prev,
      { id: `dep${prev.length + 1}`, name: newDeptName.trim(), staffCount: 0 },
    ]);
    setNewDeptName("");
  };

  const removeDepartment = (id: string) => {
    setDepts((prev) => prev.filter((d) => d.id !== id));
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
        <p className="text-gray-500 mt-1">Manage hospital profile, hours, staff, and compliance</p>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="flex gap-6">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`pb-3 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab.id
                  ? "border-primary-500 text-primary-600"
                  : "border-transparent text-gray-500 hover:text-gray-700"
              }`}
            >
              {tab.name}
            </button>
          ))}
        </nav>
      </div>

      {/* Hospital Profile */}
      {activeTab === "profile" && (
        <div className="stat-card max-w-2xl space-y-5">
          <h3 className="text-lg font-semibold text-gray-900">Hospital Profile</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Hospital Name</label>
              <input
                type="text"
                value={hospitalName}
                onChange={(e) => setHospitalName(e.target.value)}
                className="input"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
              <textarea
                value={hospitalAddress}
                onChange={(e) => setHospitalAddress(e.target.value)}
                className="input"
                rows={2}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                <input
                  type="text"
                  value={hospitalPhone}
                  onChange={(e) => setHospitalPhone(e.target.value)}
                  className="input"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  value={hospitalEmail}
                  onChange={(e) => setHospitalEmail(e.target.value)}
                  className="input"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Specialties</label>
              <input
                type="text"
                value={specialties}
                onChange={(e) => setSpecialties(e.target.value)}
                placeholder="Comma-separated specialties"
                className="input"
              />
              <p className="text-xs text-gray-400 mt-1">Comma-separated list of specialties</p>
            </div>
          </div>
          <div className="pt-2">
            <button className="btn-primary">Save Changes</button>
          </div>
        </div>
      )}

      {/* Working Hours */}
      {activeTab === "hours" && (
        <div className="stat-card max-w-2xl space-y-5">
          <h3 className="text-lg font-semibold text-gray-900">Working Hours</h3>
          <div className="space-y-3">
            {hours.map((h, idx) => (
              <div key={h.day} className="flex items-center gap-4">
                <div className="w-28">
                  <span className="text-sm font-medium text-gray-700">{h.day}</span>
                </div>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={h.isOpen}
                    onChange={(e) => updateHours(idx, "isOpen", e.target.checked)}
                    className="w-4 h-4 rounded text-primary-500 border-gray-300 focus:ring-primary-500"
                  />
                  <span className="text-sm text-gray-500">{h.isOpen ? "Open" : "Closed"}</span>
                </label>
                {h.isOpen && (
                  <>
                    <input
                      type="time"
                      value={h.open}
                      onChange={(e) => updateHours(idx, "open", e.target.value)}
                      className="input w-auto"
                    />
                    <span className="text-gray-400">to</span>
                    <input
                      type="time"
                      value={h.close}
                      onChange={(e) => updateHours(idx, "close", e.target.value)}
                      className="input w-auto"
                    />
                  </>
                )}
              </div>
            ))}
          </div>
          <div className="pt-2">
            <button className="btn-primary">Save Hours</button>
          </div>
        </div>
      )}

      {/* Departments */}
      {activeTab === "departments" && (
        <div className="stat-card max-w-2xl space-y-5">
          <h3 className="text-lg font-semibold text-gray-900">Department Management</h3>
          <div className="flex gap-3">
            <input
              type="text"
              placeholder="New department name"
              value={newDeptName}
              onChange={(e) => setNewDeptName(e.target.value)}
              className="input flex-1"
              onKeyDown={(e) => e.key === "Enter" && addDepartment()}
            />
            <button onClick={addDepartment} className="btn-primary" disabled={!newDeptName.trim()}>
              Add
            </button>
          </div>
          <div className="divide-y divide-gray-100">
            {depts.map((dept) => (
              <div key={dept.id} className="flex items-center justify-between py-3">
                <div>
                  <p className="font-medium text-sm text-gray-900">{dept.name}</p>
                  <p className="text-xs text-gray-500">{dept.staffCount} staff members</p>
                </div>
                <button
                  onClick={() => removeDepartment(dept.id)}
                  className="text-sm text-red-500 hover:text-red-600 font-medium"
                >
                  Remove
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Staff Management */}
      {activeTab === "staff" && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">Staff Management</h3>
            <button className="btn-primary">+ Add Staff</button>
          </div>
          <div className="table-container">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50">
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Department</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Phone</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {staffMembers.map((staff) => (
                    <tr key={staff.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-medium text-xs">
                            {staff.name.split(" ").map((n) => n[0]).join("").slice(0, 2)}
                          </div>
                          <span className="text-sm font-medium text-gray-900">{staff.name}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <RoleBadge role={staff.role} />
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">{staff.department}</td>
                      <td className="px-6 py-4 text-sm text-gray-600">{staff.phone}</td>
                      <td className="px-6 py-4">
                        <StatusBadge status={staff.status} />
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex gap-2">
                          <button className="text-sm text-primary-500 hover:text-primary-600 font-medium">Edit</button>
                          <button className="text-sm text-red-500 hover:text-red-600 font-medium">Remove</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Compliance */}
      {activeTab === "compliance" && (
        <div className="space-y-6 max-w-2xl">
          {/* ABDM */}
          <div className="stat-card space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">ABDM Facility ID</h3>
            <div className="flex items-center gap-4 p-4 bg-blue-50 rounded-xl">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center text-blue-600">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900">Facility ID</p>
                <p className="text-sm text-blue-700 font-mono">IN2760012345</p>
                <p className="text-xs text-gray-500 mt-0.5">Registered with Ayushman Bharat Digital Mission</p>
              </div>
            </div>
          </div>

          {/* DPDPA Consent */}
          <div className="stat-card space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">DPDPA Consent Settings</h3>
            <p className="text-sm text-gray-500">Digital Personal Data Protection Act, 2023 compliance</p>
            <div className="space-y-4">
              <label className="flex items-start gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={consentDataCollection}
                  onChange={(e) => setConsentDataCollection(e.target.checked)}
                  className="w-4 h-4 mt-0.5 rounded text-primary-500 border-gray-300 focus:ring-primary-500"
                />
                <div>
                  <p className="text-sm font-medium text-gray-700">Data Collection Consent</p>
                  <p className="text-xs text-gray-500">Require explicit consent before collecting patient personal data</p>
                </div>
              </label>
              <label className="flex items-start gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={consentDataSharing}
                  onChange={(e) => setConsentDataSharing(e.target.checked)}
                  className="w-4 h-4 mt-0.5 rounded text-primary-500 border-gray-300 focus:ring-primary-500"
                />
                <div>
                  <p className="text-sm font-medium text-gray-700">Data Sharing Consent</p>
                  <p className="text-xs text-gray-500">Require consent before sharing data with third-party services or insurers</p>
                </div>
              </label>
              <label className="flex items-start gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={consentMarketing}
                  onChange={(e) => setConsentMarketing(e.target.checked)}
                  className="w-4 h-4 mt-0.5 rounded text-primary-500 border-gray-300 focus:ring-primary-500"
                />
                <div>
                  <p className="text-sm font-medium text-gray-700">Marketing Communications</p>
                  <p className="text-xs text-gray-500">Require opt-in for promotional SMS, email, and WhatsApp messages</p>
                </div>
              </label>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Data Retention Period</label>
                <select
                  value={dataRetentionYears}
                  onChange={(e) => setDataRetentionYears(e.target.value)}
                  className="input w-auto min-w-[200px]"
                >
                  <option value="3">3 years</option>
                  <option value="5">5 years</option>
                  <option value="7">7 years (recommended)</option>
                  <option value="10">10 years</option>
                </select>
                <p className="text-xs text-gray-400 mt-1">Medical records retention as per Clinical Establishments Act</p>
              </div>
            </div>
            <div className="pt-2">
              <button className="btn-primary">Save Consent Settings</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
