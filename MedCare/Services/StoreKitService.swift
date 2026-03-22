import Foundation
import StoreKit

/// StoreKit 2 service for managing in-app subscriptions
/// Handles product loading, purchasing, entitlement checks, and transaction updates
@Observable
final class StoreKitService {
    static let shared = StoreKitService()

    var products: [Product] = []
    var purchasedSubscriptions: [Product] = []
    var currentPlan: SubscriptionPlan = .free
    var errorMessage: String?

    // MARK: - Subscription Plans

    enum SubscriptionPlan: String, CaseIterable, Sendable {
        case free, pro, premium

        var productID: String? {
            switch self {
            case .free: nil
            case .pro: "com.medcare.pro.yearly"
            case .premium: "com.medcare.premium.yearly"
            }
        }

        var displayName: String {
            switch self {
            case .free: "Free"
            case .pro: "Pro"
            case .premium: "Premium"
            }
        }

        var yearlyPrice: String {
            switch self {
            case .free: "Free"
            case .pro: "\u{20B9}1,499/year"
            case .premium: "\u{20B9}2,999/year"
            }
        }

        var features: [String] {
            switch self {
            case .free:
                return [
                    "1 profile",
                    "Up to 5 medicines",
                    "Dose reminders",
                    "Basic history",
                ]
            case .pro:
                return [
                    "Up to 3 profiles",
                    "Unlimited medicines",
                    "AI prescription extraction",
                    "AI health chat",
                    "Drug interaction alerts",
                    "Export reports",
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
                    "Family sharing",
                ]
            }
        }

        static func plan(for productID: String) -> SubscriptionPlan {
            switch productID {
            case "com.medcare.pro.yearly": return .pro
            case "com.medcare.premium.yearly": return .premium
            default: return .free
            }
        }
    }

    // MARK: - Product IDs

    private let productIDs: Set<String> = [
        "com.medcare.pro.yearly",
        "com.medcare.premium.yearly",
    ]

    private var updateListenerTask: Task<Void, Error>?

    private let planKey = "com.medcare.currentPlan"

    // MARK: - Init

    private init() {
        // Restore cached plan from UserDefaults as fallback
        if let cached = UserDefaults.standard.string(forKey: planKey),
           let plan = SubscriptionPlan(rawValue: cached) {
            currentPlan = plan
        }

        updateListenerTask = listenForTransactionUpdates()
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
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        errorMessage = nil

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePlanFromTransaction(transaction)
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            errorMessage = "Purchase is pending approval."
            return nil

        @unknown default:
            errorMessage = "Unknown purchase result."
            return nil
        }
    }

    // MARK: - Check Subscription Status

    func checkSubscriptionStatus() async {
        var highestPlan: SubscriptionPlan = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.revocationDate == nil {
                let plan = SubscriptionPlan.plan(for: transaction.productID)
                if plan == .premium {
                    highestPlan = .premium
                } else if plan == .pro && highestPlan != .premium {
                    highestPlan = .pro
                }
            }
        }

        currentPlan = highestPlan
        persistPlan(highestPlan)

        // Update purchased subscriptions list
        await updatePurchasedSubscriptions()
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }

    // MARK: - Helpers

    func product(for plan: SubscriptionPlan) -> Product? {
        guard let id = plan.productID else { return nil }
        return products.first { $0.id == id }
    }

    // MARK: - Private

    private func listenForTransactionUpdates() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self,
                      let transaction = try? self.checkVerified(result) else { continue }
                await self.updatePlanFromTransaction(transaction)
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

    private func updatePlanFromTransaction(_ transaction: Transaction) async {
        let plan = SubscriptionPlan.plan(for: transaction.productID)
        if transaction.revocationDate == nil {
            if plan == .premium || (plan == .pro && currentPlan != .premium) {
                currentPlan = plan
                persistPlan(plan)
            }
        } else {
            await checkSubscriptionStatus()
        }
    }

    private func updatePurchasedSubscriptions() async {
        var purchased: [Product] = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  transaction.revocationDate == nil else { continue }
            if let product = products.first(where: { $0.id == transaction.productID }) {
                purchased.append(product)
            }
        }
        purchasedSubscriptions = purchased
    }

    private func persistPlan(_ plan: SubscriptionPlan) {
        UserDefaults.standard.set(plan.rawValue, forKey: planKey)
    }
}
