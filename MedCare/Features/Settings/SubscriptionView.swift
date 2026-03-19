import SwiftUI
import StoreKit

/// Subscription tier selection view with Free / Pro / Premium cards
struct MCSubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionService.SubscriptionTier = .pro
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    headerSection

                    // Tier cards
                    VStack(spacing: MCSpacing.md) {
                        ForEach(SubscriptionService.SubscriptionTier.allCases, id: \.rawValue) { tier in
                            tierCard(tier)
                        }
                    }

                    // Purchase button
                    if selectedTier != .free {
                        purchaseButton
                    }

                    // Error message
                    if let error = subscriptionService.purchaseError {
                        Text(error)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.error)
                            .padding(.horizontal, MCSpacing.md)
                    }

                    // Restore purchases
                    Button {
                        Task {
                            await subscriptionService.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                    .padding(.top, MCSpacing.xs)

                    // Legal
                    legalSection
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.bottom, MCSpacing.xxl)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("MedCare Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .task {
                await subscriptionService.loadProducts()
                selectedTier = subscriptionService.currentTier == .free ? .pro : subscriptionService.currentTier
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: MCSpacing.sm) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(MCColors.primaryTeal)
                .padding(.top, MCSpacing.lg)

            Text("Unlock Full Power")
                .font(MCTypography.title)
                .foregroundStyle(MCColors.textPrimary)

            Text("Choose the plan that fits your family's health needs")
                .font(MCTypography.callout)
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MCSpacing.lg)
        }
    }

    // MARK: - Tier Card

    private func tierCard(_ tier: SubscriptionService.SubscriptionTier) -> some View {
        let isCurrent = subscriptionService.currentTier == tier
        let isSelected = selectedTier == tier

        return Button {
            if !isCurrent || tier == .free {
                selectedTier = tier
            }
        } label: {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        HStack(spacing: MCSpacing.xs) {
                            Text(tier.displayName)
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)

                            if isCurrent {
                                Text("CURRENT")
                                    .font(MCTypography.captionBold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(MCColors.success)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(tier.monthlyPrice)
                            .font(MCTypography.title2)
                            .foregroundStyle(tierAccentColor(tier))
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? MCColors.primaryTeal : MCColors.textTertiary)
                }

                // Divider
                Rectangle()
                    .fill(MCColors.divider)
                    .frame(height: 1)

                // Features list
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(spacing: MCSpacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(tierAccentColor(tier))
                                .frame(width: 16, height: 16)

                            Text(feature)
                                .font(MCTypography.callout)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }
            }
            .padding(MCSpacing.cardPadding)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .stroke(
                        isSelected ? tierAccentColor(tier) : MCColors.divider,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? tierAccentColor(tier).opacity(0.15) : .clear,
                radius: 8, y: 2
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let product = subscriptionService.product(for: selectedTier) else { return }
            isPurchasing = true
            Task {
                do {
                    try await subscriptionService.purchase(product)
                } catch {
                    subscriptionService.purchaseError = error.localizedDescription
                }
                isPurchasing = false
            }
        } label: {
            HStack(spacing: MCSpacing.xs) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe to \(selectedTier.displayName)")
                        .font(MCTypography.bodyMedium)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.buttonHeight)
            .background(
                subscriptionService.currentTier == selectedTier
                    ? MCColors.textTertiary
                    : tierAccentColor(selectedTier)
            )
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        }
        .disabled(isPurchasing || subscriptionService.currentTier == selectedTier)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: MCSpacing.xxs) {
            Text("Subscriptions auto-renew monthly unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings > Apple ID.")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: MCSpacing.md) {
                Link("Terms of Use", destination: URL(string: "https://medcare.app/terms")!)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.primaryTeal)

                Link("Privacy Policy", destination: URL(string: "https://medcare.app/privacy")!)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.primaryTeal)
            }
        }
        .padding(.horizontal, MCSpacing.md)
        .padding(.top, MCSpacing.xs)
    }

    // MARK: - Helpers

    private func tierAccentColor(_ tier: SubscriptionService.SubscriptionTier) -> Color {
        switch tier {
        case .free: return MCColors.textSecondary
        case .pro: return MCColors.primaryTeal
        case .premium: return MCColors.accentCoral
        }
    }
}
