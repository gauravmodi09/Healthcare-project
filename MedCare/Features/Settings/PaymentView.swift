import SwiftUI

/// UPI payment view with subscription tiers and payment history
/// Supports Razorpay checkout with UPI app selection
struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaymentPlan = .pro
    @State private var currentPlan: PaymentPlan = .free
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var paymentHistory: [PaymentService.PaymentRecord] = []
    @State private var showPaymentSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    headerSection

                    // Plan cards
                    VStack(spacing: MCSpacing.md) {
                        ForEach(PaymentPlan.allCases) { plan in
                            planCard(plan)
                        }
                    }

                    // Upgrade button
                    if selectedPlan != .free && selectedPlan != currentPlan {
                        upgradeSection
                    }

                    // UPI app selector
                    if selectedPlan != .free {
                        upiAppSelector
                    }

                    // Error
                    if let errorMessage {
                        Text(errorMessage)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.error)
                            .padding(.horizontal, MCSpacing.md)
                    }

                    // Payment history
                    if !paymentHistory.isEmpty {
                        paymentHistorySection
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.bottom, MCSpacing.xxl)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Payment Successful", isPresented: $showPaymentSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("You are now on the \(selectedPlan.displayName) plan. Enjoy all the features!")
            }
            .task {
                await loadPaymentHistory()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: MCSpacing.xs) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(MCColors.warning)

            Text("Choose Your Plan")
                .font(MCTypography.title2)
                .foregroundStyle(MCColors.textPrimary)

            Text("Unlock the full power of MedCare")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
        }
        .padding(.top, MCSpacing.md)
    }

    // MARK: - Plan Card

    private func planCard(_ plan: PaymentPlan) -> some View {
        let isSelected = selectedPlan == plan
        let isCurrent = currentPlan == plan

        return MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        HStack(spacing: MCSpacing.xs) {
                            Text(plan.displayName)
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)
                            if isCurrent {
                                Text("CURRENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(MCColors.success)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(plan.priceLabel)
                            .font(MCTypography.title2)
                            .foregroundStyle(MCColors.primaryTeal)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? MCColors.primaryTeal : MCColors.textTertiary)
                }

                Divider()

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: MCSpacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(MCColors.success)
                            Text(feature)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                .stroke(isSelected ? MCColors.primaryTeal : .clear, lineWidth: 2)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPlan = plan
            }
        }
    }

    // MARK: - Upgrade Button

    private var upgradeSection: some View {
        MCPrimaryButton("Upgrade to \(selectedPlan.displayName) \u{2014} \(selectedPlan.priceLabel)", isLoading: isProcessing) {
            Task { await initiatePayment() }
        }
    }

    // MARK: - UPI App Selector

    private var upiAppSelector: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Pay via UPI")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)

            HStack(spacing: MCSpacing.lg) {
                upiAppButton(name: "PhonePe", icon: "phone.fill", color: .purple)
                upiAppButton(name: "GPay", icon: "g.circle.fill", color: .blue)
                upiAppButton(name: "Paytm", icon: "indianrupeesign.circle.fill", color: .cyan)
                upiAppButton(name: "UPI", icon: "qrcode", color: MCColors.primaryTeal)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
    }

    private func upiAppButton(name: String, icon: String, color: Color) -> some View {
        VStack(spacing: MCSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

            Text(name)
                .font(.system(size: 11))
                .foregroundStyle(MCColors.textSecondary)
        }
    }

    // MARK: - Payment History

    private var paymentHistorySection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Payment History")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            VStack(spacing: 0) {
                ForEach(paymentHistory) { payment in
                    HStack {
                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text(payment.description ?? "Payment")
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textPrimary)
                            if let date = payment.createdAt {
                                Text(date, style: .date)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: MCSpacing.xxs) {
                            Text("\u{20B9}\(payment.amount / 100)")
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textPrimary)
                            Text(payment.status.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(payment.status == "captured" ? MCColors.success : MCColors.warning)
                        }
                    }
                    .padding(.horizontal, MCSpacing.cardPadding)
                    .padding(.vertical, MCSpacing.sm)

                    if payment.id != paymentHistory.last?.id {
                        Divider().padding(.leading, MCSpacing.cardPadding)
                    }
                }
            }
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }

    // MARK: - Actions

    private func initiatePayment() async {
        guard selectedPlan != .free else { return }

        isProcessing = true
        errorMessage = nil

        do {
            let order = try await PaymentService.shared.createOrder(
                amount: Double(selectedPlan.annualPrice),
                currency: "INR"
            )

            // In production, this would open the Razorpay SDK checkout sheet.
            // The SDK callback provides paymentId + signature for verification.
            _ = PaymentService.shared.buildCheckoutParams(
                order: order,
                description: "\(selectedPlan.displayName) Annual Plan"
            )

            // TODO: Integrate Razorpay iOS SDK here
            // RazorpayCheckout.open(params) { paymentId, signature in ... }

            // Simulated success for scaffold
            showPaymentSuccess = true
            currentPlan = selectedPlan
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    private func loadPaymentHistory() async {
        do {
            let response = try await PaymentService.shared.getPaymentHistory()
            paymentHistory = response.payments
        } catch {
            // Silent fail — history is non-critical
        }
    }
}

#Preview {
    PaymentView()
}
