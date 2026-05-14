import Foundation
import Security

nonisolated final class KeychainSessionLocalDataSource: SessionLocalDataSourceProtocol {
    private let service: String
    private let account: String

    init(service: String = "me.veriffDemo.session", account: String = "current") {
        self.service = service
        self.account = account
    }

    func load() -> VerificationSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }

        return try? JSONDecoder().decode(VerificationSession.self, from: data)
    }

    func save(_ session: VerificationSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }

        let query = baseQuery()
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
    }
}
