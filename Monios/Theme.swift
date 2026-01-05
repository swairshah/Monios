//
//  Theme.swift
//  Monios
//
//  Terminal-aesthetic theme configuration
//

import SwiftUI

struct TerminalTheme {
    // Dark mode colors
    static let background = Color(red: 0.08, green: 0.09, blue: 0.10)
    static let surfaceBackground = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let cardBackground = Color(red: 0.15, green: 0.16, blue: 0.18)
    static let border = Color(red: 0.25, green: 0.27, blue: 0.30)

    // Text colors
    static let primaryText = Color(red: 0.85, green: 0.85, blue: 0.85)
    static let secondaryText = Color(red: 0.55, green: 0.58, blue: 0.62)
    static let mutedText = Color(red: 0.40, green: 0.43, blue: 0.47)

    // Accent colors
    static let accent = Color(red: 0.95, green: 0.68, blue: 0.25) // Orange/amber
    static let accentBlue = Color(red: 0.40, green: 0.60, blue: 0.95)

    // Message bubbles
    static let userMessage = Color(red: 0.20, green: 0.22, blue: 0.25)
    static let assistantMessage = Color(red: 0.12, green: 0.13, blue: 0.15)

    // Fonts
    static let monoFont = Font.system(.body, design: .monospaced)
    static let monoFontSmall = Font.system(.caption, design: .monospaced)
    static let monoFontLarge = Font.system(.title2, design: .monospaced)
    static let monoFontTitle = Font.system(.title, design: .monospaced).weight(.semibold)
}

// Custom text field style for terminal look
struct TerminalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(TerminalTheme.monoFont)
            .foregroundColor(TerminalTheme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(TerminalTheme.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TerminalTheme.border, lineWidth: 1)
            )
    }
}

// Code block style modifier
struct CodeBlockStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(TerminalTheme.monoFont)
            .foregroundColor(TerminalTheme.primaryText)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TerminalTheme.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TerminalTheme.border, lineWidth: 1)
            )
    }
}

extension View {
    func codeBlockStyle() -> some View {
        modifier(CodeBlockStyle())
    }
}
