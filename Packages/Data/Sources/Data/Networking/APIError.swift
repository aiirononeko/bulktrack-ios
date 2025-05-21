import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case unexpectedStatusCode(Int)
    case decodingError(Error)
    case noData
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです。"
        case .requestFailed(let error):
            return "リクエストに失敗しました: \(error.localizedDescription)"
        case .unexpectedStatusCode(let statusCode):
            return "予期しないステータスコード: \(statusCode)"
        case .decodingError(let error):
            return "データのデコードに失敗しました: \(error.localizedDescription)"
        case .noData:
            return "データがありません。"
        case .custom(let message):
            return message
        }
    }
}
