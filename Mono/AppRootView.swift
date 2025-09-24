//  AppRootView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import SwiftUI


struct AppRootView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    @State private var isAuthenticated = UserDefaults.standard.bool(forKey: "is_authenticated")

    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            if isAuthenticated {
                TabView(selection: $selectedTab) {
                    ContentView()
                        .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                        .tag(0)

                    IntelligentSearchView()
                        .tabItem { Label("Search", systemImage: "magnifyingglass") }
                        .tag(1)

                    MemoryPalaceView()
                        .tabItem { Label("Memory", systemImage: "brain.head.profile") }
                        .tag(2)

                    SummarizeView()
                        .tabItem { Label("Summarize", systemImage: "list.bullet.rectangle.fill") }
                        .tag(3)

                    TasksView()
                        .tabItem { Label("Tasks", systemImage: "checklist") }
                        .tag(4)
                }
                .environmentObject(DataManager.shared)
                .onReceive(NotificationCenter.default.publisher(for: .summarizeSendToChat)) { note in
                    guard let text = note.object as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    // Switch to chat tab and add message
                    selectedTab = 0
                    let dm = DataManager.shared
                    let msg = ChatMessage(text: "Discuss these notes:\n\n" + text, isUser: true)
                    dm.addChatMessage(msg)
                }
            } else {
                LoginView { isAuthenticated = true }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
                .onReceive(NotificationCenter.default.publisher(for: .presentSummarizeOverlay)) { _ in
                    selectedTab = 3  // Updated for new tab order
                }
                .onReceive(NotificationCenter.default.publisher(for: .startSummarizeAutoRecord)) { _ in
                    selectedTab = 3  // Updated for new tab order
                    // let SummarizeView handle auto-record onAppear
                }
                .onReceive(NotificationCenter.default.publisher(for: .switchToMemoryPalace)) { _ in
                    selectedTab = 2  // Memory Palace tab
                }
                .onReceive(NotificationCenter.default.publisher(for: .switchToSearchWithQuery)) { notification in
                    selectedTab = 1  // Search tab
                    // Pass the search query to the search view
                    if let query = notification.object as? String {
                        // Store the query for the search view to pick up
                        UserDefaults.standard.set(query, forKey: "pendingSearchQuery")
                    }
                }

        .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue {
                // Ensure state reflects stored value after dismiss
                isAuthenticated = UserDefaults.standard.bool(forKey: "is_authenticated")
            }
        }
    }
}

