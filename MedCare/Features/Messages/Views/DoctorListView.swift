import SwiftUI
import SwiftData

struct DoctorListView: View {
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss

    @State private var doctors: [DoctorInfo] = DoctorInfo.sampleDoctors
    @State private var showAddDoctor = false
    @State private var inviteCode = ""
    @State private var searchText = ""

    private var filteredDoctors: [DoctorInfo] {
        if searchText.isEmpty { return doctors }
        return doctors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.specialty.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var totalUnread: Int {
        doctors.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if doctors.isEmpty {
                    emptyState
                } else {
                    doctorList
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddDoctor = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search doctors")
            .alert("Add Doctor", isPresented: $showAddDoctor) {
                TextField("Enter invite code", text: $inviteCode)
                    .textInputAutocapitalization(.characters)
                Button("Cancel", role: .cancel) {
                    inviteCode = ""
                }
                Button("Link") {
                    linkDoctor()
                }
            } message: {
                Text("Enter the invite code from your doctor to start messaging.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MCSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MCColors.primaryTeal.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(MCColors.primaryTeal)
            }

            VStack(spacing: MCSpacing.xs) {
                Text("No Linked Doctors")
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Connect with your doctor to message them directly instead of using WhatsApp.")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MCSpacing.xl)
            }

            Button {
                showAddDoctor = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "person.badge.plus")
                    Text("Add Doctor")
                        .fontWeight(.semibold)
                }
                .font(MCTypography.bodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MCSpacing.sm)
                .background(MCColors.primaryTeal)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            }
            .padding(.horizontal, MCSpacing.xxl)

            Spacer()
        }
    }

    // MARK: - Doctor List

    private var doctorList: some View {
        ScrollView {
            LazyVStack(spacing: MCSpacing.sm) {
                ForEach(filteredDoctors) { doctor in
                    NavigationLink {
                        DoctorMessageView(doctor: doctor)
                    } label: {
                        doctorRow(doctor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
            .padding(.top, MCSpacing.sm)
            .padding(.bottom, MCSpacing.xxl)
        }
    }

    // MARK: - Doctor Row

    private func doctorRow(_ doctor: DoctorInfo) -> some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                // Avatar with online indicator
                ZStack(alignment: .bottomTrailing) {
                    Text(doctor.avatarEmoji)
                        .font(.system(size: 28))
                        .frame(width: MCSpacing.avatarSize, height: MCSpacing.avatarSize)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())

                    Circle()
                        .fill(doctor.isOnline ? MCColors.success : MCColors.textTertiary)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(MCColors.cardBackground, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }

                // Doctor info
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(doctor.name)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)

                    Text(doctor.specialty)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.primaryTeal)

                    if let preview = doctor.lastMessagePreview {
                        Text(preview)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Timestamp + unread
                VStack(alignment: .trailing, spacing: MCSpacing.xxs) {
                    if let date = doctor.lastMessageDate {
                        Text(relativeTime(date))
                            .font(.system(size: 11))
                            .foregroundStyle(MCColors.textTertiary)
                    }

                    if doctor.unreadCount > 0 {
                        Text("\(doctor.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(MCColors.primaryTeal)
                            .clipShape(Circle())
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MCColors.textTertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(doctor.name), \(doctor.specialty), \(doctor.unreadCount) unread messages")
    }

    // MARK: - Helpers

    private func relativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))d" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func linkDoctor() {
        guard !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // In a real app this would verify the code against a backend
        let newDoctor = DoctorInfo(
            id: UUID(),
            name: "Dr. \(inviteCode.prefix(1).uppercased() + inviteCode.dropFirst().lowercased())",
            specialty: "General Physician",
            avatarEmoji: "🩺",
            isOnline: false,
            inviteCode: inviteCode.uppercased(),
            lastMessagePreview: nil,
            lastMessageDate: nil,
            unreadCount: 0
        )
        doctors.append(newDoctor)
        inviteCode = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
