//
//  UserProfileView.swift
//  Monios
//
//  User profile panel with editable info and version history - Liquid Glass styling
//

import SwiftUI

struct UserProfileView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authManager: AuthManager

    @State private var profileText: String = ""
    @State private var isEditing = false
    @State private var versions: [ProfileVersion] = []
    @State private var currentVersionIndex: Int = 0

    struct ProfileVersion: Identifiable {
        let id = UUID()
        let content: String
        let timestamp: Date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView

            // Version navigation
            if versions.count > 1 {
                versionNavigator
            }

            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Info header
                    HStack(spacing: 6) {
                        Text("user profile")
                            .foregroundColor(TerminalTheme.primaryText)
                        Spacer()
                        if !isEditing {
                            Button(action: { isEditing = true }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(TerminalTheme.secondaryText)
                                    .padding(6)
                                    .glassButton(cornerRadius: 6)
                            }
                        }
                    }
                    .font(TerminalTheme.monoFont)

                    // Editable text area
                    if isEditing {
                        editingView
                    } else {
                        displayView
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            loadProfile()
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(TerminalTheme.secondaryText)
                    .padding(8)
                    .glassButton(cornerRadius: 8)
            }

            Spacer()

            Text("profile")
                .font(TerminalTheme.monoFontTitle)
                .foregroundColor(TerminalTheme.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassHeader()
    }

    private var versionNavigator: some View {
        HStack {
            Button(action: { navigateVersion(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(currentVersionIndex > 0 ? TerminalTheme.primaryText : TerminalTheme.mutedText)
                    .padding(6)
                    .glassButton(cornerRadius: 6)
            }
            .disabled(currentVersionIndex <= 0)

            Spacer()

            Text("v\(versions.count - currentVersionIndex)")
                .font(TerminalTheme.monoFontSmall)
                .foregroundColor(TerminalTheme.secondaryText)

            Text("•")
                .foregroundColor(TerminalTheme.mutedText)

            Text(formatVersionDate(versions[safe: currentVersionIndex]?.timestamp ?? Date()))
                .font(TerminalTheme.monoFontSmall)
                .foregroundColor(TerminalTheme.mutedText)

            Spacer()

            Button(action: { navigateVersion(1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(currentVersionIndex < versions.count - 1 ? TerminalTheme.primaryText : TerminalTheme.mutedText)
                    .padding(6)
                    .glassButton(cornerRadius: 6)
            }
            .disabled(currentVersionIndex >= versions.count - 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .overlay(
            Rectangle()
                .fill(AdaptiveColors.glassHighlight.opacity(0.08))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var displayView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if profileText.isEmpty {
                Text("no profile information yet.\n\ntap the pencil icon to add notes about this user - preferences, context, important details, etc.")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.mutedText)
                    .padding(16)
            } else {
                Text(profileText)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.primaryText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .glassCard(cornerRadius: 12)
    }

    private var editingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $profileText)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding(12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(TerminalTheme.accent.opacity(0.05))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TerminalTheme.accent.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: TerminalTheme.accent.opacity(0.15), radius: 8)

            HStack(spacing: 12) {
                Button(action: { cancelEditing() }) {
                    Text("cancel")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassButton(cornerRadius: 8)
                }

                Button(action: { saveProfile() }) {
                    Text("save")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [TerminalTheme.accent, TerminalTheme.accent.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [AdaptiveColors.glassHighlight.opacity(0.2), Color.clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AdaptiveColors.glassHighlight.opacity(0.3), lineWidth: 0.5)
                        )
                        .shadow(color: TerminalTheme.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadProfile() {
        // Load from UserDefaults for now
        if let data = UserDefaults.standard.data(forKey: "user_profile_versions"),
           let decoded = try? JSONDecoder().decode([SavedVersion].self, from: data) {
            versions = decoded.map { ProfileVersion(content: $0.content, timestamp: $0.timestamp) }
            currentVersionIndex = versions.count - 1
            profileText = versions.last?.content ?? ""
        } else {
            // Initialize with empty version
            let initial = ProfileVersion(content: "", timestamp: Date())
            versions = [initial]
            currentVersionIndex = 0
            profileText = ""
        }
    }

    private func saveProfile() {
        // Only save if content changed
        if profileText != versions[safe: currentVersionIndex]?.content {
            let newVersion = ProfileVersion(content: profileText, timestamp: Date())
            versions.append(newVersion)
            currentVersionIndex = versions.count - 1
            persistVersions()
        }
        isEditing = false
    }

    private func cancelEditing() {
        profileText = versions[safe: currentVersionIndex]?.content ?? ""
        isEditing = false
    }

    private func navigateVersion(_ delta: Int) {
        let newIndex = currentVersionIndex + delta
        if newIndex >= 0 && newIndex < versions.count {
            currentVersionIndex = newIndex
            profileText = versions[newIndex].content
        }
    }

    private func persistVersions() {
        let toSave = versions.map { SavedVersion(content: $0.content, timestamp: $0.timestamp) }
        if let data = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(data, forKey: "user_profile_versions")
        }
    }

    private func formatVersionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    // Helper struct for persistence
    private struct SavedVersion: Codable {
        let content: String
        let timestamp: Date
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
