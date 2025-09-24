//  OnboardingView.swift
//  Mono
//
//  Updated with new comprehensive welcome system
//

import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager
    
    @State private var showingWelcome = false

    var body: some View {
        // Launch the new comprehensive welcome system
        VStack {
            // Hidden button just to trigger the welcome on appear
            Button("Open Welcome Experience") {
                showingWelcome = true
            }
            .hidden()
            .onAppear {
                showingWelcome = true
            }
        }
        .sheet(isPresented: $showingWelcome) {
            WelcomeMainView()
                .onDisappear {
                    // Mark onboarding as completed when welcome is dismissed
                    UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                    dismiss()
                }
        }
    }
}