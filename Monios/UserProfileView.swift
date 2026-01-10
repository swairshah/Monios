//
//  UserProfileView.swift
//  Monios
//
//  User profile panel with editable info and version history
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
        .background(TerminalTheme.background)
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
                    .background(TerminalTheme.cardBackground)
                    .cornerRadius(6)
            }

            Spacer()

            Text("profile")
                .font(TerminalTheme.monoFontTitle)
                .foregroundColor(TerminalTheme.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(TerminalTheme.surfaceBackground)
        .overlay(
            Rectangle()
                .fill(TerminalTheme.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var versionNavigator: some View {
        HStack {
            Button(action: { navigateVersion(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(currentVersionIndex > 0 ? TerminalTheme.primaryText : TerminalTheme.mutedText)
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
            }
            .disabled(currentVersionIndex >= versions.count - 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(TerminalTheme.cardBackground)
        .overlay(
            Rectangle()
                .fill(TerminalTheme.border)
                .frame(height: 1),
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
        .background(TerminalTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TerminalTheme.border, lineWidth: 1)
        )
    }

    private var editingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $profileText)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.primaryText)
                .scrollContentBackground(.hidden)
                .background(TerminalTheme.cardBackground)
                .frame(minHeight: 200)
                .padding(12)
                .background(TerminalTheme.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(TerminalTheme.accent, lineWidth: 1)
                )

            HStack(spacing: 12) {
                Button(action: { cancelEditing() }) {
                    Text("cancel")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(TerminalTheme.cardBackground)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(TerminalTheme.border, lineWidth: 1)
                        )
                }

                Button(action: { saveProfile() }) {
                    Text("save")
                        .font(TerminalTheme.monoFontSmall)
                        .foregroundColor(TerminalTheme.background)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(TerminalTheme.accent)
                        .cornerRadius(6)
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
