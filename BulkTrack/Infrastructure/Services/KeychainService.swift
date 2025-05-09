//
//  KeychainService.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/10. // TODO: Update date if necessary
//

import Foundation
import Security

// Keychain操作に関するエラー
enum KeychainError: Error, LocalizedError {
    case dataEncodingError(String)
    case dataDecodingError(String)
    case unhandledError(status: OSStatus, message: String)
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .dataEncodingError(let entity): return "\(entity) のDataへのエンコードに失敗しました。"
        case .dataDecodingError(let entity): return "\(entity) のDataからのデコードに失敗しました。"
        case .unhandledError(let status, let message): return "キーチェーン操作エラー (コード: \(status)): \(message)"
        case .itemNotFound: return "指定されたアイテムはキーチェーンに見つかりませんでした。"
        }
    }
}

class KeychainService {

    private let keychainServiceIdentifier = "app.bulktrack.credentials"

    // MARK: - Generic Keychain Operations

    func saveData(_ data: Data, forAccount account: String, accessible: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: account
        ]

        // 既存アイテムの削除を試みる (Upsertのため)
        let statusDelete = SecItemDelete(query as CFDictionary)
        if statusDelete != errSecSuccess && statusDelete != errSecItemNotFound {
            // errSecItemNotFound は問題ない。それ以外のエラーはログに残すか、ハンドリング検討。
            print("Keychain: Failed to delete existing item before save for \(account), status: \(statusDelete). This might be an issue if the item should have been overwritten.")
            // throw KeychainError.unhandledError(status: statusDelete, message: "既存アイテムの削除に失敗しました。")
        }

        var newItemQuery = query
        newItemQuery[kSecValueData as String] = data
        newItemQuery[kSecAttrAccessible as String] = accessible // アクセス制御属性を設定

        let statusAdd = SecItemAdd(newItemQuery as CFDictionary, nil)
        guard statusAdd == errSecSuccess else {
            print("Keychain: Failed to add item for \(account), status: \(statusAdd)")
            throw KeychainError.unhandledError(status: statusAdd, message: "アイテムの追加に失敗しました。 Status: \(statusAdd)")
        }
        print("Keychain: Successfully saved data for account \(account).")
    }

    func getData(forAccount account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess {
            print("Keychain: Successfully retrieved data for account \(account).")
            return item as? Data
        } else if status == errSecItemNotFound {
            print("Keychain: No item found for account \(account).")
            return nil
        } else {
            print("Keychain: Failed to retrieve item for \(account), status: \(status)")
            throw KeychainError.unhandledError(status: status, message: "アイテムの取得に失敗しました。 Status: \(status)")
        }
    }

    func deleteData(forAccount account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Keychain: Failed to delete item for \(account), status: \(status)")
            throw KeychainError.unhandledError(status: status, message: "アイテムの削除に失敗しました。 Status: \(status)")
        }
        print("Keychain: Successfully deleted data for account \(account) (or it didn't exist).")
    }

    // MARK: - Convenience Methods for Tokens and Device ID

    // 特定のキー (アカウント名) で文字列を保存
    func saveString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataEncodingError("文字列 (キー: \(key))")
        }
        try saveData(data, forAccount: key)
    }

    // 特定のキー (アカウント名) で文字列を取得
    func getString(forKey key: String) throws -> String? {
        guard let data = try getData(forAccount: key) else {
            return nil
        }
        guard let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataDecodingError("文字列 (キー: \(key))")
        }
        return value
    }
    
    // アプリ内で使用するKeychainのキー定義 (例)
    enum KeychainKeys {
        static let deviceId = "app.bulktrack.deviceId"
        static let accessToken = "app.bulktrack.deviceAccessToken"
        static let refreshToken = "app.bulktrack.deviceRefreshToken"
    }
}
