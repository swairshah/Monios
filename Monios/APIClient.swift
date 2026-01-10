//
//  APIClient.swift
//  Monios
//
//  HTTP client for authenticated API requests
//

import Foundation

class APIClient {
    #if DEBUG
    static let baseURL = "http://127.0.0.1:8000"
    #else
    static let baseURL = "https://swairshah--monios-api-fastapi-app-dev.modal.run"
    #endif

    private let tokenStorage: TokenStorage
    private let session: URLSession

    init(tokenStorage: TokenStorage, session: URLSession = .shared) {
        self.tokenStorage = tokenStorage
        self.session = session
    }

    // MARK: - Public Methods

    func get<T: Decodable>(_ endpoint: String, authenticated: Bool = true) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: "GET", authenticated: authenticated)
        return try await execute(request)
    }

    func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B, authenticated: Bool = true) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "POST", authenticated: authenticated)
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await execute(request)
    }

    // MARK: - Request Building

    private func buildRequest(endpoint: String, method: String, authenticated: Bool) throws -> URLRequest {
        guard let url = URL(string: APIClient.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if authenticated {
            guard let token = tokenStorage.getAccessToken() else {
                throw APIError.notAuthenticated
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Request Execution

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)

        case 401:
            throw APIError.unauthorized

        case 403:
            throw APIError.forbidden

        case 404:
            throw APIError.notFound

        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)

        default:
            throw APIError.httpError(httpResponse.statusCode, data)
        }
    }

    // MARK: - Error Types

    enum APIError: LocalizedError {
        case invalidURL
        case notAuthenticated
        case invalidResponse
        case unauthorized
        case forbidden
        case notFound
        case serverError(Int)
        case httpError(Int, Data)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .notAuthenticated:
                return "Not authenticated"
            case .invalidResponse:
                return "Invalid response from server"
            case .unauthorized:
                return "Session expired. Please sign in again."
            case .forbidden:
                return "Access denied"
            case .notFound:
                return "Resource not found"
            case .serverError(let code):
                return "Server error (\(code))"
            case .httpError(let code, _):
                return "Request failed (\(code))"
            }
        }
    }
}

// MARK: - Chat-specific API

extension APIClient {
    struct ChatRequest: Encodable {
        let content: String
    }

    struct ChatMessageResponse: Decodable {
        let id: String
        let content: String
        let timestamp: String
        let userEmail: String
    }

    func sendMessage(_ content: String) async throws -> ChatMessageResponse {
        let request = ChatRequest(content: content)
        return try await post("/api/chat", body: request)
    }
}
