import Foundation

/// REST API client for MedCare backend
actor APIService {
    static let shared = APIService()

    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?

    private init() {
        self.baseURL = URL(string: "https://api.medcare.app/v1")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func setAuthToken(_ token: String) {
        self.authToken = token
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: Encodable? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Auth Endpoints

    struct OTPRequest: Encodable {
        let phoneNumber: String
        let countryCode: String
    }

    struct OTPResponse: Decodable {
        let success: Bool
        let message: String
    }

    struct VerifyRequest: Encodable {
        let phoneNumber: String
        let otp: String
    }

    struct AuthResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let userId: String
    }

    func sendOTP(phone: String, countryCode: String) async throws -> OTPResponse {
        try await request("POST", path: "auth/send-otp", body: OTPRequest(phoneNumber: phone, countryCode: countryCode))
    }

    func verifyOTP(phone: String, otp: String) async throws -> AuthResponse {
        try await request("POST", path: "auth/verify-otp", body: VerifyRequest(phoneNumber: phone, otp: otp))
    }

    // MARK: - Episodes

    struct CreateEpisodeRequest: Encodable {
        let title: String
        let type: String
        let profileId: String
    }

    func getEpisodes() async throws -> [EpisodeDTO] {
        try await request("GET", path: "episodes")
    }

    func createEpisode(_ req: CreateEpisodeRequest) async throws -> EpisodeDTO {
        try await request("POST", path: "episodes", body: req)
    }

    func confirmEpisode(id: String) async throws -> EpisodeDTO {
        try await request("POST", path: "episodes/\(id)/confirm")
    }

    // MARK: - Doses

    struct LogDoseRequest: Encodable {
        let status: String
        let notes: String?
    }

    func logDose(id: String, status: String, notes: String? = nil) async throws -> DoseLogDTO {
        try await request("POST", path: "doses/\(id)/log", body: LogDoseRequest(status: status, notes: notes))
    }
}

// MARK: - DTOs

struct EpisodeDTO: Decodable {
    let id: String
    let title: String
    let type: String
    let status: String
    let doctorName: String?
    let diagnosis: String?
    let createdAt: String
}

struct DoseLogDTO: Decodable {
    let id: String
    let status: String
    let scheduledTime: String
    let actualTime: String?
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case unauthorized
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "Server error (code: \(code))"
        case .unauthorized: return "Session expired. Please login again."
        case .networkError(let error): return error.localizedDescription
        }
    }
}
