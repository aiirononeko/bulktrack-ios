//
//  ActivationService.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import Foundation
import Security

class ActivationService {

    private let userDefaults = UserDefaults.standard
    private let deviceIdKey = "app.bulktrack.deviceId"
    private let hasActivatedKey = "app.bulktrack.hasActivatedDevice"
    private let keychainServiceIdentifier = "app.bulktrack.credentials"

    func activateDeviceIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        if userDefaults.bool(forKey: hasActivatedKey) {
            print("Device already activated or activation attempt was made.")
            // TODO: ここで既存のトークンが有効かどうかのチェックも将来的に入れると良い
            completion(.success(()))
            return
        }
        performDeviceActivation(completion: completion)
    }

    private func performDeviceActivation(completion: @escaping (Result<Void, Error>) -> Void) {
        var deviceIdString: String

        // 1. KeychainからdeviceIdを取得、なければ生成して保存
        do {
            if let existingDeviceId = try getDeviceIdFromKeychain() {
                deviceIdString = existingDeviceId
                print("Existing Device ID found in Keychain: \(deviceIdString)")
            } else {
                let newDeviceId = UUID().uuidString
                try saveDeviceIdToKeychain(deviceId: newDeviceId)
                deviceIdString = newDeviceId
                print("New Device ID generated and saved to Keychain: \(deviceIdString)")
            }
        } catch {
            print("Keychain error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        guard let url = URL(string: APIConfig.baseURL + "/v1/auth/device") else {
            print("Invalid API URL for device activation")
            completion(.failure(ActivationError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceIdString, forHTTPHeaderField: "X-Device-Id")
        // request.httpBody = ... // 必要に応じてリクエストボディを設定

        print("Attempting device activation with URL: \(url) and Device ID: \(deviceIdString)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Request Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response")
                completion(.failure(ActivationError.invalidResponse))
                return
            }

            print("Device Activation API Response Status Code: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                // TODO: dataからエラーメッセージを読み取る
                if let responseData = data, let errorString = String(data: responseData, encoding: .utf8) {
                    print("API Error Response: \(errorString)")
                }
                completion(.failure(ActivationError.apiError(statusCode: httpResponse.statusCode, message: "Activation API Error")))
                return
            }

            guard let responseData = data else {
                print("API Response data is nil.")
                completion(.failure(ActivationError.invalidResponse)) // または別の適切なエラー
                return
            }

            // ↓↓↓ このデバッグコードを追加 ↓↓↓
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("Raw API Response JSON: \(responseString)")
            } else {
                print("Failed to convert API response data to string.")
            }
            // ↑↑↑ このデバッグコードを追加 ↑↑↑

            do {
                let tokens = try JSONDecoder().decode(TokenResponse.self, from: responseData)
                print("Successfully decoded tokens. Access token expires in: \(tokens.expiresIn) seconds.")

                // アクセストークンをKeychainに保存
                try self.saveTokenToKeychain(token: tokens.accessToken, account: "deviceAccessToken")
                // リフレッシュトークンをKeychainに保存
                try self.saveTokenToKeychain(token: tokens.refreshToken, account: "deviceRefreshToken")
                
                print("Device tokens saved to Keychain.")
                self.userDefaults.set(true, forKey: self.hasActivatedKey)
                completion(.success(()))

            } catch let decodingError as DecodingError {
                print("JSON Decoding Error: \(decodingError.localizedDescription)")
                // decodingError の詳細を出力するとデバッグに役立つ
                switch decodingError {
                case .typeMismatch(let type, let context): print("Type mismatch: \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context): print("Value not found: \(type), context: \(context.debugDescription)")
                case .keyNotFound(let key, let context): print("Key not found: \(key), context: \(context.debugDescription)")
                case .dataCorrupted(let context): print("Data corrupted: \(context.debugDescription)")
                @unknown default: print("Unknown decoding error")
                }
                completion(.failure(ActivationError.dataDecodingError))
            } catch {
                print("An unexpected error occurred during token processing: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }

    // MARK: - Keychain Access (OS Standard API)
    // これらのKeychainメソッドは基本的な実装のプレースホルダです。
    // より堅牢なエラー処理や、属性（kSecAttrAccessibleなど）の適切な設定が必要です。

    private func saveDeviceIdToKeychain(deviceId: String) throws {
        guard let data = deviceId.data(using: .utf8) else {
            throw ActivationError.keychainError(message: "Failed to encode deviceId to Data")
        }
        try saveDataToKeychain(data: data, account: deviceIdKey)
    }

    private func getDeviceIdFromKeychain() throws -> String? {
        guard let data = try getDataFromKeychain(account: deviceIdKey) else {
            return nil
        }
        guard let deviceId = String(data: data, encoding: .utf8) else {
            throw ActivationError.keychainError(message: "Failed to decode deviceId from Data")
        }
        return deviceId
    }
    
    // トークン保存用の汎用メソッド（例）
    func saveTokenToKeychain(token: String, account: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw ActivationError.keychainError(message: "Failed to encode token to Data for account: \(account)")
        }
        try saveDataToKeychain(data: data, account: account)
    }

    // トークン取得用の汎用メソッド（例）
    func getTokenFromKeychain(account: String) throws -> String? {
        guard let data = try getDataFromKeychain(account: account) else {
            return nil
        }
        guard let token = String(data: data, encoding: .utf8) else {
            throw ActivationError.keychainError(message: "Failed to decode token from Data for account: \(account)")
        }
        return token
    }

    private func saveDataToKeychain(data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceIdentifier,
            kSecAttrAccount as String: account
        ]

        // まず既存のアイテムを削除しようと試みる (update or add のため)
        let statusDelete = SecItemDelete(query as CFDictionary)
        if statusDelete != errSecSuccess && statusDelete != errSecItemNotFound {
            // errSecItemNotFound は問題ない (元々存在しなかっただけ)
            // それ以外のエラーは問題
            // print("Keychain: Failed to delete existing item for \(account), status: \(statusDelete)")
            // throw ActivationError.keychainError(message: "Failed to delete existing keychain item. Status: \(statusDelete)")
        }

        var newItemQuery = query
        newItemQuery[kSecValueData as String] = data
        // アクセス制御を設定 (例: デバイスがロック解除されているときのみアクセス可能)
        // newItemQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let statusAdd = SecItemAdd(newItemQuery as CFDictionary, nil)
        guard statusAdd == errSecSuccess else {
            print("Keychain: Failed to add item for \(account), status: \(statusAdd)")
            throw ActivationError.keychainError(message: "Failed to add keychain item. Status: \(statusAdd)")
        }
        print("Keychain: Successfully saved data for account \(account).")
    }

    private func getDataFromKeychain(account: String) throws -> Data? {
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
            throw ActivationError.keychainError(message: "Failed to retrieve keychain item. Status: \(status)")
        }
    }
    
    // Keychainからアイテムを削除するメソッド（必要に応じて）
    // private func deleteDataFromKeychain(account: String) throws {
    //     let query: [String: Any] = [
    //         kSecClass as String: kSecClassGenericPassword,
    //         kSecAttrService as String: keychainServiceIdentifier,
    //         kSecAttrAccount as String: account
    //     ]
    //     let status = SecItemDelete(query as CFDictionary)
    //     if status != errSecSuccess && status != errSecItemNotFound {
    //         throw ActivationError.keychainError(message: "Failed to delete keychain item. Status: \(status)")
    //     }
    //     print("Keychain: Successfully deleted data for account \(account) (or it didn't exist).")
    // }
}

// エラー型を定義
enum ActivationError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case keychainError(message: String)
    case dataDecodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なAPI URLです。"
        case .invalidResponse: return "サーバーから無効なレスポンスを受け取りました。"
        case .apiError(let statusCode, let message): return "APIエラー (コード: \(statusCode)): \(message)"
        case .keychainError(let message): return "キーチェーン操作エラー: \(message)"
        case .dataDecodingError: return "データのデコードに失敗しました。"
        }
    }
}

// TokenResponse構造体をファイルの下部 (ActivationServiceクラスの外、ActivationError enum の後など) に追加
struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    // CodingKeys enum は実際のレスポンスに合わせて不要なので削除
    // enum CodingKeys: String, CodingKey {
    //     case accessToken = "access_token"
    //     case refreshToken = "refresh_token"
    //     case expiresIn = "expires_in"
    // }
}
