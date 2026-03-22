import SwiftUI
import SwiftData

struct AdminPatientsView: View {
    @Query private var profiles: [UserProfile]
    @State private var searchText = ""

    private var filteredProfiles: [UserProfile] {
        if searchText.isEmpty { return profiles }
        return profiles.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.md) {
                    MCTextField(label: "Search patients", icon: "magnifyingglass", text: $searchText)
                        .padding(.horizontal, MCSpacing.screenPadding)

                    HStack {
                        Text("\(filteredProfiles.count) patients")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    LazyVStack(spacing: MCSpacing.sm) {
                        ForEach(filteredProfiles) { profile in
                            MCCard {
                                HStack(spacing: MCSpacing.md) {
                                    Text(profile.avatarEmoji)
                                        .font(.system(size: 28))
                                        .frame(width: 44, height: 44)
                                        .background(MCColors.primaryTeal.opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                        Text(profile.name)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(MCColors.textPrimary)

                                        if let gender = profile.gender {
                                            Text(gender.rawValue)
                                                .font(MCTypography.caption)
                                                .foregroundStyle(MCColors.textSecondary)
                                        }

                                        Text("\(profile.episodes.count) episodes")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textTertiary)
                                    }

                                    Spacer()

                                    if profile.isActive {
                                        Text("Active")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.success)
                                            .padding(.horizontal, MCSpacing.xs)
                                            .padding(.vertical, MCSpacing.xxs)
                                            .background(MCColors.success.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
                .padding(.top, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Patients")
        }
    }
}
