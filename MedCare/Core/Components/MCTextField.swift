import SwiftUI

/// Styled text field with floating label
struct MCTextField: View {
    let label: String
    let icon: String?
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: MCSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(MCColors.textSecondary)
                    .frame(width: MCSpacing.iconSize)
            }

            VStack(alignment: .leading, spacing: 2) {
                if !text.isEmpty {
                    Text(label)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.primaryTeal)
                }
                TextField(label, text: $text)
                    .font(MCTypography.body)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, MCSpacing.md)
        .frame(height: MCSpacing.inputHeight)
        .background(MCColors.backgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                .stroke(text.isEmpty ? Color.clear : MCColors.primaryTeal.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Phone number input with country code
struct MCPhoneField: View {
    @Binding var phoneNumber: String
    let countryCode: String

    var body: some View {
        HStack(spacing: MCSpacing.sm) {
            HStack(spacing: MCSpacing.xxs) {
                Text("🇮🇳")
                    .font(.system(size: 24))
                Text(countryCode)
                    .font(MCTypography.bodyMedium)
                    .foregroundStyle(MCColors.textPrimary)
            }
            .padding(.horizontal, MCSpacing.sm)
            .frame(height: MCSpacing.inputHeight)
            .background(MCColors.backgroundLight)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))

            TextField("Phone number", text: $phoneNumber)
                .font(MCTypography.phoneNumber)
                .keyboardType(.phonePad)
                .padding(.horizontal, MCSpacing.md)
                .frame(height: MCSpacing.inputHeight)
                .background(MCColors.backgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        }
    }
}

/// OTP input field with individual digit boxes
struct MCOTPField: View {
    @Binding var otp: String
    let digitCount: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field for input
            TextField("", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .focused($isFocused)
                .onChange(of: otp) { _, newValue in
                    if newValue.count > digitCount {
                        otp = String(newValue.prefix(digitCount))
                    }
                }

            // Visual digit boxes
            HStack(spacing: MCSpacing.sm) {
                ForEach(0..<digitCount, id: \.self) { index in
                    let digit = index < otp.count
                        ? String(otp[otp.index(otp.startIndex, offsetBy: index)])
                        : ""

                    Text(digit)
                        .font(MCTypography.otpDigit)
                        .foregroundStyle(MCColors.textPrimary)
                        .frame(width: 52, height: 60)
                        .background(MCColors.backgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                .stroke(
                                    index == otp.count ? MCColors.primaryTeal : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
            }
        }
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            isFocused = true
        }
    }
}
