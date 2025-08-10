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
                    SummarizeView()
                        .tabItem { Label("Summarize", systemImage: "list.bullet.rectangle.fill") }
                        .tag(1)
                    TasksView()
                        .tabItem { Label("Tasks", systemImage: "checklist") }
                        .tag(2)
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
                    selectedTab = 1
                }
                .onReceive(NotificationCenter.default.publisher(for: .startSummarizeAutoRecord)) { _ in
                    selectedTab = 1
                    // let SummarizeView handle auto-record onAppear
                }

        .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        .onChange(of: showOnboarding) { newValue in
            if !newValue {
                // Ensure state reflects stored value after dismiss
                isAuthenticated = UserDefaults.standard.bool(forKey: "is_authenticated")
            }
        }
    }
}

