//
//  Theme.swift
//  Monios
//
//  Liquid Glass themed configuration with Light/Dark mode support
//

import SwiftUI

// MARK: - Adaptive Theme Colors

struct AdaptiveColors {
    @Environment(\.colorScheme) static var colorScheme

    // Background colors
    static var background: Color {
        Color("Background")
    }

    static var surfaceBackground: Color {
        Color("SurfaceBackground")
    }

    static var cardBackground: Color {
        Color("CardBackground")
    }

    static var border: Color {
        Color("Border")
    }

    // Text colors
    static var primaryText: Color {
        Color("PrimaryText")
    }

    static var secondaryText: Color {
        Color("SecondaryText")
    }

    static var mutedText: Color {
        Color("MutedText")
    }

    // Message bubbles
    static var userMessage: Color {
        Color("UserMessage")
    }

    static var assistantMessage: Color {
        Color("AssistantMessage")
    }

    // Glass overlay colors (for borders/highlights)
    static var glassHighlight: Color {
        Color("GlassHighlight")
    }

    static var glassShadow: Color {
        Color("GlassShadow")
    }
}

struct TerminalTheme {
    // Use adaptive colors
    static var background: Color { AdaptiveColors.background }
    static var surfaceBackground: Color { AdaptiveColors.surfaceBackground }
    static var cardBackground: Color { AdaptiveColors.cardBackground }
    static var border: Color { AdaptiveColors.border }

    static var primaryText: Color { AdaptiveColors.primaryText }
    static var secondaryText: Color { AdaptiveColors.secondaryText }
    static var mutedText: Color { AdaptiveColors.mutedText }

    static var userMessage: Color { AdaptiveColors.userMessage }
    static var assistantMessage: Color { AdaptiveColors.assistantMessage }

    // Accent colors (same for both modes)
    static let accent = Color(red: 0.95, green: 0.68, blue: 0.25) // Orange/amber
    static let accentBlue = Color(red: 0.40, green: 0.60, blue: 0.95)

    // Fonts
    static let monoFont = Font.system(.body, design: .monospaced)
    static let monoFontSmall = Font.system(.caption, design: .monospaced)
    static let monoFontLarge = Font.system(.title2, design: .monospaced)
    static let monoFontTitle = Font.system(.title, design: .monospaced).weight(.semibold)
}

// MARK: - Liquid Glass Effect Modifier

struct LiquidGlassEffect: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 16
    var material: Material = .ultraThinMaterial
    var showBorder: Bool = true
    var shadowRadius: CGFloat = 10

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Native iOS 26 Liquid Glass
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            // Fallback for older iOS versions
            content
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(material)

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AdaptiveColors.glassHighlight.opacity(0.12),
                                        AdaptiveColors.glassHighlight.opacity(0.02),
                                        Color.clear,
                                        AdaptiveColors.glassShadow.opacity(0.05)
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
                                    AdaptiveColors.glassHighlight.opacity(showBorder ? 0.3 : 0),
                                    AdaptiveColors.glassHighlight.opacity(showBorder ? 0.1 : 0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: AdaptiveColors.glassShadow.opacity(0.15), radius: shadowRadius, x: 0, y: 5)
        }
    }
}

// MARK: - Glass Card Effect (for smaller elements)

struct GlassCardEffect: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AdaptiveColors.glassHighlight.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AdaptiveColors.glassHighlight.opacity(0.18), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Glass Header Effect

struct GlassHeaderEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: Rectangle())
        } else {
            content
                .background(.regularMaterial)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AdaptiveColors.glassHighlight.opacity(0.12), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
                .overlay(
                    Rectangle()
                        .fill(AdaptiveColors.glassHighlight.opacity(0.1))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
        }
    }
}

// MARK: - Glass Button Effect

struct GlassButtonEffect: ViewModifier {
    var cornerRadius: CGFloat = 10
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AdaptiveColors.glassHighlight.opacity(isPressed ? 0.12 : 0.06))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AdaptiveColors.glassHighlight.opacity(0.22), lineWidth: 0.5)
                )
                .shadow(color: AdaptiveColors.glassShadow.opacity(0.1), radius: 5, x: 0, y: 2)
        }
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
        if #available(iOS 26.0, *) {
            configuration
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.clear)
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            configuration
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(AdaptiveColors.glassHighlight.opacity(0.2), lineWidth: 0.5)
                )
        }
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

// MARK: - Liquid Glass Style Options

/// Style options for liquid glass effect
enum LiquidGlassStyle: Equatable {
    case regular
    case clear
    case tinted(Color)

    var tintColor: Color? {
        if case .tinted(let color) = self {
            return color
        }
        return nil
    }

    var material: Material {
        switch self {
        case .clear:
            return .ultraThinMaterial
        case .regular, .tinted:
            return .thinMaterial
        }
    }

    /// Convert to native iOS 26 Glass type
    @available(iOS 26.0, *)
    func toNativeGlass() -> Glass {
        switch self {
        case .regular:
            return .regular
        case .clear:
            return .clear
        case .tinted(let color):
            return .regular.tint(color)
        }
    }
}

// MARK: - Liquid Glass View Extensions

extension View {
    /// Liquid glass effect with shape - uses native iOS 26 API when available
    @ViewBuilder
    func liquidGlassEffect<S: Shape>(
        _ style: LiquidGlassStyle = .regular,
        in shape: S,
        isEnabled: Bool = true
    ) -> some View {
        if isEnabled {
            if #available(iOS 26.0, *) {
                self.glassEffect(style.toNativeGlass(), in: shape)
            } else {
                self
                    .background(
                        ZStack {
                            shape.fill(style.material)

                            if let tint = style.tintColor {
                                shape.fill(tint.opacity(0.15))
                            }

                            shape
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AdaptiveColors.glassHighlight.opacity(style == .clear ? 0.06 : 0.12),
                                            AdaptiveColors.glassHighlight.opacity(0.02),
                                            Color.clear,
                                            AdaptiveColors.glassShadow.opacity(0.04)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                    .overlay(
                        shape
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AdaptiveColors.glassHighlight.opacity(0.25),
                                        AdaptiveColors.glassHighlight.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: AdaptiveColors.glassShadow.opacity(0.12), radius: 8, x: 0, y: 4)
            }
        } else {
            self
        }
    }

    /// Convenience for RoundedRectangle shape
    func liquidGlassEffect(
        _ style: LiquidGlassStyle = .regular,
        cornerRadius: CGFloat = 16,
        isEnabled: Bool = true
    ) -> some View {
        liquidGlassEffect(style, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), isEnabled: isEnabled)
    }

    /// Convenience for Capsule shape
    func liquidGlassCapsule(
        _ style: LiquidGlassStyle = .regular,
        isEnabled: Bool = true
    ) -> some View {
        liquidGlassEffect(style, in: Capsule(), isEnabled: isEnabled)
    }
}

// MARK: - Panel Glass Effect

extension View {
    /// Optimized glass effect for side panels - uses native iOS 26 API when available
    @ViewBuilder
    func panelGlassEffect(edge: Edge) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.clear, in: Rectangle())
                .ignoresSafeArea()
        } else {
            self.background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.65))

                    LinearGradient(
                        colors: [
                            edge == .leading ? AdaptiveColors.glassHighlight.opacity(0.04) : Color.clear,
                            Color.clear,
                            edge == .trailing ? AdaptiveColors.glassHighlight.opacity(0.04) : Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .ignoresSafeArea()
            )
            .overlay(
                Rectangle()
                    .fill(AdaptiveColors.glassHighlight.opacity(0.1))
                    .frame(width: 0.5),
                alignment: edge == .leading ? .trailing : .leading
            )
        }
    }

    /// Dock-like glass effect for input bar - matches iOS home screen dock appearance
    @ViewBuilder
    func inputBarGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            // Use .regular glass for dock-like appearance
            // The dock uses a subtle tinted glass with good blur
            self
                .background(.clear)
                .glassEffect(.regular, in: Rectangle())
        } else {
            self
                .background(
                    ZStack {
                        Rectangle()
                            .fill(.regularMaterial)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AdaptiveColors.glassHighlight.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .overlay(
                    Rectangle()
                        .fill(AdaptiveColors.glassHighlight.opacity(0.08))
                        .frame(height: 0.5),
                    alignment: .top
                )
        }
    }

    /// Floating capsule glass effect - for header and input islands
    @ViewBuilder
    func floatingGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(AdaptiveColors.glassHighlight.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: AdaptiveColors.glassShadow.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
}
