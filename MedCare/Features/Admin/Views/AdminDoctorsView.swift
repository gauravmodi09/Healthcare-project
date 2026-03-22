import SwiftUI
import SwiftData

struct AdminDoctorsView: View {
    @Query private var doctors: [Doctor]
    @State private var searchText = ""

    private var filteredDoctors: [Doctor] {
        if searchText.isEmpty { return doctors }
        return doctors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.specialty.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.md) {
                    MCTextField(label: "Search doctors", icon: "magnifyingglass", text: $searchText)
                        .padding(.horizontal, MCSpacing.screenPadding)

                    HStack {
                        Text("\(filteredDoctors.count) doctors")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    LazyVStack(spacing: MCSpacing.sm) {
                        ForEach(filteredDoctors) { doctor in
                            MCCard {
                                HStack(spacing: MCSpacing.md) {
                                    Text(doctor.avatarEmoji)
                                        .font(.system(size: 28))
                                        .frame(width: 44, height: 44)
                                        .background(Color(hex: "3B82F6").opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                        Text(doctor.name)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(MCColors.textPrimary)
                                        Text(doctor.specialty)
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textSecondary)
                                        if !doctor.registrationNumber.isEmpty {
                                            Text("Reg: \(doctor.registrationNumber)")
                                                .font(MCTypography.caption)
                                                .foregroundStyle(MCColors.textTertiary)
                                        }
                                    }

                                    Spacer()

                                    if doctor.consultationFee > 0 {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("Rs. \(Int(doctor.consultationFee))")
                                                .font(MCTypography.bodyMedium)
                                                .foregroundStyle(MCColors.primaryTeal)
                                            Text("per visit")
                                                .font(MCTypography.caption)
                                                .foregroundStyle(MCColors.textTertiary)
                                        }
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
            .navigationTitle("Doctors")
        }
    }
}
