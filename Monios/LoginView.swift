//
//  LoginView.swift
//  Monios
//
//  Terminal-aesthetic login screen
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @State private var showingError = false

    var body: some View {
        ZStack {
            TerminalTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo and title
                VStack(spacing: 16) {
                    Text("monios")
                        .font(TerminalTheme.monoFontTitle)
                        .foregroundColor(TerminalTheme.primaryText)

                    Text("a minimal chat experience")
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.secondaryText)
                }
                .padding(.bottom, 60)

                Spacer()

                // Sign in buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.email, .fullName]
                        },
                        onCompletion: { result in
                            Task {
                                await authManager.handleSignInWithApple(result: result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(8)

                    // Google Sign In button
                    Button(action: {
                        Task {
                            await authManager.signInWithGoogle(presentingWindow: nil)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Sign in with Google")
                                .font(TerminalTheme.monoFont)
                        }
                        .foregroundColor(TerminalTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(TerminalTheme.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(TerminalTheme.border, lineWidth: 1)
                        )
                    }

                    // Dev mode button (for testing without real auth)
                    #if DEBUG
                    Button(action: {
                        Task {
                            await authManager.devSignIn()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("$")
                                .foregroundColor(TerminalTheme.accent)
                            Text("dev mode")
                                .font(TerminalTheme.monoFontSmall)
                        }
                        .foregroundColor(TerminalTheme.secondaryText)
                    }
                    .padding(.top, 8)
                    #endif
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

                // Loading overlay
                if authManager.isLoading {
                    loadingOverlay
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { authManager.error = nil }
        } message: {
            Text(authManager.error ?? "An error occurred")
        }
        .onChange(of: authManager.error) { _, newValue in
            showingError = newValue != nil
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: TerminalTheme.accent))
                    .scaleEffect(1.2)

                Text("authenticating...")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.secondaryText)
            }
            .padding(30)
            .background(TerminalTheme.cardBackground)
            .cornerRadius(12)
        }
    }
}
