//
//  AppError.swift
//  Domain
//
//  Created by Cline on 2025/05/22.
//

import Foundation

public enum AppError: LocalizedError, Equatable {
    case authenticationError(AuthErrorType)
    case networkError(NetworkErrorType)
    case storageError(StorageErrorType)
    case unknownError(String?)

    public var errorDescription: String? {
        switch self {
        case .authenticationError(let authError):
            return authError.localizedDescription
        case .networkError(let networkError):
            return networkError.localizedDescription
        case .storageError(let storageError):
            return storageError.localizedDescription
        case .unknownError(let message):
            return message ?? "不明なエラーが発生しました。"
        }
    }

    // Equatable conformance
    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.authenticationError(let lAuth), .authenticationError(let rAuth)):
            return lAuth == rAuth
        case (.networkError(let lNet), .networkError(let rNet)):
            return lNet == rNet
        case (.storageError(let lStore), .storageError(let rStore)):
            return lStore == rStore
        case (.unknownError(let lMsg), .unknownError(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

public enum AuthErrorType: LocalizedError, Equatable {
    case activationFailed(String?)
    case refreshTokenFailed(String?)
    case logoutFailed(String?)
    case notAuthenticated
    case sessionExpired
    case underlying(String) // For wrapping other auth-related errors

    public var errorDescription: String? {
        switch self {
        case .activationFailed(let msg):
            return msg ?? "デバイスのアクティベーションに失敗しました。"
        case .refreshTokenFailed(let msg):
            return msg ?? "セッションの更新に失敗しました。"
        case .logoutFailed(let msg):
            return msg ?? "ログアウト処理中にエラーが発生しました。"
        case .notAuthenticated:
            return "認証されていません。ログインしてください。"
        case .sessionExpired:
            return "セッションの有効期限が切れました。再度ログインしてください。"
        case .underlying(let description):
            return description
        }
    }
}

public enum NetworkErrorType: LocalizedError, Equatable {
    case noConnection
    case timeout
    case serverError(statusCode: Int, message: String?)
    case decodingError(String?)
    case encodingError(String?)
    case invalidURL
    case underlying(String) // For wrapping other network-related errors

    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "インターネット接続がありません。"
        case .timeout:
            return "リクエストがタイムアウトしました。"
        case .serverError(let statusCode, let message):
            return message ?? "サーバーエラーが発生しました (コード: \(statusCode))。"
        case .decodingError(let msg):
            return msg ?? "データの解析に失敗しました。"
        case .encodingError(let msg):
            return msg ?? "データのリクエスト作成に失敗しました。"
        case .invalidURL:
            return "無効なURLです。"
        case .underlying(let description):
            return description
        }
    }
}

public enum StorageErrorType: LocalizedError, Equatable {
    case saveFailed(String?)
    case itemNotFound
    case deleteFailed(String?)
    case underlying(String) // For wrapping other storage-related errors

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let msg):
            return msg ?? "データの保存に失敗しました。"
        case .itemNotFound:
            return "データが見つかりませんでした。"
        case .deleteFailed(let msg):
            return msg ?? "データの削除に失敗しました。"
        case .underlying(let description):
            return description
        }
    }
}
