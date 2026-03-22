import SwiftUI

/// Referral program view — invite friends, earn free Pro months
struct ReferralView: View {
    @State private var referralCode: String = ""
    @State private var isLoading = false
    @State private var invitesSent: Int = 0
    @State private var friendsJoined: Int = 0
    @State private var rewardsEarned: Int = 0
    @State private var showShareSheet = false
    @State private var showCopiedToast = false

    private let referralLink: String = "https://medcare.app/invite/"

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.sectionSpacing) {
                headerSection
                referralCodeCard
                statsSection
                shareSection
                howItWorksSection
            }
            .padding(MCSpacing.md)
        }
        .navigationTitle("Refer & Earn")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadReferralData()
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: MCSpacing.sm) {
            Image(systemName: "gift.fill")
                .font(.system(size: 48))
                .foregroundStyle(MCColors.primaryTeal)

            Text("Get 1 Month Pro Free")
                .font(MCTypography.title2)
                .foregroundStyle(MCColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("When your friend joins MedCare, you both get a free month of Pro.")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, MCSpacing.lg)
    }

    // MARK: - Referral Code Card

    private var referralCodeCard: some View {
        VStack(spacing: MCSpacing.sm) {
            Text("Your Referral Code")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
                .textCase(.uppercase)

            if isLoading {
                ProgressView()
                    .frame(height: 44)
            } else {
                Text(referralCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(MCColors.primaryTeal)
                    .kerning(4)
            }

            Button {
                copyToClipboard()
            } label: {
                Label("Copy Code", systemImage: "doc.on.doc")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.primaryTeal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MCSpacing.lg)
        .background(MCColors.primaryTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: MCSpacing.md) {
            statCard(title: "Invites Sent", value: "\(invitesSent)", icon: "paperplane.fill")
            statCard(title: "Friends Joined", value: "\(friendsJoined)", icon: "person.2.fill")
            statCard(title: "Rewards", value: "\(rewardsEarned) mo", icon: "crown.fill")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(MCColors.primaryTeal)

            Text(value)
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            Text(title)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(MCSpacing.sm)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Share Buttons

    private var shareSection: some View {
        VStack(spacing: MCSpacing.sm) {
            Text("Share with friends")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            VStack(spacing: MCSpacing.xs) {
                shareButton(
                    title: "Share on WhatsApp",
                    icon: "message.fill",
                    color: Color(red: 0.15, green: 0.68, blue: 0.38)
                ) {
                    shareViaWhatsApp()
                }

                shareButton(
                    title: "Share via SMS",
                    icon: "text.bubble.fill",
                    color: MCColors.primaryTeal
                ) {
                    shareViaSMS()
                }

                shareButton(
                    title: "Copy Invite Link",
                    icon: "link",
                    color: MCColors.textSecondary
                ) {
                    copyToClipboard()
                }

                Button {
                    showShareSheet = true
                } label: {
                    Label("More Options", systemImage: "square.and.arrow.up")
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.primaryTeal)
                        .frame(maxWidth: .infinity)
                        .padding(MCSpacing.sm)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            let shareText = "Try MedCare — the smartest health app for Indian families! Use my code \(referralCode) to get started: \(referralLink)\(referralCode)"
            ShareSheet(items: [shareText])
        }
    }

    private func shareButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(MCColors.textSecondary)
            }
            .padding(MCSpacing.sm)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("How it works")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            stepRow(number: 1, text: "Share your unique referral code with friends")
            stepRow(number: 2, text: "Your friend downloads MedCare and enters your code")
            stepRow(number: 3, text: "You both get 1 month of Pro for free!")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MCSpacing.md)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: MCSpacing.sm) {
            Text("\(number)")
                .font(MCTypography.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(MCColors.primaryTeal)
                .clipShape(Circle())

            Text(text)
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
        }
    }

    // MARK: - Toast

    private var copiedToast: some View {
        Text("Copied to clipboard!")
            .font(MCTypography.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, MCSpacing.md)
            .padding(.vertical, MCSpacing.sm)
            .background(MCColors.primaryTeal)
            .clipShape(Capsule())
            .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Actions

    private func loadReferralData() async {
        isLoading = true
        // TODO: Call GET /api/v1/referrals/stats
        // For now, generate a code from user name
        referralCode = "RAHUL2026"
        invitesSent = 5
        friendsJoined = 2
        rewardsEarned = 2
        isLoading = false
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = "\(referralLink)\(referralCode)"
        withAnimation(.easeInOut(duration: 0.3)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCopiedToast = false }
        }
    }

    private func shareViaWhatsApp() {
        let message = "Try MedCare — the smartest health app for Indian families! Use my code \(referralCode) to get started: \(referralLink)\(referralCode)"
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "whatsapp://send?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func shareViaSMS() {
        let message = "Try MedCare! Use my code \(referralCode): \(referralLink)\(referralCode)"
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ShareSheet UIKit wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
