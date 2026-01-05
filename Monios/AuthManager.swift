//
//  AuthManager.swift
//  Monios
//
//  Handles Google Sign-In and JWT token management
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    // Your Google Client ID
    private let googleClientID = "558486289958-glki40l5f7nl1dlvnb9ekhakjn9r2vjc.apps.googleusercontent.com"

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var currentUser: User?
    @Published var error: String?

    private let tokenStorage = TokenStorage()
    private let apiClient: APIClient

    struct User: Codable {
        let id: String
        let email: String
        let name: String?
        let picture: String?
    }

    struct TokenPair: Codable {
        let accessToken: String
        let refreshToken: String
        let tokenType: String
        let expiresIn: Int
    }

    struct AuthResponse: Codable {
        let user: User
        let tokens: TokenPair
    }

    private init() {
        self.apiClient = APIClient(tokenStorage: tokenStorage)
        checkExistingAuth()
    }

    private func checkExistingAuth() {
        if tokenStorage.getAccessToken() != nil {
            isAuthenticated = true
            // In production, validate token with server
        }
    }

    // MARK: - Sign In with Apple (Alternative to Google)

    func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8) {

                await authenticateWithBackend(idToken: tokenString, provider: "apple")
            }
        case .failure(let err):
            error = err.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle(presentingWindow: UIWindow? = nil) async {
        isLoading = true
        error = nil

        // Get the root view controller from the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingVC = windowScene.windows.first?.rootViewController else {
            error = "Unable to find presenting view controller"
            isLoading = false
            return
        }

        // Configure Google Sign-In with client ID
        let config = GIDConfiguration(clientID: googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
            guard let idToken = result.user.idToken?.tokenString else {
                error = "Failed to get ID token from Google"
                isLoading = false
                return
            }
            await authenticateWithBackend(idToken: idToken, provider: "google")
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func authenticateWithBackend(idToken: String, provider: String) async {
        do {
            let endpoint = provider == "google" ? "/auth/google" : "/auth/apple"
            let body = ["id_token": idToken]

            let response: AuthResponse = try await apiClient.post(endpoint, body: body, authenticated: false)

            tokenStorage.saveTokens(
                accessToken: response.tokens.accessToken,
                refreshToken: response.tokens.refreshToken
            )
            currentUser = response.user
            isAuthenticated = true
            isLoading = false

        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Development Helper

    private func simulateAuth() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Create mock tokens
        tokenStorage.saveTokens(
            accessToken: "dev_access_token_\(UUID().uuidString)",
            refreshToken: "dev_refresh_token_\(UUID().uuidString)"
        )

        currentUser = User(
            id: "dev_user_123",
            email: "dev@example.com",
            name: "Dev User",
            picture: nil
        )
        isAuthenticated = true
        isLoading = false
    }

    // MARK: - Token Refresh

    func refreshTokens() async throws {
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            throw AuthError.noRefreshToken
        }

        let body = ["refresh_token": refreshToken]
        let response: TokenPair = try await apiClient.post("/auth/refresh", body: body, authenticated: false)

        tokenStorage.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }

    // MARK: - Sign Out

    func signOut() {
        tokenStorage.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }

    enum AuthError: LocalizedError {
        case noRefreshToken
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .noRefreshToken:
                return "No refresh token available"
            case .invalidResponse:
                return "Invalid response from server"
            }
        }
    }
}

// MARK: - Token Storage

class TokenStorage {
    private let accessTokenKey = "monios_access_token"
    private let refreshTokenKey = "monios_refresh_token"

    func saveTokens(accessToken: String, refreshToken: String) {
        // In production, use Keychain instead of UserDefaults
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
    }

    func getAccessToken() -> String? {
        UserDefaults.standard.string(forKey: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    func clearTokens() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
