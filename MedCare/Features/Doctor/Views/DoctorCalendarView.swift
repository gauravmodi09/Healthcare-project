import SwiftUI

// MARK: - Calendar Models

enum CalendarSlotType: String, CaseIterable {
    case available = "Available"
    case booked = "Booked"
    case walkIn = "Walk-In"
    case breakTime = "Break"

    var color: Color {
        switch self {
        case .available: return MCColors.divider
        case .booked: return MCColors.primaryTeal
        case .walkIn: return MCColors.warning
        case .breakTime: return Color(hex: "6B7280")
        }
    }

    var icon: String {
        switch self {
        case .available: return "plus"
        case .booked: return "person.fill"
        case .walkIn: return "figure.walk"
        case .breakTime: return "cup.and.saucer.fill"
        }
    }
}

struct CalendarSlot: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let type: CalendarSlotType
    let patientName: String?
    let reason: String?
}

// MARK: - Doctor Calendar View

struct DoctorCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .day
    @State private var selectedSlot: CalendarSlot?
    @State private var showSettings = false

    // Working hours config
    @State private var startHour = 9
    @State private var endHour = 18
    @State private var breakStartHour = 13
    @State private var breakEndHour = 14
    @State private var slotDurationMinutes = 30

    enum CalendarViewMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
    }

    private var slots: [CalendarSlot] {
        generateMockSlots(for: selectedDate)
    }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: selectedDate)!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                calendarHeader
                Divider()

                ScrollView {
                    VStack(spacing: MCSpacing.md) {
                        if viewMode == .day {
                            dayView
                        } else {
                            weekView
                        }
                        legendSection
                    }
                    .padding(.vertical, MCSpacing.md)
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }
            }
            .sheet(item: $selectedSlot) { slot in
                slotDetailSheet(slot)
            }
            .sheet(isPresented: $showSettings) {
                workingHoursSettings
            }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        VStack(spacing: MCSpacing.sm) {
            // Date navigation
            HStack {
                Button {
                    moveDate(by: viewMode == .day ? -1 : -7)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MCColors.primaryTeal)
                }

                Spacer()

                Text(dateHeaderTitle)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Spacer()

                Button {
                    moveDate(by: viewMode == .day ? 1 : 7)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            // View mode toggle
            Picker("View", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .padding(.vertical, MCSpacing.sm)
        .background(MCColors.cardBackground)
    }

    // MARK: - Day View

    private var dayView: some View {
        VStack(spacing: MCSpacing.xxs) {
            ForEach(slots) { slot in
                Button {
                    selectedSlot = slot
                } label: {
                    daySlotRow(slot)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func daySlotRow(_ slot: CalendarSlot) -> some View {
        HStack(spacing: MCSpacing.sm) {
            // Time label
            VStack(alignment: .trailing, spacing: 0) {
                Text(timeString(slot.startTime))
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textSecondary)
                Text(timeString(slot.endTime))
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .frame(width: 52, alignment: .trailing)

            // Slot content
            HStack(spacing: MCSpacing.xs) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(slot.type.color)
                    .frame(width: 4)

                Image(systemName: slot.type.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(slot.type == .available ? MCColors.textTertiary : slot.type.color)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    if let name = slot.patientName {
                        Text(name)
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textPrimary)
                    }
                    Text(slot.type.rawValue)
                        .font(MCTypography.caption)
                        .foregroundStyle(slot.type == .available ? MCColors.textTertiary : slot.type.color)
                    if let reason = slot.reason {
                        Text(reason)
                            .font(.system(size: 10))
                            .foregroundStyle(MCColors.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if slot.type != .available && slot.type != .breakTime {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MCColors.textTertiary)
                }
            }
            .padding(MCSpacing.xs)
            .background(slot.type.color.opacity(slot.type == .available ? 0.05 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
        }
        .frame(minHeight: 56)
    }

    // MARK: - Week View

    private var weekView: some View {
        VStack(spacing: MCSpacing.xs) {
            // Day headers
            HStack(spacing: MCSpacing.xxs) {
                Text("")
                    .frame(width: 44)
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 2) {
                        Text(dayOfWeekShort(date))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isToday(date) ? MCColors.primaryTeal : MCColors.textTertiary)
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(isToday(date) ? .white : MCColors.textPrimary)
                            .frame(width: 24, height: 24)
                            .background(isToday(date) ? MCColors.primaryTeal : Color.clear)
                            .clipShape(Circle())
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            Divider()

            // Time grid
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(startHour..<endHour, id: \.self) { hour in
                        HStack(spacing: MCSpacing.xxs) {
                            Text(hourString(hour))
                                .font(.system(size: 10))
                                .foregroundStyle(MCColors.textTertiary)
                                .frame(width: 44, alignment: .trailing)

                            ForEach(weekDates, id: \.self) { date in
                                weekSlotCell(hour: hour, date: date)
                            }
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private func weekSlotCell(hour: Int, date: Date) -> some View {
        let slotType = mockSlotType(hour: hour, date: date)
        return RoundedRectangle(cornerRadius: 3)
            .fill(slotType.color.opacity(slotType == .available ? 0.1 : 0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .overlay(
                Group {
                    if slotType != .available {
                        Image(systemName: slotType.icon)
                            .font(.system(size: 8))
                            .foregroundStyle(slotType.color)
                    }
                }
            )
    }

    // MARK: - Legend

    private var legendSection: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("Legend")
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textSecondary)

                HStack(spacing: MCSpacing.md) {
                    ForEach(CalendarSlotType.allCases, id: \.self) { type in
                        HStack(spacing: MCSpacing.xxs) {
                            Circle()
                                .fill(type.color)
                                .frame(width: 8, height: 8)
                            Text(type.rawValue)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Slot Detail Sheet

    private func slotDetailSheet(_ slot: CalendarSlot) -> some View {
        NavigationStack {
            VStack(spacing: MCSpacing.md) {
                MCCard {
                    VStack(alignment: .leading, spacing: MCSpacing.sm) {
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: slot.type.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(slot.type.color)
                                .frame(width: 40, height: 40)
                                .background(slot.type.color.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                MCBadge(slot.type.rawValue, color: slot.type.color, style: .soft)
                                Text("\(timeString(slot.startTime)) - \(timeString(slot.endTime))")
                                    .font(MCTypography.subheadline)
                                    .foregroundStyle(MCColors.textSecondary)
                            }
                        }

                        if let name = slot.patientName {
                            Divider()
                            HStack(spacing: MCSpacing.sm) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(MCColors.textTertiary)
                                Text(name)
                                    .font(MCTypography.headline)
                                    .foregroundStyle(MCColors.textPrimary)
                            }
                        }

                        if let reason = slot.reason {
                            HStack(spacing: MCSpacing.sm) {
                                Image(systemName: "text.bubble")
                                    .foregroundStyle(MCColors.textTertiary)
                                Text(reason)
                                    .font(MCTypography.callout)
                                    .foregroundStyle(MCColors.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)

                Spacer()
            }
            .padding(.vertical, MCSpacing.md)
            .background(MCColors.backgroundLight)
            .navigationTitle("Slot Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { selectedSlot = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Working Hours Settings

    private var workingHoursSettings: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.md) {
                    MCCard {
                        VStack(spacing: MCSpacing.sm) {
                            settingsRow(label: "Start Time", value: "\(startHour):00", systemImage: "sunrise") {
                                if startHour > 6 { startHour -= 1 }
                            } increment: {
                                if startHour < endHour - 2 { startHour += 1 }
                            }

                            Divider()

                            settingsRow(label: "End Time", value: "\(endHour):00", systemImage: "sunset") {
                                if endHour > startHour + 2 { endHour -= 1 }
                            } increment: {
                                if endHour < 22 { endHour += 1 }
                            }

                            Divider()

                            settingsRow(label: "Break Start", value: "\(breakStartHour):00", systemImage: "cup.and.saucer") {
                                if breakStartHour > startHour { breakStartHour -= 1 }
                            } increment: {
                                if breakStartHour < breakEndHour - 1 { breakStartHour += 1 }
                            }

                            Divider()

                            settingsRow(label: "Break End", value: "\(breakEndHour):00", systemImage: "cup.and.saucer.fill") {
                                if breakEndHour > breakStartHour + 1 { breakEndHour -= 1 }
                            } increment: {
                                if breakEndHour < endHour { breakEndHour += 1 }
                            }

                            Divider()

                            settingsRow(label: "Slot Duration", value: "\(slotDurationMinutes) min", systemImage: "timer") {
                                if slotDurationMinutes > 15 { slotDurationMinutes -= 15 }
                            } increment: {
                                if slotDurationMinutes < 60 { slotDurationMinutes += 15 }
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Working Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func settingsRow(label: String, value: String, systemImage: String, decrement: @escaping () -> Void, increment: @escaping () -> Void) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundStyle(MCColors.primaryTeal)
                .frame(width: 24)
            Text(label)
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textPrimary)
            Spacer()
            HStack(spacing: MCSpacing.xs) {
                Button { decrement() } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(MCColors.textTertiary)
                }
                Text(value)
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textPrimary)
                    .frame(width: 52)
                Button { increment() } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    // MARK: - Helpers

    private var dateHeaderTitle: String {
        let formatter = DateFormatter()
        if viewMode == .day {
            formatter.dateFormat = "EEEE, MMM d"
        } else {
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: weekDates.first ?? selectedDate)
            let end = formatter.string(from: weekDates.last ?? selectedDate)
            return "\(start) - \(end)"
        }
        return formatter.string(from: selectedDate)
    }

    private func moveDate(by days: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func hourString(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return "\(h) \(suffix)"
    }

    private func dayOfWeekShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(3))
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func mockSlotType(hour: Int, date: Date) -> CalendarSlotType {
        if hour >= breakStartHour && hour < breakEndHour { return .breakTime }
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        let seed = hour * 7 + dayOfWeek
        switch seed % 5 {
        case 0: return .booked
        case 1: return .walkIn
        case 2: return .available
        case 3: return .booked
        default: return .available
        }
    }

    private func generateMockSlots(for date: Date) -> [CalendarSlot] {
        let calendar = Calendar.current
        var result: [CalendarSlot] = []

        var hour = startHour
        while hour < endHour {
            let slotStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let slotEnd = calendar.date(byAdding: .minute, value: slotDurationMinutes, to: slotStart)!
            let type = mockSlotType(hour: hour, date: date)

            let (name, reason): (String?, String?) = {
                switch type {
                case .booked:
                    let names = ["Ramesh Kumar", "Priya Sharma", "Suresh Patel", "Anita Desai"]
                    let reasons = ["BP check", "Diabetes follow-up", "Chest pain", "Skin rash"]
                    return (names[hour % names.count], reasons[hour % reasons.count])
                case .walkIn:
                    return ("Walk-In Patient", "General consultation")
                default:
                    return (nil, nil)
                }
            }()

            result.append(CalendarSlot(startTime: slotStart, endTime: slotEnd, type: type, patientName: name, reason: reason))

            // If slot duration is 30, add second half-hour slot
            if slotDurationMinutes == 30 {
                let secondStart = slotEnd
                let secondEnd = calendar.date(byAdding: .minute, value: slotDurationMinutes, to: secondStart)!
                let secondType = mockSlotType(hour: hour, date: calendar.date(byAdding: .day, value: 1, to: date)!)

                let (n2, r2): (String?, String?) = secondType == .booked
                    ? ("Vikram Singh", "Follow-up")
                    : secondType == .walkIn ? ("Walk-In", "Consultation") : (nil, nil)

                result.append(CalendarSlot(startTime: secondStart, endTime: secondEnd, type: secondType, patientName: n2, reason: r2))
            }

            hour += 1
        }

        return result
    }
}

#Preview {
    DoctorCalendarView()
}
