import XCTest
@testable import MedCare

final class ServiceTests: XCTestCase {

    // MARK: - Auth Service Tests

    func testAuthServiceInitialState() {
        let authService = AuthService()
        XCTAssertFalse(authService.isLoading)
        XCTAssertNil(authService.errorMessage)
        XCTAssertNil(authService.currentUser)
    }

    func testOTPValidation() async throws {
        let authService = AuthService()

        // Short OTP should fail
        let shortResult = try await authService.verifyOTP("123", phoneNumber: "9876543210")
        XCTAssertFalse(shortResult)
        XCTAssertNotNil(authService.errorMessage)

        // 6-digit OTP should succeed
        let validResult = try await authService.verifyOTP("123456", phoneNumber: "9876543210")
        XCTAssertTrue(validResult)
        XCTAssertTrue(authService.isAuthenticated)
    }

    func testLogout() async throws {
        let authService = AuthService()
        let _ = try await authService.verifyOTP("123456", phoneNumber: "9876543210")
        XCTAssertTrue(authService.isAuthenticated)

        authService.logout()
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }

    // MARK: - Keychain Helper Tests

    func testKeychainSaveAndRead() {
        let key = "test_key_\(UUID().uuidString)"
        let value = "test_value"

        KeychainHelper.save(key: key, value: value)
        let retrieved = KeychainHelper.read(key: key)
        XCTAssertEqual(retrieved, value)

        // Cleanup
        KeychainHelper.delete(key: key)
        XCTAssertNil(KeychainHelper.read(key: key))
    }

    // MARK: - AI Extraction Service Tests

    func testAIExtractionServiceInitialState() {
        let service = AIExtractionService()
        XCTAssertFalse(service.isExtracting)
        XCTAssertEqual(service.extractionProgress, 0)
    }

    func testExtractionResult() async throws {
        let service = AIExtractionService()

        let result = try await service.extractFromImages(
            prescriptionImage: nil,
            medicineImages: []
        )

        XCTAssertFalse(result.doctorName.value.isEmpty)
        XCTAssertFalse(result.medicines.isEmpty)
        XCTAssertEqual(result.medicines.count, 3)
        XCTAssertGreaterThan(result.overallConfidence, 0.5)

        // Check confidence scoring
        let firstMed = result.medicines[0]
        XCTAssertGreaterThan(firstMed.brandName.confidence, 0.8)
    }

    func testExtractionLowConfidenceDetection() async throws {
        let service = AIExtractionService()
        let result = try await service.extractFromImages(
            prescriptionImage: nil,
            medicineImages: []
        )

        // The third medicine (Montek LC) should have low confidence fields
        let thirdMed = result.medicines[2]
        XCTAssertTrue(thirdMed.hasLowConfidenceField)
    }

    // MARK: - Notification Service Tests

    func testNotificationServiceSingleton() {
        let service1 = NotificationService.shared
        let service2 = NotificationService.shared
        XCTAssertTrue(service1 === service2)
    }

    // MARK: - API Error Tests

    func testAPIErrorDescriptions() {
        XCTAssertEqual(APIError.invalidResponse.errorDescription, "Invalid server response")
        XCTAssertEqual(APIError.unauthorized.errorDescription, "Session expired. Please login again.")
        XCTAssertNotNil(APIError.httpError(statusCode: 500).errorDescription)
    }
}
