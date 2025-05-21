////
////  ActivationService.swift
////  BulkTrack
////
////  Created by Ryota Katada on 2025/05/09.
////
//
//import Foundation
//import Security
//
//class ActivationService {
//
//    private let userDefaults = UserDefaults.standard
//    private let keychainService = KeychainService()
//    
//    private let hasActivatedKey = "app.bulktrack.hasActivatedDevice"
//
//    func activateDeviceIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
//        // userDefaults.set(false, forKey: hasActivatedKey) // ← 強制的にアクティベーションを実行するためのテストコード
//
//        if userDefaults.bool(forKey: hasActivatedKey) {
//            print("Device already activated or activation attempt was made.")
//            completion(.success(()))
//            return
//        }
//        performDeviceActivation(completion: completion)
//    }
//
//    private func performDeviceActivation(completion: @escaping (Result<Void, Error>) -> Void) {
//        var deviceIdString: String
//
//        do {
//            if let existingDeviceId = try keychainService.getString(forKey: KeychainService.KeychainKeys.deviceId) {
//                deviceIdString = existingDeviceId
//                print("Existing Device ID found in Keychain: \(deviceIdString)")
//            } else {
//                let newDeviceId = UUID().uuidString
//                try keychainService.saveString(newDeviceId, forKey: KeychainService.KeychainKeys.deviceId)
//                deviceIdString = newDeviceId
//                print("New Device ID generated and saved to Keychain: \(deviceIdString)")
//            }
//        } catch let error as KeychainError {
//            print("Keychain error during device ID handling: \(error.localizedDescription)")
//            completion(.failure(error))
//            return
//        } catch {
//            print("Unexpected error during device ID handling: \(error.localizedDescription)")
//            completion(.failure(error))
//            return
//        }
//
//        guard let url = URL(string: APIConfig.baseURL + "/v1/auth/device") else {
//            print("Invalid API URL for device activation")
//            completion(.failure(ActivationError.invalidURL))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(deviceIdString, forHTTPHeaderField: "X-Device-Id")
//        // request.httpBody = ... // 必要に応じてリクエストボディを設定
//
//        print("Attempting device activation with URL: \(url) and Device ID: \(deviceIdString)")
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("API Request Error: \(error.localizedDescription)")
//                completion(.failure(error))
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("Invalid HTTP response")
//                completion(.failure(ActivationError.invalidResponse))
//                return
//            }
//
//            print("Device Activation API Response Status Code: \(httpResponse.statusCode)")
//
//            guard (200...299).contains(httpResponse.statusCode) else {
//                // TODO: dataからエラーメッセージを読み取る
//                if let responseData = data, let errorString = String(data: responseData, encoding: .utf8) {
//                    print("API Error Response: \(errorString)")
//                }
//                completion(.failure(ActivationError.apiError(statusCode: httpResponse.statusCode, message: "Activation API Error")))
//                return
//            }
//
//            guard let responseData = data else {
//                print("API Response data is nil.")
//                completion(.failure(ActivationError.invalidResponse)) // または別の適切なエラー
//                return
//            }
//
//            // ↓↓↓ このデバッグコードを追加 ↓↓↓
//            if let responseString = String(data: responseData, encoding: .utf8) {
//                print("Raw API Response JSON: \(responseString)")
//            } else {
//                print("Failed to convert API response data to string.")
//            }
//            // ↑↑↑ このデバッグコードを追加 ↑↑↑
//
//            do {
//                let tokens = try JSONDecoder().decode(TokenResponse.self, from: responseData)
//                print("Successfully decoded tokens. Access token expires in: \(tokens.expiresIn) seconds.")
//
//                try self.keychainService.saveString(tokens.accessToken, forKey: KeychainService.KeychainKeys.accessToken)
//                try self.keychainService.saveString(tokens.refreshToken, forKey: KeychainService.KeychainKeys.refreshToken)
//                
//                print("Device tokens saved to Keychain.")
//                self.userDefaults.set(true, forKey: self.hasActivatedKey)
//                completion(.success(()))
//
//            } catch let decodingError as DecodingError {
//                print("JSON Decoding Error: \(decodingError.localizedDescription)")
//                // decodingError の詳細を出力するとデバッグに役立つ
//                switch decodingError {
//                case .typeMismatch(let type, let context): print("Type mismatch: \(type), context: \(context.debugDescription)")
//                case .valueNotFound(let type, let context): print("Value not found: \(type), context: \(context.debugDescription)")
//                case .keyNotFound(let key, let context): print("Key not found: \(key), context: \(context.debugDescription)")
//                case .dataCorrupted(let context): print("Data corrupted: \(context.debugDescription)")
//                @unknown default: print("Unknown decoding error")
//                }
//                completion(.failure(ActivationError.dataDecodingError))
//            } catch let error as KeychainError {
//                print("Keychain error during token saving: \(error.localizedDescription)")
//                completion(.failure(error))
//            } catch {
//                print("An unexpected error occurred during token processing: \(error.localizedDescription)")
//                completion(.failure(error))
//            }
//        }
//        task.resume()
//    }
//
//    // MARK: - Keychain Access (OS Standard API)
//    // これらのKeychainメソッドは基本的な実装のプレースホルダです。
//    // より堅牢なエラー処理や、属性（kSecAttrAccessibleなど）の適切な設定が必要です。
//
//    // Keychainからアイテムを削除するメソッド（必要に応じて）
//    // private func deleteDataFromKeychain(account: String) throws {
//    //     let query: [String: Any] = [
//    //         kSecClass as String: kSecClassGenericPassword,
//    //         kSecAttrService as String: keychainServiceIdentifier,
//    //         kSecAttrAccount as String: account
//    //     ]
//    //     let status = SecItemDelete(query as CFDictionary)
//    //     if status != errSecSuccess && status != errSecItemNotFound {
//    //         throw ActivationError.keychainError(message: "Failed to delete keychain item. Status: \(status)")
//    //     }
//    //     print("Keychain: Successfully deleted data for account \(account) (or it didn't exist).")
//    // }
//}
//
//// エラー型を定義
//enum ActivationError: Error, LocalizedError {
//    case invalidURL
//    case invalidResponse
//    case apiError(statusCode: Int, message: String)
//    case dataDecodingError
//
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL: return "無効なAPI URLです。"
//        case .invalidResponse: return "サーバーから無効なレスポンスを受け取りました。"
//        case .apiError(let statusCode, let message): return "APIエラー (コード: \(statusCode)): \(message)"
//        case .dataDecodingError: return "データのデコードに失敗しました。"
//        }
//    }
//}
//
//struct TokenResponse: Decodable {
//    let accessToken: String
//    let refreshToken: String
//    let expiresIn: Int
//}
