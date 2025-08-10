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
    
    var body: some View {
        ZStack {
            if isAuthenticated {
                TabView {
                    ContentView()
                        .tabItem {
                            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                    SummarizeView()
                        .tabItem {
                            Label("Summarize", systemImage: "list.bullet.rectangle.fill")
                        }
                }
                .environmentObject(DataManager.shared)
            } else {
                LoginView { isAuthenticated = true }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
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

