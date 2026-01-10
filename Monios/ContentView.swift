//
//  ContentView.swift
//  Monios
//
//  Root view with authentication and swipeable panels
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var messages: [Message] = []
    @State private var showSessionPanel = false
    @State private var showProfilePanel = false
    @State private var leftDragOffset: CGFloat = 0
    @State private var rightDragOffset: CGFloat = 0
    @State private var sessionStartTime = Date()

    // Panel configuration
    private let panelWidth: CGFloat = 300
    private let dragThreshold: CGFloat = 100
    private let edgeDragWidth: CGFloat = 60

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                authenticatedView
            } else {
                LoginView(authManager: authManager)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var authenticatedView: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Chat View
                ChatView(messages: $messages, authManager: authManager)
                    .frame(width: geometry.size.width)

                // Dimmed overlay when any panel is visible
                if showSessionPanel || showProfilePanel || leftDragOffset > 0 || rightDragOffset < 0 {
                    Color.black
                        .opacity(overlayOpacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showSessionPanel = false
                                showProfilePanel = false
                                leftDragOffset = 0
                                rightDragOffset = 0
                            }
                        }
                }

                // Left Panel - Session (swipe right to open)
                if showSessionPanel || leftDragOffset > 0 {
                    SessionView(
                        messageCount: messages.count,
                        sessionStartTime: sessionStartTime,
                        isPresented: $showSessionPanel,
                        authManager: authManager,
                        onClearChat: { messages.removeAll() }
                    )
                    .frame(width: panelWidth)
                    .transition(.move(edge: .leading))
                    .offset(x: -geometry.size.width / 2 + panelWidth / 2 + leftPanelOffset)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 5, y: 0)
                }

                // Right Panel - User Profile (swipe left to open)
                if showProfilePanel || rightDragOffset < 0 {
                    UserProfileView(
                        isPresented: $showProfilePanel,
                        authManager: authManager
                    )
                    .frame(width: panelWidth)
                    .transition(.move(edge: .trailing))
                    .offset(x: geometry.size.width / 2 - panelWidth / 2 + rightPanelOffset)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: -5, y: 0)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDragChange(value: value, screenWidth: geometry.size.width)
                    }
                    .onEnded { value in
                        handleDragEnd(value: value, screenWidth: geometry.size.width)
                    }
            )
        }
    }

    // MARK: - Computed Properties

    private var leftPanelOffset: CGFloat {
        if showSessionPanel {
            return leftDragOffset
        } else {
            return -panelWidth + leftDragOffset
        }
    }

    private var rightPanelOffset: CGFloat {
        if showProfilePanel {
            return rightDragOffset
        } else {
            return panelWidth + rightDragOffset
        }
    }

    private var overlayOpacity: Double {
        let leftProgress = (showSessionPanel ? panelWidth + leftDragOffset : leftDragOffset) / panelWidth
        let rightProgress = (showProfilePanel ? panelWidth - rightDragOffset : -rightDragOffset) / panelWidth
        let progress = max(leftProgress, rightProgress)
        return min(0.4, progress * 0.4)
    }

    // MARK: - Gesture Handling

    private func handleDragChange(value: DragGesture.Value, screenWidth: CGFloat) {
        let translation = value.translation.width
        let startX = value.startLocation.x

        // Left panel (Session) - swipe from left edge
        if showSessionPanel {
            if translation < 0 {
                leftDragOffset = max(-panelWidth, translation)
            }
        } else if !showProfilePanel && startX < edgeDragWidth && translation > 0 {
            leftDragOffset = min(panelWidth, translation)
        }

        // Right panel (Profile) - swipe from right edge
        if showProfilePanel {
            if translation > 0 {
                rightDragOffset = min(panelWidth, translation)
            }
        } else if !showSessionPanel && startX > screenWidth - edgeDragWidth && translation < 0 {
            rightDragOffset = max(-panelWidth, translation)
        }
    }

    private func handleDragEnd(value: DragGesture.Value, screenWidth: CGFloat) {
        let translation = value.translation.width
        let velocity = value.predictedEndTranslation.width - translation

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            // Handle left panel
            if showSessionPanel {
                if translation < -dragThreshold || velocity < -500 {
                    showSessionPanel = false
                }
                leftDragOffset = 0
            } else if leftDragOffset > 0 {
                if translation > dragThreshold || velocity > 500 {
                    showSessionPanel = true
                }
                leftDragOffset = 0
            }

            // Handle right panel
            if showProfilePanel {
                if translation > dragThreshold || velocity > 500 {
                    showProfilePanel = false
                }
                rightDragOffset = 0
            } else if rightDragOffset < 0 {
                if translation < -dragThreshold || velocity < -500 {
                    showProfilePanel = true
                }
                rightDragOffset = 0
            }
        }
    }
}

#Preview {
    ContentView()
}
