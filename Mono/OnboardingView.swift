//  OnboardingView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager

    @State private var page = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TabView(selection: $page) {
                    OnboardingPage(
                        title: "Welcome to Mono",
                        message: "A warm, minimalist place to think with AI.",
                        icon: "sparkles"
                    ).tag(0)

                    OnboardingPage(
                        title: "Voice Memories",
                        message: "Record voice notes with beautiful cassette visuals.",
                        icon: "mic.circle.fill"
                    ).tag(1)

                    OnboardingPage(
                        title: "Microphone Permission",
                        message: "Mono uses the microphone to record your voice messages. Recordings stay on your device unless you choose to share.",
                        icon: "lock.circle"
                    ).tag(2)

                    OnboardingPage(
                        title: "Summarize with one swipe",
                        message: "Swipe from the right edge to Summarize. Export as Markdown/JSON or send to Chat.",
                        icon: "list.bullet.rectangle.fill"
                    ).tag(3)

                    OnboardingPage(
                        title: "Turn Action Items into Tasks",
                        message: "Add action items to Tasks and optionally set reminders.",
                        icon: "checklist"
                    ).tag(4)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                HStack(spacing: 16) {
                    if page > 0 {
                        Button("Back") { withAnimation { page -= 1 } }
                    }
                    Spacer()
                    if page < 4 {
                        Button("Next") { withAnimation { page += 1 } }
                    } else {
                        Button("Get Started") {
                            UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cassetteOrange)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Welcome")
            .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        }
    }
}

private struct OnboardingPage: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.cassetteOrange)
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.cassetteTextDark)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.cassetteTextMedium)
                .padding(.horizontal)
        }
    }
}

