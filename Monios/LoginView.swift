//
//  LoginView.swift
//  Monios
//
//  Terminal-aesthetic login screen with Liquid Glass styling
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @State private var showingError = false

    var body: some View {
        ZStack {
            // Gradient background for glass effect contrast
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.06, green: 0.07, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle ambient glow
            Circle()
                .fill(TerminalTheme.accent.opacity(0.08))
                .blur(radius: 100)
                .offset(y: -200)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo and title with glass card
                VStack(spacing: 16) {
                    Text("monios")
                        .font(TerminalTheme.monoFontTitle)
                        .foregroundColor(TerminalTheme.primaryText)

                    Text("a minimal chat experience")
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.secondaryText)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 40)
                .liquidGlass(cornerRadius: 20, shadowRadius: 15)
                .padding(.bottom, 60)

                Spacer()

                // Sign in buttons
                VStack(spacing: 16) {
                    // Sign in with Apple - glass styled
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
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                    // Google Sign In button with glass
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
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)

                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.05))

                                // Shine effect
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.1), Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .glassButton(cornerRadius: 8)
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
            Color.black.opacity(0.5)
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
            .liquidGlass(cornerRadius: 16, shadowRadius: 20)
        }
    }
}
