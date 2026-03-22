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

    // MARK: - HIU (Health Information User) — Health Record Import

    /// Data types that can be requested from a Health Information Provider (HIP)
    enum HealthDataType: String, CaseIterable, Codable, Identifiable {
        case prescriptions = "Prescription"
        case labReports = "DiagnosticReport"
        case dischargeSummaries = "DischargeSummary"
        case vitals = "OPConsultation"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .prescriptions: return "Prescriptions"
            case .labReports: return "Lab Reports"
            case .dischargeSummaries: return "Discharge Summaries"
            case .vitals: return "Vitals"
            }
        }

        var icon: String {
            switch self {
            case .prescriptions: return "doc.text.fill"
            case .labReports: return "flask.fill"
            case .dischargeSummaries: return "list.clipboard.fill"
            case .vitals: return "heart.text.square.fill"
            }
        }
    }

    /// Status of a consent request
    enum ConsentRequestStatus: String, Codable {
        case requested = "REQUESTED"
        case approved = "GRANTED"
        case denied = "DENIED"
        case expired = "EXPIRED"

        var displayName: String {
            switch self {
            case .requested: return "Requested"
            case .approved: return "Approved"
            case .denied: return "Denied"
            case .expired: return "Expired"
            }
        }

        var color: String {
            switch self {
            case .requested: return "orange"
            case .approved: return "green"
            case .denied: return "red"
            case .expired: return "gray"
            }
        }
    }

    /// A consent request for health data from a provider
    struct ConsentRequest: Codable, Identifiable {
        let id: String
        let requestId: String
        let providerName: String
        let dataTypes: [HealthDataType]
        let dateRangeStart: Date
        let dateRangeEnd: Date
        let status: ConsentRequestStatus
        let createdAt: Date
        let consentArtifactId: String?
    }

    /// An imported health record
    struct ImportedHealthRecord: Codable, Identifiable {
        let id: String
        let providerName: String
        let dataType: HealthDataType
        let recordDate: Date
        let importedAt: Date
        let title: String
        let summary: String
        let fhirResourceType: String
        let rawData: String // JSON string of FHIR resource
    }

    /// Provider search result
    struct HealthProvider: Codable, Identifiable {
        let id: String
        let name: String
        let city: String
        let type: String // hospital, clinic, lab, pharmacy
    }

    // MARK: - HIU Request Bodies

    private struct ConsentRequestBody: Encodable {
        let providerId: String
        let dataTypes: [String]
        let dateRangeStart: String
        let dateRangeEnd: String
    }

    // MARK: - HIU Response Models

    struct ConsentRequestResponse: Decodable {
        let requestId: String
        let status: String
        let message: String
    }

    struct ConsentStatusResponse: Decodable {
        let requestId: String
        let status: String
        let consentArtifactId: String?
    }

    struct HealthRecordsResponse: Decodable {
        let records: [FHIRRecord]
    }

    struct FHIRRecord: Decodable {
        let resourceType: String
        let id: String
        let title: String
        let date: String
        let summary: String
        let data: String
    }

    struct ProviderSearchResponse: Decodable {
        let providers: [HealthProvider]
    }

    // MARK: - HIU Methods

    /// Search for health information providers (hospitals, clinics, labs)
    func searchProviders(query: String) async throws -> [HealthProvider] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let response: ProviderSearchResponse = try await request("GET", path: "hiu/providers?q=\(encoded)")
        return response.providers
    }

    /// Request consent from a provider to access patient's health records
    func requestConsent(
        fromProvider providerId: String,
        forDataTypes dataTypes: [HealthDataType],
        dateRange: ClosedRange<Date>
    ) async throws -> ConsentRequestResponse {
        let formatter = ISO8601DateFormatter()
        let body = ConsentRequestBody(
            providerId: providerId,
            dataTypes: dataTypes.map(\.rawValue),
            dateRangeStart: formatter.string(from: dateRange.lowerBound),
            dateRangeEnd: formatter.string(from: dateRange.upperBound)
        )
        return try await request("POST", path: "hiu/consent-request", body: body)
    }

    /// Check the status of a consent request
    func checkConsentStatus(requestId: String) async throws -> ConsentStatusResponse {
        return try await request("GET", path: "hiu/consent-status/\(requestId)")
    }

    /// Fetch health records after consent has been granted
    func fetchHealthRecords(consentArtifactId: String) async throws -> [ImportedHealthRecord] {
        let response: HealthRecordsResponse = try await request(
            "GET",
            path: "hiu/health-records/\(consentArtifactId)"
        )

        let now = Date()
        return response.records.map { record in
            let recordDate = ISO8601DateFormatter().date(from: record.date) ?? now
            return ImportedHealthRecord(
                id: record.id,
                providerName: "", // Will be filled by caller
                dataType: HealthDataType(rawValue: record.resourceType) ?? .vitals,
                recordDate: recordDate,
                importedAt: now,
                title: record.title,
                summary: record.summary,
                fhirResourceType: record.resourceType,
                rawData: record.data
            )
        }
    }

    // MARK: - Local Consent Request Storage

    private static let consentRequestsKey = "mc_abdm_consent_requests"
    private static let importedRecordsKey = "mc_abdm_imported_records"

    nonisolated func savedConsentRequests() -> [ConsentRequest] {
        guard let data = UserDefaults.standard.data(forKey: Self.consentRequestsKey) else { return [] }
        return (try? JSONDecoder().decode([ConsentRequest].self, from: data)) ?? []
    }

    nonisolated func saveConsentRequest(_ request: ConsentRequest) {
        var requests = savedConsentRequests()
        if let idx = requests.firstIndex(where: { $0.requestId == request.requestId }) {
            requests[idx] = request
        } else {
            requests.append(request)
        }
        if let data = try? JSONEncoder().encode(requests) {
            UserDefaults.standard.set(data, forKey: Self.consentRequestsKey)
        }
    }

    nonisolated func savedImportedRecords() -> [ImportedHealthRecord] {
        guard let data = UserDefaults.standard.data(forKey: Self.importedRecordsKey) else { return [] }
        return (try? JSONDecoder().decode([ImportedHealthRecord].self, from: data)) ?? []
    }

    nonisolated func saveImportedRecords(_ records: [ImportedHealthRecord]) {
        var existing = savedImportedRecords()
        existing.append(contentsOf: records)
        if let data = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(data, forKey: Self.importedRecordsKey)
        }
    }
}
