import Foundation

/// ABDM (Ayushman Bharat Digital Mission) service client
/// Handles ABHA ID linking, OTP verification, and profile retrieval
actor ABDMService {
    static let shared = ABDMService()

    private let baseURL: URL
    private let session: URLSession

    private init() {
        self.baseURL = URL(string: "https://api.medcare.app/v1/abdm")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Models

    struct ABHACreationResponse: Decodable {
        let txnId: String
        let message: String
    }

    struct ABHAVerifyResponse: Decodable {
        let abhaNumber: String
        let abhaAddress: String
        let name: String
        let mobile: String
        let healthIdNumber: String
        let token: String
    }

    struct ABHAProfile: Decodable {
        let abhaNumber: String
        let abhaAddress: String
        let name: String
        let gender: String
        let dateOfBirth: String
        let mobile: String
        let address: String
        let kycVerified: Bool
    }

    enum ABDMError: LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int)
        case noAuthToken

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from ABDM service"
            case .httpError(let code):
                return "ABDM request failed with status \(code)"
            case .noAuthToken:
                return "Authentication required. Please log in first."
            }
        }
    }

    // MARK: - Private Helpers

    private func authToken() async throws -> String {
        guard let token = UserDefaults.standard.string(forKey: "mc_auth_token") else {
            throw ABDMError.noAuthToken
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

        let token = try await authToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ABDMError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ABDMError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Link ABHA via Aadhaar

    struct LinkABHARequest: Encodable {
        let aadhaarNumber: String
        let method: String = "aadhaar"
    }

    func linkABHA(aadhaarNumber: String) async throws -> ABHACreationResponse {
        let body = LinkABHARequest(aadhaarNumber: aadhaarNumber)
        return try await request("POST", path: "create-abha", body: body)
    }

    // MARK: - Verify OTP

    struct VerifyOTPRequest: Encodable {
        let txnId: String
        let otp: String
    }

    func verifyOTP(txnId: String, otp: String) async throws -> ABHAVerifyResponse {
        let body = VerifyOTPRequest(txnId: txnId, otp: otp)
        let response: ABHAVerifyResponse = try await request("POST", path: "verify-otp", body: body)

        // Store ABHA ID locally
        UserDefaults.standard.set(response.abhaNumber, forKey: "mc_abha_number")
        UserDefaults.standard.set(response.abhaAddress, forKey: "mc_abha_address")

        return response
    }

    // MARK: - Get Profile

    func getProfile(abhaId: String) async throws -> ABHAProfile {
        return try await request("GET", path: "profile/\(abhaId)")
    }

    // MARK: - Status Helpers

    nonisolated var isLinked: Bool {
        UserDefaults.standard.string(forKey: "mc_abha_number") != nil
    }

    nonisolated var storedABHANumber: String? {
        UserDefaults.standard.string(forKey: "mc_abha_number")
    }

    nonisolated var storedABHAAddress: String? {
        UserDefaults.standard.string(forKey: "mc_abha_address")
    }

    nonisolated func unlinkABHA() {
        UserDefaults.standard.removeObject(forKey: "mc_abha_number")
        UserDefaults.standard.removeObject(forKey: "mc_abha_address")
    }
}
