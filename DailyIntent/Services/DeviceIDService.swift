import Foundation

/// 匿名设备标识，用于 Worker 端限流（非账号体系）。
final class DeviceIDService {
    static let shared = DeviceIDService()

    private let keychainKey = "device_uuid"

    var deviceID: String {
        get {
            if let existing = try? KeychainService.shared.read(account: keychainKey),
               !existing.isEmpty {
                return existing
            }
            let newID = UUID().uuidString
            try? KeychainService.shared.save(newID, account: keychainKey)
            return newID
        }
    }

    private init() {}
}
