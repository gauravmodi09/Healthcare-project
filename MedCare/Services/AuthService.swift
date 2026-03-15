import Foundation
import SwiftUI

/// Authentication service handling OTP-based login
@Observable
final class AuthService {
    var isAuthenticated = false
    var isLoading = false
    var currentUser: User?
    var errorMessage: String?

    private let keychainKey = "com.medcare.authToken"

    init() {
        checkExistingAuth()
    }

    private func checkExistingAuth() {
        // Check for stored token
        if let _ = KeychainHelper.read(key: keychainKey) {
            isAuthenticated = true
        }
    }

    func sendOTP(to phoneNumber: String, countryCode: String = "+91") async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // In production: call POST /auth/send-otp
        // For now, always succeed
    }

    func verifyOTP(_ otp: String, phoneNumber: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // In production: call POST /auth/verify-otp
        // For demo, accept any 6-digit OTP
        guard otp.count == 6 else {
            errorMessage = "Please enter a valid 6-digit OTP"
            return false
        }

        // Store token
        let mockToken = "jwt_\(UUID().uuidString)"
        KeychainHelper.save(key: keychainKey, value: mockToken)
        isAuthenticated = true
        return true
    }

    func logout() {
        KeychainHelper.delete(key: keychainKey)
        isAuthenticated = false
        currentUser = nil
    }
}

/// Simple Keychain helper
enum KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
