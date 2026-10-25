import Foundation
import Security

// the apple user id is stable for this app but it is still an identity, so it
// goes in the keychain rather than in defaults. never logged.
enum Keychain {
    private static let service = "com.rizkyinsania.moop.apple-user"

    static var appleUser: String? {
        get {
            var out: AnyObject?
            let query = base.merging([kSecReturnData as String: true]) { $1 }
            guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
                  let data = out as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            SecItemDelete(base as CFDictionary)
            guard let newValue else { return }
            let add = base.merging([kSecValueData as String: Data(newValue.utf8)]) { $1 }
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    private static let base: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: "user",
    ]
}
