import Foundation

final class TokenStore {
    static let shared = TokenStore()

    private let userDefaults: UserDefaults
    private let tokenKey = "authToken"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> String? {
        userDefaults.string(forKey: tokenKey)
    }

    func save(_ token: String) {
        userDefaults.set(token, forKey: tokenKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: tokenKey)
    }
}
