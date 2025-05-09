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

class APIService {
    private let keychainService = KeychainService()
    private let baseURLString = APIConfig.baseURL // APIConfigからベースURLを取得

    // Keychainからアクセストークンを取得するヘルパー
    private func getAccessToken() throws -> String {
        guard let token = try keychainService.getString(forKey: KeychainService.KeychainKeys.accessToken) else {
            // アクセストークンがない場合は認証エラーとして扱う
            print("APIService: Access token not found in Keychain.")
            throw APIError.unauthorized 
        }
        return token
    }

    func fetchExercises(query: String?, locale: String?, completion: @escaping (Result<[Exercise], Error>) -> Void) {
        guard let baseURL = URL(string: baseURLString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("/v1/exercises"), resolvingAgainstBaseURL: true)
        
        var queryItems = [URLQueryItem]()
        if let q = query, !q.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: q))
        }
        if let loc = locale, !loc.isEmpty {
            queryItems.append(URLQueryItem(name: "locale", value: loc))
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
            print("Fetching exercises with URL: \(url) and Token: Bearer \(accessToken.prefix(10))... ") // トークンは一部のみ表示
        } catch {
            completion(.failure(error)) // getAccessToken()がスローしたエラー (例: APIError.unauthorized)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.apiError(statusCode: 0, message: "Invalid HTTP response object")))
                return
            }
            
            print("Fetch Exercises API Response Status Code: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    completion(.failure(APIError.unauthorized))
                } else {
                    var errorMessage: String? = nil
                    if let responseData = data, let msg = String(data: responseData, encoding: .utf8) {
                        errorMessage = msg
                        print("API Error Response Body: \(msg)")
                    }
                    completion(.failure(APIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)))
                }
                return
            }

            guard let responseData = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                 print("Raw Exercises API Response JSON: \(responseString)")
            }

            do {
                let exercises = try JSONDecoder().decode([Exercise].self, from: responseData)
                completion(.success(exercises))
            } catch let decodingError {
                print("Exercise Decoding Error: \(decodingError)")
                completion(.failure(APIError.decodingError(decodingError)))
            }
        }
        task.resume()
    }
}
