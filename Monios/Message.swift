//
//  Message.swift
//  Monios
//
//  Chat message model and view components with Liquid Glass styling
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
        VStack(alignment: .leading, spacing: 4) {
            // Role indicator
            Text(message.isUser ? "you" : "monios")
                .font(TerminalTheme.monoFontSmall)
                .foregroundColor(message.isUser ? TerminalTheme.accent : TerminalTheme.accentBlue)

            // Message content
            Text(message.content)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }
}

struct TypingIndicatorView: View {
    @State private var animationPhase = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("monios")
                .font(TerminalTheme.monoFontSmall)
                .foregroundColor(TerminalTheme.accentBlue)

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(TerminalTheme.secondaryText)
                        .frame(width: 6, height: 6)
                        .opacity(animationPhase == index ? 1.0 : 0.3)
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}
