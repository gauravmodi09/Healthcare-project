"use client";

import { hospital } from "@/lib/mock-data";

export default function TopBar() {
  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6 sticky top-0 z-20">
      <div>
        <h2 className="text-lg font-semibold text-gray-900">{hospital.name}</h2>
        <p className="text-xs text-gray-500">{hospital.address}</p>
      </div>

      <div className="flex items-center gap-4">
        {/* Notification bell */}
        <button className="relative p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors">
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
          </svg>
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>

        {/* Admin profile */}
        <div className="flex items-center gap-3">
          <div className="text-right">
            <p className="text-sm font-medium text-gray-900">{hospital.adminName}</p>
            <p className="text-xs text-gray-500">Hospital Admin</p>
          </div>
          <div className="w-9 h-9 bg-primary-500 rounded-full flex items-center justify-center text-white font-medium text-sm">
            {hospital.adminName.split(" ").map((n) => n[0]).join("").slice(0, 2)}
          </div>
        </div>
      </div>
    </header>
  );
}
