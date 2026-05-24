import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let service = "com.dailyquest.app"
    private let defaultAccount = "deepseek_api_key"

    var hasAPIKey: Bool {
        (try? read()) != nil
    }

    func save(_ key: String, account: String? = nil) throws {
        let data = Data(key.utf8)
        try deleteIfExists(account: account)
        let acct = account ?? defaultAccount
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: acct,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    func read(account: String? = nil) throws -> String? {
        let acct = account ?? defaultAccount
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: acct,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unhandled(status)
        }
        return string
    }

    func delete(account: String? = nil) throws {
        try deleteIfExists(account: account)
    }

    private func deleteIfExists(account: String? = nil) throws {
        let acct = account ?? defaultAccount
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: acct
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case unhandled(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unhandled(let status):
            return "Keychain error: \(status)"
        }
    }
}
