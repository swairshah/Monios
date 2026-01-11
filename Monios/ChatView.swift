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
        VStack(spacing: 0) {
            // Header
            headerView

            // Messages
            messagesScrollView

            // Input
            inputView
        }
        .background(TerminalTheme.background)
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
        HStack {
            Text("monios")
                .font(TerminalTheme.monoFontTitle)
                .foregroundColor(TerminalTheme.primaryText)

            Spacer()

            HStack(spacing: 8) {
                if isCheckingConnection {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("connecting...")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)
                } else {
                    // Glass status indicator
                    Circle()
                        .fill(isConnected ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                        .frame(width: 8, height: 8)
                        .shadow(color: isConnected ? .green.opacity(0.5) : .red.opacity(0.5), radius: 4)
                    Text(isConnected ? "connected" : "disconnected")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)

                    // Retry button when disconnected
                    if !isConnected {
                        Button(action: { checkConnection() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .foregroundColor(TerminalTheme.secondaryText)
                                .padding(6)
                                .glassButton(cornerRadius: 6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassHeader()
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
                    }
                }
                .padding(.vertical, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)

            Text("Start a conversation")
                .font(TerminalTheme.monoFontTitle)
                .foregroundColor(TerminalTheme.primaryText)

            if let user = authManager.currentUser {
                Text("signed in as \(user.email)")
                    .font(TerminalTheme.monoFontSmall)
                    .foregroundColor(TerminalTheme.mutedText)
            }

            Spacer()
        }
    }

    private var inputView: some View {
        HStack(spacing: 12) {
            Text(">")
                .font(TerminalTheme.monoFontLarge)
                .foregroundColor(isConnected ? TerminalTheme.accent : TerminalTheme.mutedText)

            if isConnected {
                TextField("type a message...", text: $inputText)
                    .textFieldStyle(TerminalTextFieldStyle())
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            inputText.isEmpty
                                ? AnyShapeStyle(TerminalTheme.mutedText)
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [TerminalTheme.accent, TerminalTheme.accent.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .shadow(color: inputText.isEmpty ? .clear : TerminalTheme.accent.opacity(0.4), radius: 8)
                }
                .disabled(inputText.isEmpty)
            } else {
                Text("backend not connected")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.mutedText)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5),
            alignment: .top
        )
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
