"use client";

import { useState, useMemo } from "react";
import { paymentTransactions, doctors } from "@/lib/mock-data";

function formatCurrency(amount: number): string {
  return amount.toLocaleString("en-IN");
}

function PaymentModeBadge({ mode }: { mode: string }) {
  const cls =
    mode === "upi"
      ? "text-purple-700 bg-purple-100"
      : mode === "cash"
      ? "text-green-700 bg-green-100"
      : mode === "insurance"
      ? "text-blue-700 bg-blue-100"
      : "text-gray-700 bg-gray-100";
  return (
    <span className={`badge ${cls}`}>
      {mode.toUpperCase()}
    </span>
  );
}

function PaymentStatusBadge({ status }: { status: string }) {
  const cls =
    status === "paid"
      ? "text-green-700 bg-green-100"
      : status === "pending"
      ? "text-yellow-700 bg-yellow-100"
      : status === "refunded"
      ? "text-orange-700 bg-orange-100"
      : "text-red-700 bg-red-100";
  return (
    <span className={`badge ${cls}`}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
}

export default function BillingPage() {
  const [searchInvoice, setSearchInvoice] = useState("");
  const [filterMode, setFilterMode] = useState("");
  const [filterStatus, setFilterStatus] = useState("");
  const [qrAmount, setQrAmount] = useState("");
  const [qrDescription, setQrDescription] = useState("");
  const [showQR, setShowQR] = useState(false);

  const filtered = useMemo(() => {
    return paymentTransactions.filter((t) => {
      const matchSearch =
        !searchInvoice ||
        (t.invoiceId && t.invoiceId.toLowerCase().includes(searchInvoice.toLowerCase())) ||
        t.patientName.toLowerCase().includes(searchInvoice.toLowerCase());
      const matchMode = !filterMode || t.mode === filterMode;
      const matchStatus = !filterStatus || t.status === filterStatus;
      return matchSearch && matchMode && matchStatus;
    });
  }, [searchInvoice, filterMode, filterStatus]);

  const today = "2026-03-21";
  const todayRevenue = paymentTransactions
    .filter((t) => t.date === today && t.status === "paid")
    .reduce((sum, t) => sum + t.amount, 0);

  const weekDates = Array.from({ length: 7 }, (_, i) => {
    const d = new Date("2026-03-21");
    d.setDate(d.getDate() - i);
    return d.toISOString().split("T")[0];
  });
  const weekRevenue = paymentTransactions
    .filter((t) => weekDates.includes(t.date) && t.status === "paid")
    .reduce((sum, t) => sum + t.amount, 0);

  const monthRevenue = paymentTransactions
    .filter((t) => t.date.startsWith("2026-03") && t.status === "paid")
    .reduce((sum, t) => sum + t.amount, 0);

  const outstanding = paymentTransactions
    .filter((t) => t.status === "pending")
    .reduce((sum, t) => sum + t.amount, 0);

  // GST summary (18% GST = 9% CGST + 9% SGST)
  const totalPaidAmount = paymentTransactions
    .filter((t) => t.status === "paid")
    .reduce((sum, t) => sum + t.amount, 0);
  const baseAmount = Math.round(totalPaidAmount / 1.18);
  const totalGST = totalPaidAmount - baseAmount;
  const cgst = Math.round(totalGST / 2);
  const sgst = totalGST - cgst;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Billing</h1>
        <p className="text-gray-500 mt-1">Revenue summary, payments, and invoices</p>
      </div>

      {/* Revenue summary cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { label: "Today", value: todayRevenue, color: "bg-blue-50", iconColor: "text-blue-600" },
          { label: "This Week", value: weekRevenue, color: "bg-green-50", iconColor: "text-green-600" },
          { label: "This Month", value: monthRevenue, color: "bg-purple-50", iconColor: "text-purple-600" },
          { label: "Outstanding", value: outstanding, color: "bg-amber-50", iconColor: "text-amber-600" },
        ].map((s) => (
          <div key={s.label} className="stat-card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{s.label}</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">
                  &#8377;{formatCurrency(s.value)}
                </p>
              </div>
              <div className={`w-12 h-12 ${s.color} rounded-xl flex items-center justify-center ${s.iconColor}`}>
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Payment transactions table */}
        <div className="lg:col-span-2 space-y-4">
          {/* Search + Filters */}
          <div className="flex flex-wrap gap-3">
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
                  placeholder="Search by invoice ID or patient name..."
                  value={searchInvoice}
                  onChange={(e) => setSearchInvoice(e.target.value)}
                  className="input pl-10"
                />
              </div>
            </div>
            <select
              value={filterMode}
              onChange={(e) => setFilterMode(e.target.value)}
              className="input w-auto min-w-[140px]"
            >
              <option value="">All Modes</option>
              <option value="upi">UPI</option>
              <option value="cash">Cash</option>
              <option value="insurance">Insurance</option>
              <option value="card">Card</option>
            </select>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="input w-auto min-w-[140px]"
            >
              <option value="">All Statuses</option>
              <option value="paid">Paid</option>
              <option value="pending">Pending</option>
              <option value="refunded">Refunded</option>
              <option value="failed">Failed</option>
            </select>
          </div>

          {/* Table */}
          <div className="table-container">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50">
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Patient</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Doctor</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Mode</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Invoice</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {filtered.map((txn) => (
                    <tr key={txn.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 text-sm text-gray-600">{txn.date}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-medium text-xs">
                            {txn.patientName.split(" ").map((n) => n[0]).join("")}
                          </div>
                          <span className="text-sm font-medium text-gray-900">{txn.patientName}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">{txn.doctorName}</td>
                      <td className="px-6 py-4 text-sm font-medium text-gray-900">&#8377;{formatCurrency(txn.amount)}</td>
                      <td className="px-6 py-4">
                        <PaymentModeBadge mode={txn.mode} />
                      </td>
                      <td className="px-6 py-4">
                        <PaymentStatusBadge status={txn.status} />
                      </td>
                      <td className="px-6 py-4">
                        {txn.invoiceId ? (
                          <button className="text-sm text-primary-500 hover:text-primary-600 font-medium">
                            {txn.invoiceId}
                          </button>
                        ) : (
                          <span className="text-sm text-gray-400">--</span>
                        )}
                      </td>
                    </tr>
                  ))}
                  {filtered.length === 0 && (
                    <tr>
                      <td colSpan={7} className="px-6 py-12 text-center text-gray-400">
                        No transactions match your filters.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right column: QR + GST */}
        <div className="space-y-6">
          {/* UPI QR Code Generator */}
          <div className="stat-card">
            <h3 className="text-lg font-semibold text-gray-900 mb-1">UPI QR Code</h3>
            <p className="text-sm text-gray-500 mb-4">Generate QR for consultation fee</p>
            <div className="space-y-3">
              <input
                type="number"
                placeholder="Amount (INR)"
                value={qrAmount}
                onChange={(e) => setQrAmount(e.target.value)}
                className="input"
              />
              <input
                type="text"
                placeholder="Description (e.g. Consultation)"
                value={qrDescription}
                onChange={(e) => setQrDescription(e.target.value)}
                className="input"
              />
              <button
                onClick={() => setShowQR(!!qrAmount)}
                disabled={!qrAmount}
                className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Generate QR
              </button>
              {showQR && qrAmount && (
                <div className="mt-4 p-4 bg-gray-50 rounded-xl text-center">
                  <div className="w-40 h-40 mx-auto bg-white border-2 border-gray-200 rounded-lg flex items-center justify-center mb-3">
                    <div className="text-center">
                      <svg className="w-10 h-10 mx-auto text-gray-400 mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 013.75 9.375v-4.5zM3.75 14.625c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5a1.125 1.125 0 01-1.125-1.125v-4.5zM13.5 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 0113.5 9.375v-4.5z" />
                        <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 6.75h.75v.75h-.75v-.75zM6.75 16.5h.75v.75h-.75v-.75zM16.5 6.75h.75v.75h-.75v-.75zM13.5 13.5h.75v.75h-.75v-.75zM13.5 19.5h.75v.75h-.75v-.75zM19.5 13.5h.75v.75h-.75v-.75zM19.5 19.5h.75v.75h-.75v-.75zM16.5 16.5h.75v.75h-.75v-.75z" />
                      </svg>
                      <p className="text-xs text-gray-500">UPI QR</p>
                    </div>
                  </div>
                  <p className="text-lg font-bold text-gray-900">&#8377;{formatCurrency(Number(qrAmount))}</p>
                  {qrDescription && <p className="text-sm text-gray-500">{qrDescription}</p>}
                  <p className="text-xs text-gray-400 mt-1">shreesaihospital@upi</p>
                </div>
              )}
            </div>
          </div>

          {/* GST Summary */}
          <div className="stat-card">
            <h3 className="text-lg font-semibold text-gray-900 mb-1">GST Summary</h3>
            <p className="text-sm text-gray-500 mb-4">March 2026 (SAC: 9983)</p>
            <div className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Taxable Amount</span>
                <span className="font-medium text-gray-900">&#8377;{formatCurrency(baseAmount)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">CGST @ 9%</span>
                <span className="font-medium text-gray-900">&#8377;{formatCurrency(cgst)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">SGST @ 9%</span>
                <span className="font-medium text-gray-900">&#8377;{formatCurrency(sgst)}</span>
              </div>
              <div className="border-t border-gray-200 pt-3 flex justify-between text-sm">
                <span className="font-semibold text-gray-900">Total with GST</span>
                <span className="font-bold text-gray-900">&#8377;{formatCurrency(totalPaidAmount)}</span>
              </div>
              <div className="pt-2">
                <p className="text-xs text-gray-400">GSTIN: 27AABCS1234D1ZE</p>
                <p className="text-xs text-gray-400">HSN/SAC: 9983 - Medical Consultation</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
