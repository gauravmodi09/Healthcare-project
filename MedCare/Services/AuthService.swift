import Foundation
import SwiftUI

/// Authentication service handling OTP-based login
@Observable
final class AuthService {
    var isAuthenticated = false
    var isLoading = false
    var currentUser: User?
    var errorMessage: String?
    var authenticatedPhone: String?

    private let keychainKey = "com.medcare.authToken"

    init() {
        checkExistingAuth()
    }

    private func checkExistingAuth() {
        // Check for stored token
        if let token = KeychainHelper.read(key: keychainKey) {
            isAuthenticated = true
            // Extract phone from JWT payload
            let parts = token.split(separator: ".")
            if parts.count >= 2, let data = Data(base64Encoded: String(parts[1]) + "=="),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sub = json["sub"] as? String {
                authenticatedPhone = sub
            }
        }
    }

    /// The fixed demo OTP code. Displayed to users on the OTP screen.
    static let demoOTP = "123456"

    func sendOTP(to phoneNumber: String, countryCode: String = "+91") async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Simulate network latency
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // MARK: - Production SMS Integration Point
        // In production, replace this with a real SMS provider call:
        //   let response = try await MSG91Service.sendOTP(
        //       phone: "\(countryCode)\(phoneNumber)",
        //       templateId: "YOUR_MSG91_TEMPLATE_ID"
        //   )
        //   guard response.success else { throw AuthError.otpSendFailed }
    }

    func verifyOTP(_ otp: String, phoneNumber: String) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Simulate network latency
        try await Task.sleep(nanoseconds: 1_000_000_000)

        guard otp.count == 6 else {
            errorMessage = "Please enter a valid 6-digit OTP"
            return false
        }

        // MARK: - Production OTP Verification Point
        // In production, replace this with a real verification call:
        //   let response = try await MSG91Service.verifyOTP(
        //       phone: "\(countryCode)\(phoneNumber)",
        //       otp: otp
        //   )
        //   guard response.verified else {
        //       errorMessage = "Invalid OTP. Please try again."
        //       return false
        //   }

        // Demo mode: only accept the fixed demo OTP
        guard otp == Self.demoOTP else {
            errorMessage = "Invalid OTP. Hint: use \(Self.demoOTP)"
            return false
        }

        // Generate a realistic-looking JWT token (header.payload.signature)
        let header = Data("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".utf8).base64EncodedString()
        let payload = Data("{\"sub\":\"\(phoneNumber)\",\"iat\":\(Int(Date().timeIntervalSince1970)),\"exp\":\(Int(Date().timeIntervalSince1970) + 86400)}".utf8).base64EncodedString()
        let signature = Data(UUID().uuidString.utf8).base64EncodedString()
        let token = "\(header).\(payload).\(signature)"

        KeychainHelper.save(key: keychainKey, value: token)
        authenticatedPhone = phoneNumber
        isAuthenticated = true
        return true
    }

    func logout() {
        KeychainHelper.delete(key: keychainKey)
        isAuthenticated = false
        currentUser = nil
        authenticatedPhone = nil
        // Clear role-related storage so role selection shows on next login
        UserDefaults.standard.removeObject(forKey: "mc_user_role")
        UserDefaults.standard.removeObject(forKey: "mc_role_setup_complete")
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
