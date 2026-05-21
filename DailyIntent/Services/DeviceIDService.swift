import Foundation

/// 匿名设备标识，用于 Worker 端限流（非账号体系）。
final class DeviceIDService {
    static let shared = DeviceIDService()

    private let keychainKey = "device_uuid"
    private let fallbackDefaultsKey = "device_uuid_fallback"

    var deviceID: String {
        get {
            if let existing = try? KeychainService.shared.read(account: keychainKey),
               !existing.isEmpty {
                return existing
            }
            if let fallback = UserDefaults.standard.string(forKey: fallbackDefaultsKey),
               !fallback.isEmpty {
                return fallback
            }
            let newID = UUID().uuidString
            if (try? KeychainService.shared.save(newID, account: keychainKey)) != nil {
                UserDefaults.standard.removeObject(forKey: fallbackDefaultsKey)
            } else {
                UserDefaults.standard.set(newID, forKey: fallbackDefaultsKey)
            }
            return newID
        }
    }

    private init() {}
}
