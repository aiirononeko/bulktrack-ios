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

// MARK: - Dashboard Models (NEW - OpenAPI スキーマに基づく)

struct WeekPoint: Decodable, Identifiable { 
    var id = UUID() 
    let weekStart: String 
    let totalVolume: Double
    let avgSetVolume: Double 
    let e1rmAvg: Double?     

    enum CodingKeys: String, CodingKey {
        case weekStart
        case totalVolume
        case avgSetVolume
        case e1rmAvg
    }
}

struct MuscleSeries: Decodable, Identifiable {
    var id: Int { muscleId } // muscleId を id として使用
    let muscleId: Int
    let name: String
    let points: [WeekPoint]

    enum CodingKeys: String, CodingKey {
        case muscleId
        case name
        case points
    }
}

struct MetricValuePoint: Decodable, Identifiable { 
    var id: String { weekStart + "_" + String(value) } // weekStartとvalueでidを生成
    let weekStart: String
    let value: Double

    enum CodingKeys: String, CodingKey {
        case weekStart
        case value
    }
}

struct MetricSeries: Decodable, Identifiable {
    var id: String { metricKey } // metricKey を id として使用
    let metricKey: String
    let unit: String
    let points: [MetricValuePoint] 

    enum CodingKeys: String, CodingKey {
        case metricKey
        case unit
        case points
    }
}

struct DashboardResponse: Decodable {
    let userId: String?
    let span: String?
    let thisWeek: WeekPoint
    let lastWeek: WeekPoint
    let trend: [WeekPoint]
    let muscles: [MuscleSeries]
    let metrics: [MetricSeries]

    // CodingKeys はプロパティ名とJSONキーが一致する場合は不要だが、
    // スネークケースなど違いがある場合は定義する。
    // 今回のOpenAPIスキーマではキャメルケースで一致していると仮定。
    // enum CodingKeys: String, CodingKey {
    //     case userId, span, thisWeek, lastWeek, trend, muscles, metrics
    // }
}

// MARK: - Session Models (OpenAPI スキーマに基づく)

struct SessionStartRequest: Encodable {
    // userId と startedAt は必須と仮定 (OpenAPIの SessionStart には元々 user_id, started_at がないので、
    // これらが実際にはリクエストボディに含まれないなら、それに応じて削除またはオプショナルにする必要あり)
    // 今回の修正API仕様では menu_id のみが SessionStart のプロパティ
    // let userId: String // OpenAPIの SessionStart スキーマに準拠するなら削除
    // let startedAt: String // OpenAPIの SessionStart スキーマに準拠するなら削除
    let menuId: String? 

    enum CodingKeys: String, CodingKey {
        // case userId = "user_id"
        // case startedAt = "started_at"
        case menuId = "menu_id"
    }
}

struct WorkoutSessionResponse: Decodable, Identifiable {
    let id: String // プロパティ名は id のままでOK (Identifiable準拠のため)
    let startedAt: String
    // 以下のプロパティはAPIレスポンスに含まれていないため、オプショナルにするか、
    // APIが返すように修正する必要がある。今回はオプショナルとして扱う。
    let userId: String?
    let menuId: String?
    let finishedAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "sessionId" // JSONのキー "sessionId" を プロパティ "id" にマッピング
        case startedAt = "startedAt" // JSONのキー "startedAt" (もしスネークケースなら "started_at")
        // APIレスポンスに合わせて他のキーも確認・修正
        case userId = "user_id" // APIが user_id を返さないならコメントアウトかオプショナル対応
        case menuId = "menu_id" // APIが menu_id を返さないならコメントアウトかオプショナル対応
        case finishedAt = "finished_at"
        case createdAt = "created_at"
    }
}

// MARK: - Workout Set Models (OpenAPI スキーマに基づく)

struct WorkoutSetCreate: Encodable {
    let exerciseId: String
    let setNumber: Int
    let weight: Float
    let reps: Int
    let rpe: Float?
}

struct WorkoutSetResponse: Decodable, Identifiable {
    let id: String
    let exerciseId: String
    let setNo: Int 
    let weight: Float
    let reps: Int
    let rpe: Float?
    let performedAt: String 
    let volume: Float      
    let createdAt: String    

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId 
        case setNo 
        case weight
        case reps
        case rpe
        case performedAt 
        case volume
        case createdAt
    }
}

class APIService {
    private let keychainService = KeychainService()
    private let baseURLString = APIConfig.baseURL
    
    private var isRefreshingToken = false
    private var pendingRequests: [(URLRequest, (Result<Data, Error>) -> Void)] = []

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // .sssZ を含む形式
        return formatter
    }()

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

    // MARK: - Token Refresh (async/await version)

    private func refreshToken() async throws {
        print("APIService: Attempting to refresh token (async)...")

        guard let currentRefreshToken = try? keychainService.getString(forKey: KeychainService.KeychainKeys.refreshToken) else {
            print("APIService: No refresh token found in Keychain. Cannot refresh (async).")
            throw APIError.unauthorized
        }

        guard let url = URL(string: baseURLString + "/v1/auth/refresh") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let requestBody = RefreshTokenRequest(refreshToken: currentRefreshToken)
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("APIService: Failed to encode refresh token request (async): \\(error)")
            throw APIError.requestFailed(error)
        }

        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("APIService: Refresh token API request error (async): \\(error.localizedDescription)")
            throw APIError.requestFailed(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("APIService: Invalid HTTP response from refresh API (async)")
            throw APIError.apiError(statusCode: 0, message: "Invalid HTTP response from refresh API")
        }
        
        print("APIService: Refresh Token API Response Status Code (async): \\(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 { // リフレッシュトークン自体が無効/期限切れ
                print("APIService: Refresh token is invalid or expired (async). Re-authentication required.")
                try? keychainService.deleteData(forAccount: KeychainService.KeychainKeys.accessToken)
                try? keychainService.deleteData(forAccount: KeychainService.KeychainKeys.refreshToken)
                
                UserDefaults.standard.set(false, forKey: "app.bulktrack.hasActivatedDevice")
                print("APIService: Cleared tokens and reset activation flag (async). Device ID remains. Please restart the app or trigger activation.")
            }
            throw APIError.apiError(statusCode: httpResponse.statusCode, message: "Refresh token API error (async)")
        }

        do {
            // TokenResponseの定義が別途必要
            let tokens = try JSONDecoder().decode(TokenResponse.self, from: data) 
            try saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
            print("APIService: Tokens refreshed successfully (async).")
        } catch {
            print("APIService: Failed to decode or save new tokens (async): \\(error.localizedDescription)")
            throw APIError.decodingError(error)
        }
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

    // MARK: - Recent Exercises API
    func fetchRecentExercises(limit: Int = 20, offset: Int = 0, locale: String = "ja", completion: @escaping (Result<[Exercise], Error>) -> Void) {
        guard let baseURL = URL(string: baseURLString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("/v1/me/exercises/recent"), resolvingAgainstBaseURL: true)
        var queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "locale", value: locale)
        ]
        components?.queryItems = queryItems

        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let accessToken = try getAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("Fetching recent exercises with URL: \(url) and Token: Bearer \(accessToken.prefix(10))... ")
        } catch {
            completion(.failure(error))
            return
        }

        performRequest(request) { result in
            switch result {
            case .success(let data):
                if let responseString = String(data: data, encoding: .utf8) {
                     print("Raw Recent Exercises API Response JSON: \(responseString)")
                }
                do {
                    let exercises = try JSONDecoder().decode([Exercise].self, from: data)
                    completion(.success(exercises))
                } catch let decodingError {
                    print("Recent Exercise Decoding Error: \(decodingError)")
                    completion(.failure(APIError.decodingError(decodingError)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Dashboard API
    func fetchDashboard(period: String? = nil, completion: @escaping (Result<DashboardResponse, Error>) -> Void) {
        guard let baseURL = URL(string: baseURLString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("/v1/dashboard"), resolvingAgainstBaseURL: true)
        
        var queryItems = [URLQueryItem]()
        if let p = period, !p.isEmpty {
            queryItems.append(URLQueryItem(name: "period", value: p))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let accessToken = try getAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("Fetching dashboard with URL: \(url) and Token: Bearer \(accessToken.prefix(10))... ")
        } catch {
            completion(.failure(error))
            return
        }

        performRequest(request) { result in
            switch result {
            case .success(let data):
                if let responseString = String(data: data, encoding: .utf8) {
                     print("Raw Dashboard API Response JSON: \(responseString)")
                }
                do {
                    let dashboardResponse = try JSONDecoder().decode(DashboardResponse.self, from: data)
                    completion(.success(dashboardResponse))
                } catch let decodingError {
                    print("Dashboard Decoding Error: \(decodingError)")
                    // より詳細なデコードエラー情報をログに出力
                    if let decodingError = decodingError as? DecodingError {
                        switch decodingError {
                        case .typeMismatch(let type, let context): print("Type mismatch: \(type), context: \(context.debugDescription)")
                        case .valueNotFound(let type, let context): print("Value not found: \(type), context: \(context.debugDescription)")
                        case .keyNotFound(let key, let context): print("Key not found: \(key.stringValue), context: \(context.debugDescription)")
                        case .dataCorrupted(let context): print("Data corrupted: \(context.debugDescription)")
                        @unknown default: print("Unknown decoding error")
                        }
                    }
                    completion(.failure(APIError.decodingError(decodingError)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Session Management

    func startSession(menuId: String? = nil, completion: @escaping (Result<WorkoutSessionResponse, Error>) -> Void) {
        guard let url = URL(string: baseURLString + "/v1/sessions") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = SessionStartRequest(menuId: menuId)
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(APIError.decodingError(error)))
            return
        }
        
        do {
            let accessToken = try getAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("APIService: Starting session with URL: \(url) and Token: Bearer \(accessToken.prefix(10))...")
        } catch {
            completion(.failure(error))
            return
        }

        performRequest(request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    // DateDecodingStrategy は WorkoutSessionResponse の CodingKeys で対応想定
                    let sessionResponse = try decoder.decode(WorkoutSessionResponse.self, from: data)
                    print("APIService: Session started successfully. Response: \(sessionResponse)")
                    completion(.success(sessionResponse))
                } catch {
                    print("APIService: Failed to decode session start response: \(error)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Raw response data for startSession: \(dataString)")
                    }
                    completion(.failure(APIError.decodingError(error)))
                }
            case .failure(let error):
                print("APIService: Failed to start session: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func finishSession(sessionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURLString + "/v1/sessions/\(sessionId)/finish") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let accessToken = try getAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("APIService: Finishing session with URL: \(url) and Token: Bearer \(accessToken.prefix(10))...")
        } catch {
            completion(.failure(error))
            return
        }
        
        performRequest(request) { result in
            switch result {
            case .success(let data): // 204 No Contentの場合 dataは空かもしれない
                // 成功時、レスポンスボディは期待しないため、dataのチェックは不要な場合もある
                // サーバーが204を返す場合、dataは0バイトになる
                if data.isEmpty {
                     print("APIService: Session (ID: \(sessionId)) finished successfully (204 No Content or empty body).")
                } else {
                     print("APIService: Session (ID: \(sessionId)) finished successfully with data (length: \(data.count)).")
                }
                completion(.success(()))
            case .failure(let error):
                print("APIService: Failed to finish session (ID: \(sessionId)): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Workout Set Management

    func recordSet(sessionId: String, setData: WorkoutSetCreate, completion: @escaping (Result<WorkoutSetResponse, Error>) -> Void) {
        guard let url = URL(string: baseURLString + "/v1/sessions/\(sessionId)/sets") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let encoder = JSONEncoder()
            // encoder.dateEncodingStrategy = .iso8601 // 日付型を送信する場合
            request.httpBody = try encoder.encode(setData)
            print("APIService: Recording set for session \(sessionId) with data: \(setData)")
        } catch {
            print("APIService: Failed to encode set data: \(error)")
            completion(.failure(APIError.decodingError(error))) // エンコードエラーもdecodingErrorで一旦まとめる
            return
        }
        
        do {
            let accessToken = try getAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } catch {
            completion(.failure(error))
            return
        }

        performRequest(request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    // decoder.dateDecodingStrategy = .customISO8601 // 日付型をデコードする場合
                    let setResponse = try decoder.decode(WorkoutSetResponse.self, from: data)
                    print("APIService: Set recorded successfully. Response: \(setResponse)")
                    completion(.success(setResponse))
                } catch {
                    print("APIService: Failed to decode set record response: \(error)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Raw response data for recordSet: \(dataString)")
                    }
                    completion(.failure(APIError.decodingError(error)))
                }
            case .failure(let error):
                print("APIService: Failed to record set: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Workout Set Operations

    func recordSet(sessionId: String, setData: WorkoutSetCreate) async throws -> WorkoutSetResponse {
        let endpoint = "/v1/sessions/\(sessionId)/sets"
        print("APIService: Recording set for session \(sessionId) with data: \(setData)")
        
        // performRequest を使用してリクエストを実行し、直接 WorkoutSetResponse にデコード
        return try await performRequest(
            endpoint: endpoint,
            method: "POST",
            body: setData,
            requiresAuth: true
        )
    }

    // MARK: - Dashboard Operations

    private func performRequest<T: Decodable, B: Encodable>(
        endpoint: String,
        method: String,
        body: B? = nil,
        requiresAuth: Bool = true,
        isRetry: Bool = false
    ) async throws -> T {
        guard let url = URL(string: baseURLString + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            do {
                let token = try getAccessToken()
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } catch {
                // アクセストークン取得に失敗した場合 (例: Keychainに存在しない)
                // リフレッシュを試みる前に、これがリトライでないことを確認
                if !isRetry {
                    print("APIService: Access token not found or invalid, attempting refresh before request to \(endpoint).")
                    try await refreshToken()
                    // リフレッシュ成功後、再度リクエストを試みる (isRetry: true を設定)
                    return try await performRequest(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth, isRetry: true)
                } else {
                    // リフレッシュ後のリトライでも失敗した場合は、元のエラーをスロー
                    print("APIService: Access token still invalid after refresh for request to \(endpoint).")
                    throw error
                }
            }
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.requestFailed(error) // エンコード失敗
            }
        }
        
        print("APIService: Making request to \(url.path)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(URLError(.badServerResponse))
        }
        
        print("APIService: Request to \(url.path) completed with status: \(httpResponse.statusCode)")


        if httpResponse.statusCode == 401 && requiresAuth && !isRetry {
            print("APIService: Received 401 Unauthorized. Attempting token refresh.")
            do {
                try await refreshToken()
                print("APIService: Token refresh successful. Retrying original request.")
                // リフレッシュ成功後、再度リクエストを試みる (isRetry: true を設定)
                return try await performRequest(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth, isRetry: true)
            } catch {
                print("APIService: Token refresh failed. Error: \(error.localizedDescription)")
                // リフレッシュに失敗した場合は、401エラーをAPIError.unauthorizedとして処理
                 throw APIError.unauthorized
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let rawResponseString = String(data: data, encoding: .utf8) {
                 print("APIService Error: Status \(httpResponse.statusCode), Response: \(rawResponseString)")
            }
            // TODO: サーバーからのエラーメッセージをパースしてAPIErrorに含める
            throw APIError.apiError(statusCode: httpResponse.statusCode, message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }

        do {
            let decoder = JSONDecoder()
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            decoder.dateDecodingStrategy = .custom { decoder -> Date in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                // .SSSZ 形式に対応できていない場合、カスタムで対応するか、より柔軟なパーサーを使う
                // ここでは仮にエラーをスロー
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            // AddedSetContainer を使わずに直接 WorkoutSetResponse にデコード
            let decodedResponse = try decoder.decode(T.self, from: data)
            print("APIService: Successfully decoded response for \(endpoint)")
            return decodedResponse
        } catch {
            print("APIService: Failed to decode response for \(endpoint): \(error.localizedDescription)")
            if let rawResponseString = String(data: data, encoding: .utf8) {
                print("Raw response data for \(endpoint): \(rawResponseString)")
            }
            throw APIError.decodingError(error)
        }
    }
}
