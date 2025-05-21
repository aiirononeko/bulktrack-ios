import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(Error) // Underlying network error, e.g., no internet
    case unexpectedStatusCode(statusCode: Int, data: Data?) // HTTP error without specific ErrorResponseDTO
    case serverError(statusCode: Int, errorResponse: ErrorResponseDTO) // HTTP error with ErrorResponseDTO
    case decodingError(Error) // Error parsing successful response
    case noData // Successful response but no data when data was expected
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです。"
        case .requestFailed(let error):
            return "リクエストに失敗しました: \(error.localizedDescription)"
        case .unexpectedStatusCode(let statusCode, _):
            return "サーバーエラーが発生しました (コード: \(statusCode))。"
        case .serverError(_, let errorResponse):
            // TODO: Potentially use errorResponse.code for more specific client-side messages
            return "サーバーエラー: \(errorResponse.message) (コード: \(errorResponse.code))"
        case .decodingError(let error):
            return "受信データの解析に失敗しました: \(error.localizedDescription)"
        case .noData:
            return "サーバーからデータが返されませんでした。"
        case .custom(let message):
            return message
        }
    }

    // Helper to access server error details if available
    public var serverErrorDetails: ErrorResponseDTO? {
        if case .serverError(_, let details) = self {
            return details
        }
        return nil
    }
    
    public var httpStatusCode: Int? {
        switch self {
        case .unexpectedStatusCode(let statusCode, _):
            return statusCode
        case .serverError(let statusCode, _):
            return statusCode
        default:
            return nil
        }
    }
}
