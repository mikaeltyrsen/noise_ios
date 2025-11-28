import Foundation

/// A singleton class to manage storing and retrieving the APNs device token as a hex string in UserDefaults.
final class APNsDeviceTokenManager {
    
    /// Shared singleton instance
    static let shared = APNsDeviceTokenManager()
    
    /// UserDefaults key for storing the device token
    private let deviceTokenKey = "APNsDeviceTokenKey"
    
    /// Private initializer to prevent external instantiation
    private init() {}
    
    /// Stores the APNs device token as a hex string in UserDefaults
    /// - Parameter deviceToken: The device token data
    func saveDeviceToken(_ deviceToken: Data) {
        let hexString = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hexString, forKey: deviceTokenKey)
    }
    
    /// Retrieves the stored device token hex string from UserDefaults
    /// - Returns: The device token hex string if available, otherwise nil
    func getDeviceToken() -> String? {
        UserDefaults.standard.string(forKey: deviceTokenKey)
    }
    
    /// Clears the stored device token from UserDefaults
    func clearDeviceToken() {
        UserDefaults.standard.removeObject(forKey: deviceTokenKey)
    }
}
