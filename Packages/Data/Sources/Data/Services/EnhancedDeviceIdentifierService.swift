//
//  EnhancedDeviceIdentifierService.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/26.
//

import Foundation
import Domain

public struct EnhancedDeviceIdentifierService: DeviceIdentifierServiceProtocol {
    private let keychainStorage: DeviceIdentifierKeychainProtocol
    private let userDefaults: UserDefaults
    private let deviceIdKey = "com.bulktrack.deviceId"
    
    public init(
        keychainStorage: DeviceIdentifierKeychainProtocol = DeviceIdentifierKeychain(),
        userDefaults: UserDefaults = .standard
    ) {
        self.keychainStorage = keychainStorage
        self.userDefaults = userDefaults
    }
    
    public func getDeviceIdentifier() -> String {
        // 1. Keychain から取得を試行（最優先）
        if let keychainId = keychainStorage.getDeviceIdentifier() {
            return keychainId
        }
        
        // 2. UserDefaults から取得（後方互換性）
        if let userDefaultsId = userDefaults.string(forKey: deviceIdKey) {
            // Keychain に移行
            do {
                try keychainStorage.saveDeviceIdentifier(userDefaultsId)
                // 移行成功後、UserDefaults から削除（任意）
                userDefaults.removeObject(forKey: deviceIdKey)
                return userDefaultsId
            } catch {
                // Keychain 保存に失敗した場合、UserDefaults の値をそのまま使用
                print("Failed to migrate device ID to Keychain: \(error)")
                return userDefaultsId
            }
        }
        
        // 3. 新規生成
        let newId = UUID().uuidString
        
        do {
            try keychainStorage.saveDeviceIdentifier(newId)
        } catch {
            // Keychain 保存に失敗した場合、UserDefaults にフォールバック
            print("Failed to save device ID to Keychain: \(error)")
            userDefaults.set(newId, forKey: deviceIdKey)
        }
        
        return newId
    }
}
