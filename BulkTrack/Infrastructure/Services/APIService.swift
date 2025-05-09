//
//  APIService.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/10.
//

import Foundation

// API呼び出しに関する共通エラー
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case noData
    case decodingError(Error)
    case unauthorized // 401など認証エラー用
    case apiError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです。"
        case .requestFailed(let err): return "リクエスト失敗: \(err.localizedDescription)"
        case .noData: return "サーバーからデータが返されませんでした。"
        case .decodingError(let err): return "データのデコードに失敗しました: \(err.localizedDescription)"
        case .unauthorized: return "認証に失敗しました。アクセストークンが無効か期限切れの可能性があります。"
        case .apiError(let code, let msg): return "APIエラー (コード: \(code)): \(msg ?? "詳細不明")"
        }
    }
}

// MARK: - Exercise Models (OpenAPI スキーマに基づく)

struct Exercise: Decodable, Identifiable {
    let id: String // UUID
    let canonicalName: String
    let locale: String?
    let name: String?
    let aliases: String?
    let isOfficial: Bool?
    let lastUsedAt: String? // date-time (ISO 8601)

    enum CodingKeys: String, CodingKey {
        case id
        case canonicalName = "canonical_name"
        case locale
        case name
        case aliases
        case isOfficial = "is_official"
        case lastUsedAt = "last_used_at"
    }
}

// ExerciseCreate は Exercise に含まれるので、ここでは明示的に作成せず、
// POSTリクエスト時のために別途定義することも可能だが、GETでは不要。

// MARK: - Auth Models (OpenAPI スキーマに基づく)

struct RefreshTokenRequest: Encodable { // POSTリクエストボディ用なのでEncodable
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// TokenResponse は ActivationService.swift にあるので、ここでは再定義しないか、
// 共通のモデルファイルに移動することを検討。今回は簡略化のため、必要であればAPIService内にも定義するが、
// 本来は重複を避けるべき。
// (ActivationService.swiftのTokenResponseを参照できるなら、ここでは不要)

class APIService {
    private let keychainService = KeychainService()
    private let baseURLString = APIConfig.baseURL
    
    private var isRefreshingToken = false
    private var pendingRequests: [(URLRequest, (Result<Data, Error>) -> Void)] = []

    // Keychainからアクセストークンを取得するヘルパー
    private func getAccessToken() throws -> String {
        guard let token = try keychainService.getString(forKey: KeychainService.KeychainKeys.accessToken) else {
            // アクセストークンがない場合は認証エラーとして扱う
            print("APIService: Access token not found in Keychain.")
            throw APIError.unauthorized 
        }
        return token
    }

    // 新しいアクセストークンとリフレッシュトークンをKeychainに保存するヘルパー
    private func saveTokens(accessToken: String, refreshToken: String?) throws {
        try keychainService.saveString(accessToken, forKey: KeychainService.KeychainKeys.accessToken)
        if let newRefreshToken = refreshToken {
            try keychainService.saveString(newRefreshToken, forKey: KeychainService.KeychainKeys.refreshToken)
            print("APIService: New refresh token saved to Keychain.")
        }
        print("APIService: New access token saved to Keychain.")
    }

    // トークンリフレッシュ処理
    private func refreshToken(completion: @escaping (Result<Void, Error>) -> Void) {
        print("APIService: Attempting to refresh token...")
        guard let currentRefreshToken = try? keychainService.getString(forKey: KeychainService.KeychainKeys.refreshToken) else {
            print("APIService: No refresh token found in Keychain. Cannot refresh.")
            completion(.failure(APIError.unauthorized)) // リフレッシュトークンがなければ認証エラー
            return
        }

        guard let url = URL(string: baseURLString + "/v1/auth/refresh") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let requestBody = RefreshTokenRequest(refreshToken: currentRefreshToken)
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("APIService: Failed to encode refresh token request: \(error)")
            completion(.failure(APIError.requestFailed(error)))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("APIService: Refresh token API request error: \(error.localizedDescription)")
                completion(.failure(APIError.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.apiError(statusCode: 0, message: "Invalid HTTP response from refresh API")))
                return
            }
            
            print("APIService: Refresh Token API Response Status Code: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 { // リフレッシュトークン自体が無効/期限切れ
                    print("APIService: Refresh token is invalid or expired. Re-authentication required.")
                    // Keychainからアクセストークンとリフレッシュトークンのみを削除
                    try? self.keychainService.deleteData(forAccount: KeychainService.KeychainKeys.accessToken)
                    try? self.keychainService.deleteData(forAccount: KeychainService.KeychainKeys.refreshToken)
                    // デバイスIDは削除しない！
                    // try? self.keychainService.deleteData(forAccount: KeychainService.KeychainKeys.deviceId)
                    
                    // 再アクティベーションを促すためにUserDefaultsを更新
                    UserDefaults.standard.set(false, forKey: "app.bulktrack.hasActivatedDevice")
                    print("APIService: Cleared tokens and reset activation flag. Device ID remains. Please restart the app or trigger activation.")
                }
                completion(.failure(APIError.apiError(statusCode: httpResponse.statusCode, message: "Refresh token API error")))
                return
            }

            guard let responseData = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                // /v1/auth/refresh も TokenResponse を返すと仮定 (OpenAPI仕様に基づく)
                let tokens = try JSONDecoder().decode(TokenResponse.self, from: responseData)
                try self.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken) // refreshTokenも更新される場合があるため
                print("APIService: Tokens refreshed successfully.")
                completion(.success(()))
            } catch {
                print("APIService: Failed to decode or save new tokens: \(error.localizedDescription)")
                completion(.failure(APIError.decodingError(error)))
            }
        }
        task.resume()
    }

    // MARK: - Generic Request Handler (リファクタリングしてここに集約するイメージ)
    // このメソッドはまだ完全ではない。再試行ロジック、リフレッシュ処理の多重実行防止などが必要。
    private func performRequest(_ originalRequest: URLRequest, originalCompletion: @escaping (Result<Data, Error>) -> Void) {
        var requestToPerform = originalRequest
        
        // ヘッダーにアクセストークンを付与 (既に付与されている場合は上書きしないように注意、または常にここで設定)
        // この例では、performRequestを呼ぶ前にAuthorizationヘッダーが設定済みであることを期待するか、
        // ここで毎回getAccessToken()して設定する。
        // 今回は、呼び出し側 (fetchExercisesなど) で設定済みと仮定。
        // ただし、リフレッシュ後の再試行では新しいトークンで上書きする必要がある。
        
        // print("Performing request: \(requestToPerform.url?.absoluteString ?? "") with headers: \(requestToPerform.allHTTPHeaderFields ?? [:])")

        URLSession.shared.dataTask(with: requestToPerform) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                originalCompletion(.failure(APIError.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                originalCompletion(.failure(APIError.apiError(statusCode: 0, message: "Invalid HTTP response object")))
                return
            }
            
            print("APIService: Request to \(originalRequest.url?.path ?? "") completed with status: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 401 {
                print("APIService: Received 401 Unauthorized. Attempting token refresh.")
                
                if self.isRefreshingToken {
                    print("APIService: Token refresh already in progress. Queuing request (actual queueing not yet implemented).")
                    originalCompletion(.failure(APIError.unauthorized)) 
                    return
                }
                self.isRefreshingToken = true
                
                self.refreshToken { refreshResult in
                    self.isRefreshingToken = false
                    switch refreshResult {
                    case .success:
                        print("APIService: Token refresh successful. Retrying original request.")
                        var newRequest = originalRequest
                        do {
                            let newAccessToken = try self.getAccessToken()
                            newRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
                            self.performRequest(newRequest, originalCompletion: originalCompletion)
                        } catch {
                             print("APIService: Failed to get new access token after refresh. \(error.localizedDescription)")
                            originalCompletion(.failure(APIError.unauthorized))
                        }
                    case .failure(let refreshError):
                        print("APIService: Token refresh failed. \(refreshError.localizedDescription)")
                        originalCompletion(.failure(refreshError))
                    }
                    // TODO: 待機中のリクエストを処理するロジック (pendingRequests)
                }
            } else {
                // 401以外のエラーまたは成功
                if (200...299).contains(httpResponse.statusCode) {
                    if let responseData = data {
                        originalCompletion(.success(responseData))
                    } else {
                        originalCompletion(.failure(APIError.noData))
                    }
                } else {
                    var errorMessage: String? = nil
                    if let responseData = data, let msg = String(data: responseData, encoding: .utf8) { errorMessage = msg }
                    originalCompletion(.failure(APIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)))
                }
            }
        }.resume()
    }
    
    // fetchExercises を performRequest を使うように修正
    func fetchExercises(query: String?, locale: String?, completion: @escaping (Result<[Exercise], Error>) -> Void) {
        guard let baseURL = URL(string: baseURLString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("/v1/exercises"), resolvingAgainstBaseURL: true)
        var queryItems = [URLQueryItem]()
        if let q = query, !q.isEmpty { queryItems.append(URLQueryItem(name: "q", value: q)) }
        if let loc = locale, !loc.isEmpty { queryItems.append(URLQueryItem(name: "locale", value: loc)) }
        if !queryItems.isEmpty { components?.queryItems = queryItems }

        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // performRequestを呼び出す前にAuthorizationヘッダーを設定
        do {
            let accessToken = try getAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("Fetching exercises with URL: \(url) and Token: Bearer \(accessToken.prefix(10))... ")
        } catch {
            completion(.failure(error)) // 通常はAPIError.unauthorized
            return
        }

        performRequest(request) { result in
            switch result {
            case .success(let data):
                if let responseString = String(data: data, encoding: .utf8) {
                     print("Raw Exercises API Response JSON: \(responseString)")
                }
                do {
                    let exercises = try JSONDecoder().decode([Exercise].self, from: data)
                    completion(.success(exercises))
                } catch let decodingError {
                    print("Exercise Decoding Error: \(decodingError)")
                    completion(.failure(APIError.decodingError(decodingError)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
