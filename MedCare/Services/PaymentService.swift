import Foundation

/// Razorpay payment service client
/// Handles order creation, payment verification, and subscription management
actor PaymentService {
    static let shared = PaymentService()

    private let baseURL: URL
    private let session: URLSession

    /// Razorpay key ID — used by the checkout SDK on the client side
    nonisolated let razorpayKeyId: String = {
        Bundle.main.infoDictionary?["RAZORPAY_KEY_ID"] as? String ?? ""
    }()

    private init() {
        self.baseURL = URL(string: "https://api.medcare.app/v1/payments")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Models

    struct Order: Decodable {
        let id: String
        let amount: Int
        let currency: String
        let receipt: String
        let status: String
    }

    struct PaymentVerification: Decodable {
        let verified: Bool
        let orderId: String
        let paymentId: String
    }

    struct Subscription: Decodable {
        let id: String
        let planId: String
        let customerId: String
        let status: String
        let shortUrl: String
    }

    struct QRCode: Decodable {
        let id: String
        let imageUrl: String
        let amount: Int
        let description: String
        let status: String
    }

    struct PaymentHistoryResponse: Decodable {
        let payments: [PaymentRecord]
        let total: Int
    }

    struct PaymentRecord: Decodable, Identifiable {
        let id: String
        let amount: Int
        let currency: String
        let status: String
        let description: String?
        let createdAt: Date?
    }

    enum PaymentError: LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int)
        case noAuthToken
        case verificationFailed
        case razorpayNotConfigured

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from payment service"
            case .httpError(let code):
                return "Payment request failed with status \(code)"
            case .noAuthToken:
                return "Authentication required. Please log in first."
            case .verificationFailed:
                return "Payment verification failed. Please contact support."
            case .razorpayNotConfigured:
                return "Payment gateway is not configured"
            }
        }
    }

    // MARK: - Private Helpers

    private func authToken() throws -> String {
        guard let token = UserDefaults.standard.string(forKey: "mc_auth_token") else {
            throw PaymentError.noAuthToken
        }
        return token
    }

    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: Encodable? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try authToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Create Order

    struct CreateOrderRequest: Encodable {
        let amount: Double
        let currency: String
    }

    func createOrder(amount: Double, currency: String = "INR") async throws -> Order {
        let body = CreateOrderRequest(amount: amount, currency: currency)
        return try await request("POST", path: "create-order", body: body)
    }

    // MARK: - Initiate Payment (returns data needed for Razorpay SDK)

    struct RazorpayCheckoutParams {
        let orderId: String
        let amount: Int
        let currency: String
        let keyId: String
        let merchantName: String
        let description: String
    }

    nonisolated func buildCheckoutParams(order: Order, description: String = "MedCare Subscription") -> RazorpayCheckoutParams {
        RazorpayCheckoutParams(
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
            keyId: razorpayKeyId,
            merchantName: "MedCare",
            description: description
        )
    }

    // MARK: - Verify Payment

    struct VerifyRequest: Encodable {
        let orderId: String
        let paymentId: String
        let signature: String
    }

    func verifyPayment(paymentId: String, orderId: String, signature: String) async throws -> PaymentVerification {
        let body = VerifyRequest(orderId: orderId, paymentId: paymentId, signature: signature)
        let result: PaymentVerification = try await request("POST", path: "verify", body: body)

        if !result.verified {
            throw PaymentError.verificationFailed
        }

        return result
    }

    // MARK: - Subscription Management

    struct SubscribeRequest: Encodable {
        let planId: String
        let customerId: String?
    }

    func createSubscription(planId: String, customerId: String? = nil) async throws -> Subscription {
        let body = SubscribeRequest(planId: planId, customerId: customerId)
        return try await request("POST", path: "subscribe", body: body)
    }

    struct CancelRequest: Encodable {
        let subscriptionId: String
    }

    func cancelSubscription(subscriptionId: String) async throws {
        // Cancel via direct API call — no response body needed
        let url = baseURL.appendingPathComponent("subscribe/\(subscriptionId)/cancel")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = try authToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.invalidResponse
        }
    }

    // MARK: - Payment History

    func getPaymentHistory() async throws -> PaymentHistoryResponse {
        return try await request("GET", path: "history")
    }
}

// MARK: - Plan Definitions

enum PaymentPlan: String, CaseIterable, Identifiable {
    case free
    case pro
    case premium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }

    var annualPrice: Int {
        switch self {
        case .free: return 0
        case .pro: return 599
        case .premium: return 999
        }
    }

    var priceLabel: String {
        switch self {
        case .free: return "Free"
        case .pro: return "\u{20B9}599/yr"
        case .premium: return "\u{20B9}999/yr"
        }
    }

    var razorpayPlanId: String? {
        switch self {
        case .free: return nil
        case .pro: return "plan_medcare_pro_annual"
        case .premium: return "plan_medcare_premium_annual"
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
                "AI prescription scan",
                "AI health chat",
                "Drug interaction alerts",
                "Export reports"
            ]
        case .premium:
            return [
                "Up to 5 profiles",
                "Unlimited medicines",
                "All Pro features",
                "ABHA integration",
                "Doctor teleconsult",
                "Priority support"
            ]
        }
    }

    var accentColor: String {
        switch self {
        case .free: return "textSecondary"
        case .pro: return "primaryTeal"
        case .premium: return "warning"
        }
    }
}
