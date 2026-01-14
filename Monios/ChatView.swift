//
//  ChatView.swift
//  Monios
//
//  Main chat interface with Liquid Glass aesthetic
//

import SwiftUI

struct ChatView: View {
    @Binding var messages: [Message]
    @ObservedObject var authManager: AuthManager

    @State private var inputText = ""
    @State private var isTyping = false
    @State private var isConnected = false
    @State private var isCheckingConnection = true
    @FocusState private var isInputFocused: Bool

    private let apiClient = APIClient(tokenStorage: TokenStorage())

    var body: some View {
        ZStack {
            // Background
            ZStack {
                TerminalTheme.background
                LinearGradient(
                    colors: [
                        TerminalTheme.accent.opacity(0.05),
                        Color.clear,
                        TerminalTheme.accentBlue.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()

            // Messages scroll view (full screen)
            messagesScrollView

            // Floating header at top
            VStack {
                headerView
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                Spacer()
            }

            // Floating input at bottom
            VStack {
                Spacer()
                inputView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .onAppear {
            checkConnection()
        }
    }

    private func checkConnection() {
        isCheckingConnection = true
        Task {
            do {
                let url = URL(string: APIClient.baseURL + "/health")!
                let (_, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    await MainActor.run {
                        isConnected = true
                        isCheckingConnection = false
                    }
                } else {
                    await MainActor.run {
                        isConnected = false
                        isCheckingConnection = false
                    }
                }
            } catch {
                await MainActor.run {
                    isConnected = false
                    isCheckingConnection = false
                }
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            Text("monios")
                .font(TerminalTheme.monoFontLarge)
                .foregroundColor(TerminalTheme.primaryText)

            Spacer()

            HStack(spacing: 6) {
                if isCheckingConnection {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("...")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)
                } else {
                    Circle()
                        .fill(isConnected ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                        .frame(width: 8, height: 8)
                        .shadow(color: isConnected ? .green.opacity(0.5) : .red.opacity(0.5), radius: 4)
                    Text(isConnected ? "online" : "offline")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)

                    if !isConnected {
                        Button(action: { checkConnection() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                                .foregroundColor(TerminalTheme.secondaryText)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.clear)
        .floatingGlassEffect()
        .onTapGesture {
            isInputFocused = false
        }
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if messages.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }

                        if isTyping {
                            TypingIndicatorView()
                        }

                        // Scroll anchor at bottom
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                }
                .padding(.top, 70) // Space for floating header
                .padding(.bottom, 80) // Space for floating input
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
            .onChange(of: isTyping) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)

            if !isConnected && !isCheckingConnection {
                // Disconnected state - show in center
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundColor(TerminalTheme.mutedText)

                    Text("backend not connected")
                        .font(TerminalTheme.monoFontLarge)
                        .foregroundColor(TerminalTheme.mutedText)

                    Button(action: { checkConnection() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("retry")
                        }
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.primaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassButton(cornerRadius: 10)
                    }
                }
            } else {
                Text("Start a conversation")
                    .font(TerminalTheme.monoFontTitle)
                    .foregroundColor(TerminalTheme.primaryText)

                if let user = authManager.currentUser {
                    Text("signed in as \(user.email)")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.mutedText)
                }
            }

            Spacer()
        }
    }

    private var inputView: some View {
        HStack(spacing: 12) {
            TextField(isConnected ? "type a message..." : "waiting for connection...", text: $inputText)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)
                .focused($isInputFocused)
                .disabled(!isConnected)
                .onSubmit {
                    sendMessage()
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        inputText.isEmpty || !isConnected
                            ? AnyShapeStyle(TerminalTheme.mutedText)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [TerminalTheme.accent, TerminalTheme.accent.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: (inputText.isEmpty || !isConnected) ? .clear : TerminalTheme.accent.opacity(0.4), radius: 8)
            }
            .disabled(inputText.isEmpty || !isConnected)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.clear)
        .floatingGlassEffect()
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard isConnected else { return }

        let userMessage = Message(content: inputText, isUser: true)
        messages.append(userMessage)
        let sentText = inputText
        inputText = ""

        isTyping = true

        Task {
            await sendToAPI(sentText)
        }
    }

    private func sendToAPI(_ content: String) async {
        do {
            let response = try await apiClient.sendMessage(content)
            await MainActor.run {
                isTyping = false
                let assistantMessage = Message(content: response.content, isUser: false)
                messages.append(assistantMessage)
            }
        } catch {
            await MainActor.run {
                isTyping = false
                let errorMessage = Message(
                    content: "error: \(error.localizedDescription)",
                    isUser: false
                )
                messages.append(errorMessage)
            }
        }
    }

}
