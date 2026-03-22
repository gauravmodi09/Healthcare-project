import SwiftUI

// MARK: - Queue Models

enum QueueEntryStatus: String, CaseIterable, Codable {
    case waiting = "Waiting"
    case inConsultation = "In Consultation"
    case completed = "Completed"
    case noShow = "No-Show"

    var color: Color {
        switch self {
        case .waiting: return MCColors.warning
        case .inConsultation: return MCColors.primaryTeal
        case .completed: return MCColors.success
        case .noShow: return MCColors.textTertiary
        }
    }

    var icon: String {
        switch self {
        case .waiting: return "clock.fill"
        case .inConsultation: return "stethoscope"
        case .completed: return "checkmark.circle.fill"
        case .noShow: return "person.fill.xmark"
        }
    }
}

struct QueueEntry: Identifiable, Codable {
    var id: UUID
    var name: String
    var phone: String
    var reason: String
    var arrivalTime: Date
    var status: QueueEntryStatus
    var position: Int

    init(id: UUID = UUID(), name: String, phone: String, reason: String, arrivalTime: Date, status: QueueEntryStatus, position: Int) {
        self.id = id
        self.name = name
        self.phone = phone
        self.reason = reason
        self.arrivalTime = arrivalTime
        self.status = status
        self.position = position
    }
}

// MARK: - Queue Persistence

enum QueueStore {
    private static let storageKey = "mc_walkin_queue"
    private static let dateKey = "mc_walkin_queue_date"

    /// Load today's queue from UserDefaults. Returns empty if it's a new day.
    static func load() -> [QueueEntry] {
        let todayString = Self.todayString()

        // Check if the stored queue is from today
        guard let savedDate = UserDefaults.standard.string(forKey: dateKey),
              savedDate == todayString else {
            // Different day -- clear stale data
            UserDefaults.standard.removeObject(forKey: storageKey)
            UserDefaults.standard.set(todayString, forKey: dateKey)
            return []
        }

        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([QueueEntry].self, from: data) else {
            return []
        }
        return entries
    }

    /// Save queue entries to UserDefaults for today.
    static func save(_ entries: [QueueEntry]) {
        UserDefaults.standard.set(todayString(), forKey: dateKey)
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Walk-In Queue View

struct WalkInQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var queueEntries: [QueueEntry] = []
    @State private var showAddWalkIn = false

    private let avgConsultMinutes = 10

    private var waitingEntries: [QueueEntry] {
        queueEntries
            .filter { $0.status == .waiting }
            .sorted { $0.position < $1.position }
    }

    private var inConsultationEntry: QueueEntry? {
        queueEntries.first { $0.status == .inConsultation }
    }

    private var completedCount: Int {
        queueEntries.filter { $0.status == .completed }.count
    }

    private var waitingCount: Int {
        waitingEntries.count
    }

    private var avgWaitMinutes: Int {
        guard waitingCount > 0 else { return 0 }
        let totalWait = waitingEntries.enumerated().reduce(0) { sum, item in
            sum + (item.offset + 1) * avgConsultMinutes
        }
        return totalWait / waitingCount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    queueHeader
                    currentConsultation
                    waitingList
                    queueStats
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Walk-In Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddWalkIn = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }
            }
            .sheet(isPresented: $showAddWalkIn) {
                AddWalkInSheet { name, phone, reason in
                    let nextPosition = (queueEntries.map(\.position).max() ?? 0) + 1
                    let entry = QueueEntry(
                        name: name, phone: phone, reason: reason,
                        arrivalTime: Date(), status: .waiting, position: nextPosition
                    )
                    withAnimation { queueEntries.append(entry) }
                    persistQueue()
                }
            }
            .onAppear {
                queueEntries = QueueStore.load()
            }
        }
    }

    // MARK: - Queue Header

    private var queueHeader: some View {
        MCCard {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("Today's Queue")
                        .font(MCTypography.title2)
                        .foregroundStyle(MCColors.textPrimary)
                    Text("\(queueEntries.count) patients total")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                }
                Spacer()
                VStack(spacing: MCSpacing.xxs) {
                    Text("\(waitingCount)")
                        .font(MCTypography.metric)
                        .foregroundStyle(MCColors.warning)
                    Text("Waiting")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Current Consultation

    @ViewBuilder
    private var currentConsultation: some View {
        if let current = inConsultationEntry {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                sectionHeader(icon: "stethoscope", title: "IN CONSULTATION")

                MCAccentCard(accent: MCColors.primaryTeal) {
                    HStack(spacing: MCSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(MCColors.primaryTeal.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(MCColors.primaryTeal)
                        }

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text(current.name)
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)
                            Text(current.reason)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }

                        Spacer()

                        Button {
                            callNext()
                        } label: {
                            Text("Done")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, MCSpacing.sm)
                                .padding(.vertical, MCSpacing.xs)
                                .background(MCColors.success)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    // MARK: - Waiting List

    private var waitingList: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                sectionHeader(icon: "clock.fill", title: "WAITING")
                Spacer()
                if !waitingEntries.isEmpty && inConsultationEntry == nil {
                    Button {
                        callNext()
                    } label: {
                        HStack(spacing: MCSpacing.xxs) {
                            Image(systemName: "phone.arrow.up.right.fill")
                                .font(.system(size: 12))
                            Text("Call Next")
                                .font(MCTypography.captionBold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, MCSpacing.sm)
                        .padding(.vertical, MCSpacing.xs)
                        .background(MCColors.primaryTeal)
                        .clipShape(Capsule())
                    }
                    .padding(.trailing, MCSpacing.screenPadding)
                }
            }

            if waitingEntries.isEmpty {
                MCCard {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(MCColors.success)
                        Text("No patients waiting")
                            .font(MCTypography.callout)
                            .foregroundStyle(MCColors.textSecondary)
                        Spacer()
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                VStack(spacing: MCSpacing.xs) {
                    ForEach(waitingEntries) { entry in
                        PatientQueueCard(
                            entry: entry,
                            estimatedWaitMinutes: estimatedWait(for: entry),
                            onCall: { markInConsultation(entry) },
                            onNoShow: { markNoShow(entry) }
                        )
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    // MARK: - Queue Stats

    private var queueStats: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            sectionHeader(icon: "chart.bar.fill", title: "TODAY'S STATS")

            HStack(spacing: MCSpacing.sm) {
                statCard(value: "\(avgWaitMinutes) min", label: "Avg Wait", icon: "clock", color: MCColors.warning)
                statCard(value: "\(completedCount)", label: "Seen", icon: "checkmark.circle", color: MCColors.success)
                statCard(value: "\(waitingCount)", label: "Waiting", icon: "person.2", color: MCColors.info)
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .padding(.bottom, MCSpacing.lg)
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        MCCard {
            VStack(spacing: MCSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                Text(value)
                    .font(MCTypography.title2)
                    .foregroundStyle(MCColors.textPrimary)
                Text(label)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func callNext() {
        withAnimation {
            // Complete current consultation
            if let idx = queueEntries.firstIndex(where: { $0.status == .inConsultation }) {
                queueEntries[idx].status = .completed
                queueEntries[idx].position = 0
            }
            // Move next waiting to in consultation
            if let nextWaiting = waitingEntries.first,
               let idx = queueEntries.firstIndex(where: { $0.id == nextWaiting.id }) {
                queueEntries[idx].status = .inConsultation
            }
            recalculatePositions()
        }
        persistQueue()
    }

    private func markInConsultation(_ entry: QueueEntry) {
        withAnimation {
            // Complete any current consultation first
            if let idx = queueEntries.firstIndex(where: { $0.status == .inConsultation }) {
                queueEntries[idx].status = .completed
                queueEntries[idx].position = 0
            }
            if let idx = queueEntries.firstIndex(where: { $0.id == entry.id }) {
                queueEntries[idx].status = .inConsultation
            }
            recalculatePositions()
        }
        persistQueue()
    }

    private func markNoShow(_ entry: QueueEntry) {
        withAnimation {
            if let idx = queueEntries.firstIndex(where: { $0.id == entry.id }) {
                queueEntries[idx].status = .noShow
                queueEntries[idx].position = 0
            }
            recalculatePositions()
        }
        persistQueue()
    }

    private func recalculatePositions() {
        let waiting = queueEntries
            .filter { $0.status == .waiting }
            .sorted { $0.arrivalTime < $1.arrivalTime }
        for (offset, entry) in waiting.enumerated() {
            if let idx = queueEntries.firstIndex(where: { $0.id == entry.id }) {
                queueEntries[idx].position = offset + 1
            }
        }
    }

    private func persistQueue() {
        QueueStore.save(queueEntries)
    }

    private func estimatedWait(for entry: QueueEntry) -> Int {
        let positionInQueue = waitingEntries.firstIndex(where: { $0.id == entry.id }) ?? 0
        let offset = inConsultationEntry != nil ? 1 : 0
        return (positionInQueue + offset) * avgConsultMinutes
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(MCColors.primaryTeal)
                .font(.system(size: 14))
            Text(title)
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textSecondary)
                .kerning(1.2)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }
}

// MARK: - Add Walk-In Sheet

private struct AddWalkInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String, String) -> Void

    @State private var name = ""
    @State private var phone = ""
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.md) {
                    MCTextField(label: "Patient Name", icon: "person", text: $name)
                    MCTextField(label: "Phone Number", icon: "phone", text: $phone, keyboardType: .phonePad)
                    MCTextField(label: "Reason for Visit", icon: "text.bubble", text: $reason)

                    MCPrimaryButton("Add to Queue", icon: "plus.circle") {
                        onAdd(name, phone, reason)
                        dismiss()
                    }
                    .disabled(name.isEmpty || reason.isEmpty)
                    .opacity(name.isEmpty || reason.isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Walk-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    WalkInQueueView()
}
