import SwiftUI

/// Primary CTA button with gradient background
struct MCPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(title)
                        .font(MCTypography.headline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.buttonHeight)
            .background(MCColors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: MCColors.primaryTeal.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isLoading)
    }
}

/// Secondary outlined button
struct MCSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(MCTypography.headline)
            }
            .foregroundStyle(MCColors.primaryTeal)
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .stroke(MCColors.primaryTeal, lineWidth: 2)
            )
        }
    }
}

/// Coral accent button for primary CTAs
struct MCCoralButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(title)
                        .font(MCTypography.headline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.buttonHeight)
            .background(MCColors.coralGradient)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: MCColors.accentCoral.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isLoading)
    }
}
