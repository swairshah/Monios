//
//  SessionView.swift
//  Monios
//
//  Session information sidebar panel with Liquid Glass styling
//

import SwiftUI

struct SessionView: View {
    let messageCount: Int
    let sessionStartTime: Date
    @Binding var isPresented: Bool
    @ObservedObject var authManager: AuthManager
    var onClearChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // User Section
                    if let user = authManager.currentUser {
                        sectionView(title: "user") {
                            infoRow(label: "email", value: user.email)
                            if let name = user.name {
                                infoRow(label: "name", value: name)
                            }
                        }
                    }

                    // Session Info Section
                    sectionView(title: "session") {
                        infoRow(label: "started", value: formatDate(sessionStartTime))
                        infoRow(label: "duration", value: formatDuration(since: sessionStartTime))
                        infoRow(label: "messages", value: "\(messageCount)")
                        infoRow(label: "status", value: "active", valueColor: .green)
                    }

                    // Quick Actions
                    actionsSection
                }
                .padding(20)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("session")
                .font(TerminalTheme.monoFontTitle)
                .foregroundColor(TerminalTheme.primaryText)

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(TerminalTheme.secondaryText)
                    .padding(8)
                    .glassButton(cornerRadius: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassHeader()
    }

    private func sectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 12)
        }
    }

    private func infoRow(label: String, value: String, valueColor: Color = TerminalTheme.primaryText) -> some View {
        HStack {
            Text(label)
                .font(TerminalTheme.monoFontSmall)
                .foregroundColor(TerminalTheme.secondaryText)
            Spacer()
            HStack(spacing: 6) {
                if valueColor == .green {
                    Circle()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: 6, height: 6)
                        .shadow(color: .green.opacity(0.5), radius: 3)
                }
                Text(value)
                    .font(TerminalTheme.monoFontSmall)
                    .foregroundColor(valueColor == .green ? .green : valueColor)
                    .lineLimit(1)
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("actions")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)

            VStack(spacing: 8) {
                actionButton(icon: "trash", label: "clear chat", isDestructive: false) {
                    onClearChat()
                }
                actionButton(icon: "rectangle.portrait.and.arrow.right", label: "sign out", isDestructive: true) {
                    authManager.signOut()
                    isPresented = false
                }
            }
        }
    }

    private func actionButton(icon: String, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(TerminalTheme.monoFontSmall)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(TerminalTheme.mutedText)
            }
            .foregroundColor(isDestructive ? .red.opacity(0.9) : TerminalTheme.primaryText)
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)

                    if isDestructive {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.red.opacity(0.08))
                    }

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.06), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isDestructive
                            ? Color.red.opacity(0.2)
                            : Color.white.opacity(0.12),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(since date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 1 {
            return "< 1m"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}
