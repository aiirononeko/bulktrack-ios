//
//  DeviceIdentifierKeychain.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/26.
//

import Foundation
import Security

public protocol DeviceIdentifierKeychainProtocol {
    func getDeviceIdentifier() -> String?
    func saveDeviceIdentifier(_ identifier: String) throws
    func deleteDeviceIdentifier() throws
}

public struct DeviceIdentifierKeychain: DeviceIdentifierKeychainProtocol {
    private let serviceIdentifier: String
    private let account = "deviceIdentifier"
    
    public init(serviceIdentifier: String = "com.bulktrack.deviceidentifier") {
        self.serviceIdentifier = serviceIdentifier
    }
    
    public func getDeviceIdentifier() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let identifier = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return identifier
    }
    
    public func saveDeviceIdentifier(_ identifier: String) throws {
        guard let data = identifier.data(using: .utf8) else {
            throw DeviceIdentifierError.invalidData
        }
        
        // 既存のアイテムを削除
        try? deleteDeviceIdentifier()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw DeviceIdentifierError.saveFailed
        }
    }
    
    public func deleteDeviceIdentifier() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw DeviceIdentifierError.deleteFailed
        }
    }
}

public enum DeviceIdentifierError: Error, LocalizedError {
    case invalidData
    case saveFailed
    case deleteFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidData: return "無効なデバイスIDデータです。"
        case .saveFailed: return "デバイスIDの保存に失敗しました。"
        case .deleteFailed: return "デバイスIDの削除に失敗しました。"
        }
    }
}
