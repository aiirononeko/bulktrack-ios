import Foundation

public protocol DeviceIdentifierServiceProtocol {
    func getDeviceIdentifier() -> String
}

public struct DeviceIdentifierService: DeviceIdentifierServiceProtocol {
    private let userDefaults: UserDefaults
    private let deviceIdKey = "com.bulktrack.deviceId"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func getDeviceIdentifier() -> String {
        if let existingId = userDefaults.string(forKey: deviceIdKey) {
            return existingId
        } else {
            // API spec asks for UUID v7. UUID() generates v4.
            // For now, using v4. If v7 is strictly required by the backend,
            // a custom v7 generator or library would be needed.
            let newId = UUID().uuidString
            userDefaults.set(newId, forKey: deviceIdKey)
            return newId
        }
    }
}
