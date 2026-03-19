import Foundation
import StoreKit

/// Freemium subscription service using StoreKit 2
/// Manages Free / Pro / Premium tiers with entitlement checks
@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var currentTier: SubscriptionTier = .free
    @Published var products: [Product] = []
    @Published var purchaseError: String?

    // MARK: - Product IDs

    private let productIDs: Set<String> = [
        "com.medcare.pro.monthly",
        "com.medcare.premium.monthly"
    ]

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Subscription Tiers

    enum SubscriptionTier: String, CaseIterable {
        case free, pro, premium

        var maxProfiles: Int {
            switch self {
            case .free: 1
            case .pro: 3
            case .premium: 5
            }
        }

        var maxMedicines: Int {
            switch self {
            case .free: 5
            case .pro: 999
            case .premium: 999
            }
        }

        var hasAIChat: Bool { self != .free }
        var hasExtraction: Bool { self != .free }
        var displayName: String { rawValue.capitalized }

        var monthlyPrice: String {
            switch self {
            case .free: "Free"
            case .pro: "\u{20B9}149/mo"
            case .premium: "\u{20B9}299/mo"
            }
        }

        var features: [String] {
            switch self {
            case .free:
                return [
                    "1 profile",
                    "Up to 5 medicines",
                    "Dose reminders",
                    "Basic history"
                ]
            case .pro:
                return [
                    "Up to 3 profiles",
                    "Unlimited medicines",
                    "AI prescription extraction",
                    "AI health chat",
                    "Drug interaction alerts",
                    "Export reports"
                ]
            case .premium:
                return [
                    "Up to 5 profiles",
                    "Unlimited medicines",
                    "AI prescription extraction",
                    "AI health chat",
                    "Drug interaction alerts",
                    "Export reports",
                    "Priority support",
                    "Refill reminders",
                    "Family sharing"
                ]
            }
        }

        var productID: String? {
            switch self {
            case .free: nil
            case .pro: "com.medcare.pro.monthly"
            case .premium: "com.medcare.premium.monthly"
            }
        }

        static func tier(for productID: String) -> SubscriptionTier {
            switch productID {
            case "com.medcare.pro.monthly": return .pro
            case "com.medcare.premium.monthly": return .premium
            default: return .free
            }
        }
    }

    // MARK: - Init

    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        purchaseError = nil

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateTierFromTransaction(transaction)
            await transaction.finish()

        case .userCancelled:
            break

        case .pending:
            purchaseError = "Purchase is pending approval."

        @unknown default:
            purchaseError = "Unknown purchase result."
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }

    // MARK: - Entitlement Check

    func checkEntitlements() async {
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.revocationDate == nil {
                let tier = SubscriptionTier.tier(for: transaction.productID)
                if tier == .premium {
                    highestTier = .premium
                } else if tier == .pro && highestTier != .premium {
                    highestTier = .pro
                }
            }
        }

        currentTier = highestTier
    }

    // MARK: - Helpers

    func product(for tier: SubscriptionTier) -> Product? {
        guard let id = tier.productID else { return nil }
        return products.first { $0.id == id }
    }

    func canAddProfile(currentCount: Int) -> Bool {
        currentCount < currentTier.maxProfiles
    }

    func canAddMedicine(currentCount: Int) -> Bool {
        currentCount < currentTier.maxMedicines
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                guard let transaction = try? self.checkVerified(result) else { continue }
                await self.updateTierFromTransaction(transaction)
                await transaction.finish()
            }
        }
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func updateTierFromTransaction(_ transaction: Transaction) async {
        let tier = SubscriptionTier.tier(for: transaction.productID)
        if transaction.revocationDate == nil {
            if tier == .premium || (tier == .pro && currentTier != .premium) {
                currentTier = tier
            }
        } else {
            // Revoked — recheck all entitlements
            await checkEntitlements()
        }
    }
}
