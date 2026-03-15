import SwiftUI

struct ProfileSetupView: View {
    let phoneNumber: String
    @Environment(DataService.self) private var dataService
    @State private var name = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
    @State private var showDatePicker = false
    @State private var selectedGender: Gender?
    @State private var knownConditions: [String] = []
    @State private var conditionInput = ""
    @State private var isComplete = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                // Header
                VStack(spacing: MCSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(MCColors.primaryTeal.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Text("👤")
                            .font(.system(size: 48))
                    }

                    Text("Set up your profile")
                        .font(MCTypography.title)
                        .foregroundStyle(MCColors.textPrimary)

                    Text("Help us personalize your health journey")
                        .font(MCTypography.callout)
                        .foregroundStyle(MCColors.textSecondary)
                }
                .padding(.top, MCSpacing.lg)

                // Form
                VStack(spacing: MCSpacing.md) {
                    MCTextField(label: "Full Name", icon: "person", text: $name)

                    // Gender picker
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Gender")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.xs) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Button {
                                    selectedGender = gender
                                } label: {
                                    Text(gender.rawValue)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(selectedGender == gender ? .white : MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(
                                            selectedGender == gender
                                                ? MCColors.primaryTeal
                                                : MCColors.backgroundLight
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Date of Birth
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Date of Birth")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        Button {
                            showDatePicker.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(MCColors.textSecondary)
                                Text(dateOfBirth, style: .date)
                                    .font(MCTypography.body)
                                    .foregroundStyle(MCColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(MCColors.textTertiary)
                                    .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                            }
                            .padding(.horizontal, MCSpacing.md)
                            .frame(height: MCSpacing.inputHeight)
                            .background(MCColors.backgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                        }

                        if showDatePicker {
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(height: 150)
                                .clipped()
                        }
                    }

                    // Known conditions
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Known Conditions (optional)")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack {
                            TextField("e.g., Diabetes, Hypertension", text: $conditionInput)
                                .font(MCTypography.body)
                                .padding(.horizontal, MCSpacing.md)
                                .frame(height: MCSpacing.inputHeight)
                                .background(MCColors.backgroundLight)
                                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))

                            if !conditionInput.isEmpty {
                                Button {
                                    knownConditions.append(conditionInput)
                                    conditionInput = ""
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(MCColors.primaryTeal)
                                }
                            }
                        }

                        if !knownConditions.isEmpty {
                            FlowLayout(spacing: MCSpacing.xs) {
                                ForEach(knownConditions, id: \.self) { condition in
                                    HStack(spacing: MCSpacing.xxs) {
                                        Text(condition)
                                            .font(MCTypography.caption)
                                        Button {
                                            knownConditions.removeAll { $0 == condition }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .foregroundStyle(MCColors.primaryTeal)
                                    .padding(.horizontal, MCSpacing.sm)
                                    .padding(.vertical, MCSpacing.xxs)
                                    .background(MCColors.primaryTeal.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                // Continue button
                MCPrimaryButton("Complete Setup", icon: "checkmark") {
                    completeSetup()
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1 : 0.6)
                .padding(.top, MCSpacing.md)
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }

    private func completeSetup() {
        let user = dataService.getOrCreateUser(phoneNumber: phoneNumber)
        let profile = dataService.createProfile(
            for: user,
            name: name,
            relation: .myself,
            dob: dateOfBirth,
            gender: selectedGender
        )
        profile.knownConditions = knownConditions
        dataService.save()
    }
}

/// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}
