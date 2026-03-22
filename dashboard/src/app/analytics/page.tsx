"use client";

import {
  revenueData,
  demographics,
  topConditions,
  adherenceData,
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

const barColors = [
  "bg-primary-500",
  "bg-primary-400",
  "bg-primary-300",
  "bg-blue-500",
  "bg-blue-400",
  "bg-blue-300",
];

const demographicColors = [
  "bg-primary-300",
  "bg-primary-400",
  "bg-primary-500",
  "bg-primary-600",
  "bg-primary-700",
];

const adherenceColors = [
  "bg-green-500",
  "bg-yellow-400",
  "bg-orange-400",
  "bg-red-400",
];

export default function AnalyticsPage() {
  const maxRevenue = Math.max(...revenueData.map((d) => d.revenue));
  const maxConditionCount = Math.max(...topConditions.map((c) => c.count));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
        <p className="text-gray-500 mt-1">Hospital performance insights and trends</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue by Month */}
        <div className="stat-card">
          <h3 className="text-lg font-semibold text-gray-900 mb-1">Revenue by Month</h3>
          <p className="text-sm text-gray-500 mb-6">Last 6 months revenue trend</p>
          <div className="flex items-end gap-4 h-56">
            {revenueData.map((d, i) => {
              const heightPercent = (d.revenue / maxRevenue) * 100;
              return (
                <div key={d.month} className="flex-1 flex flex-col items-center gap-2">
                  <span className="text-xs font-medium text-gray-700">
                    ₹{formatCurrency(d.revenue)}
                  </span>
                  <div
                    className={`w-full ${barColors[i]} rounded-t-md hover:opacity-80 transition-opacity cursor-default`}
                    style={{ height: `${heightPercent}%` }}
                    title={`₹${d.revenue.toLocaleString("en-IN")} | ${d.patients} patients`}
                  />
                  <span className="text-xs text-gray-500">{d.month}</span>
                </div>
              );
            })}
          </div>
          <div className="mt-4 pt-4 border-t border-gray-100 flex items-center justify-between text-sm">
            <span className="text-gray-500">Total Revenue (6 months)</span>
            <span className="font-bold text-gray-900">
              ₹{formatCurrency(revenueData.reduce((sum, d) => sum + d.revenue, 0))}
            </span>
          </div>
        </div>

        {/* Patient Demographics */}
        <div className="stat-card">
          <h3 className="text-lg font-semibold text-gray-900 mb-1">Patient Demographics</h3>
          <p className="text-sm text-gray-500 mb-6">Age group distribution</p>

          {/* Stacked bar */}
          <div className="h-10 flex rounded-lg overflow-hidden mb-6">
            {demographics.map((d, i) => (
              <div
                key={d.ageGroup}
                className={`${demographicColors[i]} flex items-center justify-center text-white text-xs font-medium`}
                style={{ width: `${d.percentage}%` }}
                title={`${d.ageGroup}: ${d.count} (${d.percentage}%)`}
              >
                {d.percentage}%
              </div>
            ))}
          </div>

          <div className="space-y-3">
            {demographics.map((d, i) => (
              <div key={d.ageGroup} className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-3 h-3 rounded-full ${demographicColors[i]}`} />
                  <span className="text-sm text-gray-700">{d.ageGroup} years</span>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-sm font-medium text-gray-900">{d.count}</span>
                  <span className="text-sm text-gray-500 w-12 text-right">{d.percentage}%</span>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-4 pt-4 border-t border-gray-100 flex items-center justify-between text-sm">
            <span className="text-gray-500">Total Patients</span>
            <span className="font-bold text-gray-900">
              {demographics.reduce((sum, d) => sum + d.count, 0).toLocaleString("en-IN")}
            </span>
          </div>
        </div>

        {/* Top Conditions */}
        <div className="stat-card">
          <h3 className="text-lg font-semibold text-gray-900 mb-1">Top Conditions</h3>
          <p className="text-sm text-gray-500 mb-6">Most common diagnoses</p>
          <div className="space-y-4">
            {topConditions.map((c) => {
              const pct = (c.count / maxConditionCount) * 100;
              return (
                <div key={c.condition}>
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-sm font-medium text-gray-700">{c.condition}</span>
                    <div className="flex items-center gap-3">
                      <span className="text-sm text-gray-900 font-medium">{c.count}</span>
                      <span className="text-xs text-gray-500 w-12 text-right">{c.percentage}%</span>
                    </div>
                  </div>
                  <div className="w-full h-2.5 bg-gray-100 rounded-full overflow-hidden">
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

        {/* Adherence Rates */}
        <div className="stat-card">
          <h3 className="text-lg font-semibold text-gray-900 mb-1">Adherence Rates</h3>
          <p className="text-sm text-gray-500 mb-6">Patient medication adherence breakdown</p>

          {/* Donut-style visualization using bars */}
          <div className="flex items-center gap-8 mb-6">
            <div className="relative w-36 h-36">
              <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                {(() => {
                  let offset = 0;
                  const colors = ["#22c55e", "#eab308", "#f97316", "#ef4444"];
                  return adherenceData.map((d, i) => {
                    const dash = d.percentage;
                    const gap = 100 - dash;
                    const el = (
                      <circle
                        key={d.range}
                        cx="18"
                        cy="18"
                        r="15.9155"
                        fill="transparent"
                        stroke={colors[i]}
                        strokeWidth="3"
                        strokeDasharray={`${dash} ${gap}`}
                        strokeDashoffset={`${-offset}`}
                      />
                    );
                    offset += dash;
                    return el;
                  });
                })()}
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-2xl font-bold text-gray-900">62%</span>
                <span className="text-xs text-gray-500">Above 75%</span>
              </div>
            </div>

            <div className="flex-1 space-y-3">
              {adherenceData.map((d, i) => (
                <div key={d.range} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className={`w-3 h-3 rounded-full ${adherenceColors[i]}`} />
                    <span className="text-sm text-gray-700">{d.range}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-medium text-gray-900">{d.count}</span>
                    <span className="text-xs text-gray-500 w-10 text-right">{d.percentage}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-amber-50 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <svg className="w-5 h-5 text-amber-500 mt-0.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <div>
                <p className="text-sm font-medium text-amber-800">175 patients below 50% adherence</p>
                <p className="text-xs text-amber-600 mt-0.5">
                  Consider sending medication reminders via MedCare app
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
