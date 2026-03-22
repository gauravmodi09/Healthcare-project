import SwiftUI
import SwiftData

struct DoctorPatientsListView: View {
    @Environment(DataService.self) private var dataService
    @Query private var profiles: [UserProfile]
    @State private var searchText = ""

    private var patients: [DoctorPatientData] {
        let all = profiles.map { DoctorPatientData.from(profile: $0) }
        if searchText.isEmpty { return all }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.primaryCondition.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.md) {
                    // Search
                    MCTextField(label: "Search patients", icon: "magnifyingglass", text: $searchText)
                        .padding(.horizontal, MCSpacing.screenPadding)

                    // Patient count
                    HStack {
                        Text("\(patients.count) patients")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // Patient list
                    LazyVStack(spacing: MCSpacing.sm) {
                        ForEach(patients, id: \.name) { patient in
                            MCCard {
                                HStack(spacing: MCSpacing.md) {
                                    Text(patient.avatarEmoji)
                                        .font(.system(size: 32))
                                        .frame(width: 48, height: 48)
                                        .background(MCColors.primaryTeal.opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                        Text(patient.name)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(MCColors.textPrimary)

                                        Text(patient.primaryCondition)
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textSecondary)

                                        HStack(spacing: MCSpacing.xs) {
                                            Label("\(patient.adherencePercent)%", systemImage: "chart.bar.fill")
                                                .font(MCTypography.caption)
                                                .foregroundStyle(patient.adherencePercent >= 80 ? MCColors.success : MCColors.warning)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MCColors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
                .padding(.top, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("My Patients")
        }
    }
}
