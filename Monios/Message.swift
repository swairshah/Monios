//
//  Message.swift
//  Monios
//
//  Chat message model and view components
//

import SwiftUI

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if !message.isUser {
                        Text("$")
                            .font(TerminalTheme.monoFont)
                            .foregroundColor(TerminalTheme.accent)
                    }
                    Text(message.isUser ? "you" : "monios")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)
                    if message.isUser {
                        Text(">")
                            .font(TerminalTheme.monoFont)
                            .foregroundColor(TerminalTheme.accentBlue)
                    }
                }

                Text(message.content)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isUser ? TerminalTheme.userMessage : TerminalTheme.assistantMessage)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(TerminalTheme.border, lineWidth: 1)
                    )

                Text(formatTime(message.timestamp))
                    .font(TerminalTheme.monoFontSmall)
                    .foregroundColor(TerminalTheme.mutedText)
            }

            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 16)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct TypingIndicatorView: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("$")
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.accent)
                    Text("monios")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)
                }

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(TerminalTheme.secondaryText)
                            .frame(width: 6, height: 6)
                            .opacity(animationPhase == index ? 1.0 : 0.3)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(TerminalTheme.assistantMessage)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(TerminalTheme.border, lineWidth: 1)
                )
            }

            Spacer(minLength: 50)
        }
        .padding(.horizontal, 16)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}
