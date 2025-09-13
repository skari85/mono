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
                        icon: "brain.head.profile",
                        isWelcomePage: true
                    ).tag(0)

                    OnboardingPage(
                        title: "Voice Memories",
                        message: "Record voice notes with elegant simplicity.",
                        icon: "waveform.circle"
                    ).tag(1)

                    OnboardingPage(
                        title: "Microphone Permission",
                        message: "Mono uses the microphone to record your voice messages. Recordings stay on your device unless you choose to share.",
                        icon: "lock.shield"
                    ).tag(2)

                    OnboardingPage(
                        title: "Summarize with one swipe",
                        message: "Swipe from the right edge to Summarize. Export as Markdown/JSON or send to Chat.",
                        icon: "doc.text"
                    ).tag(3)

                    OnboardingPage(
                        title: "Turn Action Items into Tasks",
                        message: "Add action items to Tasks and optionally set reminders.",
                        icon: "checkmark.circle"
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.cassetteTextDark, .cassetteTextDark.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.cassetteBeige.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        }
    }
}

private struct OnboardingPage: View {
    let title: String
    let message: String
    let icon: String
    var isWelcomePage: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            if isWelcomePage {
                // Special welcome page with Monotrans logo
                VStack(spacing: 24) {
                    Image("Monotrans")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

                    VStack(spacing: 8) {
                        Text("Mono")
                            .font(.system(size: 36, weight: .light, design: .default))
                            .foregroundColor(.cassetteTextDark)
                            .tracking(2)
                    }
                }
            } else {
                // Regular pages with vintage-inspired icons
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cassetteBeige.opacity(0.3),
                                    Color.cassetteWarmGray.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.cassetteTextDark)
                }
            }

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .light, design: .default))
                    .foregroundColor(.cassetteTextDark)
                    .tracking(1)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.cassetteTextMedium)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 24)
    }
}

