//
//  Theme.swift
//  Monios
//
//  Liquid Glass themed configuration
//

import SwiftUI

struct TerminalTheme {
    // Base background (kept dark for glass contrast)
    static let background = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let surfaceBackground = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let cardBackground = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let border = Color.white.opacity(0.12)

    // Text colors (slightly brighter for glass backgrounds)
    static let primaryText = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let secondaryText = Color(red: 0.60, green: 0.63, blue: 0.68)
    static let mutedText = Color(red: 0.45, green: 0.48, blue: 0.52)

    // Accent colors
    static let accent = Color(red: 0.95, green: 0.68, blue: 0.25) // Orange/amber
    static let accentBlue = Color(red: 0.40, green: 0.60, blue: 0.95)

    // Message bubbles (slightly more translucent base)
    static let userMessage = Color(red: 0.18, green: 0.20, blue: 0.24)
    static let assistantMessage = Color(red: 0.10, green: 0.11, blue: 0.14)

    // Fonts
    static let monoFont = Font.system(.body, design: .monospaced)
    static let monoFontSmall = Font.system(.caption, design: .monospaced)
    static let monoFontLarge = Font.system(.title2, design: .monospaced)
    static let monoFontTitle = Font.system(.title, design: .monospaced).weight(.semibold)
}

// MARK: - Liquid Glass Effect Modifier

struct LiquidGlassEffect: ViewModifier {
    var cornerRadius: CGFloat = 16
    var material: Material = .ultraThinMaterial
    var showBorder: Bool = true
    var shadowRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material)

                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear,
                                    Color.black.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(showBorder ? 0.25 : 0),
                                Color.white.opacity(showBorder ? 0.08 : 0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: shadowRadius, x: 0, y: 5)
    }
}

// MARK: - Glass Card Effect (for smaller elements)

struct GlassCardEffect: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}

// MARK: - Glass Header Effect

struct GlassHeaderEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1),
                alignment: .top
            )
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5),
                alignment: .bottom
            )
    }
}

// MARK: - Glass Button Effect

struct GlassButtonEffect: ViewModifier {
    var cornerRadius: CGFloat = 10
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(isPressed ? 0.1 : 0.05))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - View Extensions

extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 16,
        material: Material = .ultraThinMaterial,
        showBorder: Bool = true,
        shadowRadius: CGFloat = 10
    ) -> some View {
        modifier(LiquidGlassEffect(
            cornerRadius: cornerRadius,
            material: material,
            showBorder: showBorder,
            shadowRadius: shadowRadius
        ))
    }

    func glassCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassCardEffect(cornerRadius: cornerRadius))
    }

    func glassHeader() -> some View {
        modifier(GlassHeaderEffect())
    }

    func glassButton(cornerRadius: CGFloat = 10, isPressed: Bool = false) -> some View {
        modifier(GlassButtonEffect(cornerRadius: cornerRadius, isPressed: isPressed))
    }
}

// MARK: - Custom text field style for terminal look with glass

struct TerminalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(TerminalTheme.monoFont)
            .foregroundColor(TerminalTheme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}

// Code block style modifier with glass
struct CodeBlockStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(TerminalTheme.monoFont)
            .foregroundColor(TerminalTheme.primaryText)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 12)
    }
}

extension View {
    func codeBlockStyle() -> some View {
        modifier(CodeBlockStyle())
    }
}
