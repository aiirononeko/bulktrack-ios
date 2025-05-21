import Foundation

public protocol NetworkClientProtocol {
    func sendRequest<T: Decodable>(endpoint: Endpoint, decoder: JSONDecoder) async throws -> T
    func sendRequest(endpoint: Endpoint) async throws // For requests that don't return data (e.g., 204 No Content)
}

public struct NetworkClient: NetworkClientProtocol {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func sendRequest<T: Decodable>(endpoint: Endpoint, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        guard let urlRequest = endpoint.asURLRequest() else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.custom("Invalid HTTP response.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                // TODO: Parse error response body if API provides one
                throw APIError.unexpectedStatusCode(httpResponse.statusCode)
            }
            
            // The caller is responsible for configuring the decoder,
            // including its dateDecodingStrategy.
            // APIService, for example, passes a decoder already configured with .iso8601.

            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    public func sendRequest(endpoint: Endpoint) async throws {
        guard let urlRequest = endpoint.asURLRequest() else {
            throw APIError.invalidURL
        }

        do {
            let (_, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.custom("Invalid HTTP response.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                // TODO: Parse error response body if API provides one
                throw APIError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }
}

// Endpoint definition (can be in its own file or here for simplicity)
public protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get } // For query params or body
    var body: Data? { get } // For raw body data
}

public extension Endpoint {
    // Default implementations
    var baseURL: URL {
        // TODO: Make this configurable (e.g., via environment variables or a config file)
        // For now, using the local development server from OpenAPI spec.
        // Ensure this matches your actual API server URL.
        #if DEBUG
        return URL(string: "http://localhost:8787/v1")!
        #else
        return URL(string: "https://api.bulk-track.com/v1")!
        #endif
    }

    var headers: [String: String]? {
        var defaultHeaders = ["Content-Type": "application/json"]
        // Add Authorization header if a token is available
        // This needs a mechanism to access the current auth token.
        // if let token = AuthManager.shared.accessToken {
        //     defaultHeaders["Authorization"] = "Bearer \(token)"
        // }
        return defaultHeaders
    }
    
    var parameters: [String: Any]? { nil }
    var body: Data? { nil }

    func asURLRequest() -> URLRequest? {
        var url = baseURL.appendingPathComponent(path)

        if method == .get, let parameters = parameters as? [String: String] {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            if let newUrl = urlComponents?.url {
                url = newUrl
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let bodyData = body {
            request.httpBody = bodyData
        } else if method != .get, let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        return request
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    // Add other methods as needed
}
