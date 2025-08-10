//
//  SettingsViews.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import SwiftUI
import UserNotifications
import AVFoundation

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var appearanceMode: AppearanceMode = .system
    @Published var fontSize: FontSize = .medium
    @Published var notificationsEnabled: Bool = false
    @Published var analyticsEnabled: Bool = true
    @Published var crashReportingEnabled: Bool = true
    @Published var llmModel: String = UserDefaults.standard.string(forKey: "llm_model") ?? "llama-3.1-8b-instant" {
        didSet { UserDefaults.standard.set(llmModel, forKey: "llm_model") }
    }
    @Published var transcriptionLanguage: String = UserDefaults.standard.string(forKey: "transcription_language") ?? "auto" {
        didSet { UserDefaults.standard.set(transcriptionLanguage, forKey: "transcription_language") }
    }

    @Published var whisperModel: String = UserDefaults.standard.string(forKey: "whisper_model") ?? "whisper-large-v3-turbo" {
        didSet { UserDefaults.standard.set(whisperModel, forKey: "whisper_model") }
    }
    // Voice activation (VOX) preferences
    @Published var autoVoiceDetectionEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "auto_voice_detection_enabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "auto_voice_detection_enabled")
    }() { didSet { UserDefaults.standard.set(autoVoiceDetectionEnabled, forKey: "auto_voice_detection_enabled") } }
    @Published var voiceActivationThreshold: Double = {
        let v = UserDefaults.standard.double(forKey: "voice_activation_threshold")
        return v == 0 ? 0.15 : v
    }() { didSet { UserDefaults.standard.set(voiceActivationThreshold, forKey: "voice_activation_threshold") } }




    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    enum FontSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"

        var bodyFont: Font {
            switch self {
            case .small: return .callout
            case .medium: return .body
            case .large: return .title3
            }
        }

        var headlineFont: Font {
            switch self {
            case .small: return .body
            case .medium: return .headline
            case .large: return .title2
            }
        }

        var titleFont: Font {
            switch self {
            case .small: return .headline
            case .medium: return .title
            case .large: return .largeTitle
            }
        }

        var captionFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .footnote
            }
        }

        var quickPromptFont: Font {
            switch self {
            case .small: return .body
            case .medium: return .headline
            case .large: return .title3
            }
        }
    }

    init() {
        loadSettings()
    }

    private func loadSettings() {
        if let savedMode = UserDefaults.standard.string(forKey: "appearance_mode"),
           let mode = AppearanceMode(rawValue: savedMode) {
            appearanceMode = mode
        }

        if let savedFontSize = UserDefaults.standard.string(forKey: "font_size"),
           let fontSizeMode = FontSize(rawValue: savedFontSize) {
            fontSize = fontSizeMode
        }

        notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
        analyticsEnabled = UserDefaults.standard.bool(forKey: "analytics_enabled")
        crashReportingEnabled = UserDefaults.standard.bool(forKey: "crash_reporting_enabled")
    }

    func saveSettings() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearance_mode")
        UserDefaults.standard.set(fontSize.rawValue, forKey: "font_size")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled")
        UserDefaults.standard.set(analyticsEnabled, forKey: "analytics_enabled")
        UserDefaults.standard.set(crashReportingEnabled, forKey: "crash_reporting_enabled")
    }
}

// MARK: - Appearance Settings View
struct AppearanceSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(SettingsManager.AppearanceMode.allCases, id: \.self) { mode in
                    Button(action: {
                        settingsManager.appearanceMode = mode
                        settingsManager.saveSettings()

                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        HStack {
                            Text(mode.rawValue)
                                .foregroundColor(.cassetteTextDark)

                            Spacer()

                            if settingsManager.appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cassetteOrange)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text("Theme")
                    .foregroundColor(.cassetteTextMedium)
            } footer: {
                Text("Choose how Mono appears. System follows your device's appearance settings.")
                    .foregroundColor(.cassetteTextMedium)
            }

            Section {
                ForEach(SettingsManager.FontSize.allCases, id: \.self) { fontSize in
                    Button(action: {
                        settingsManager.fontSize = fontSize
                        settingsManager.saveSettings()

                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fontSize.rawValue)
                                    .font(fontSize.bodyFont)
                                    .foregroundColor(.cassetteTextDark)

                                Text("Sample text size")
                                    .font(fontSize.captionFont)
                                    .foregroundColor(.cassetteTextMedium)
                            }

                            Spacer()

                            if settingsManager.fontSize == fontSize {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cassetteOrange)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Font Size")
                    .foregroundColor(.cassetteTextMedium)
            } footer: {
                Text("Choose your preferred text size for better readability throughout the app.")
                    .foregroundColor(.cassetteTextMedium)
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cassette Aesthetic")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        Text("Hand-drawn elements and vintage colors")
                            .font(.caption)
                            .foregroundColor(.cassetteTextMedium)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cassetteOrange)
                        .font(.title2)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Visual Style")
                    .foregroundColor(.cassetteTextMedium)
            } footer: {
                Text("Mono's unique cassette tape aesthetic is always enabled to maintain the app's character.")
                    .foregroundColor(.cassetteTextMedium)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.cassetteWarmGray.opacity(0.1))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showingPermissionAlert = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { settingsManager.notificationsEnabled },
                    set: { newValue in
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            settingsManager.notificationsEnabled = false
                            settingsManager.saveSettings()
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.cassetteRed)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .foregroundColor(.cassetteTextDark)

                            Text("Get notified about app updates")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                }
                .tint(.cassetteOrange)
            } footer: {
                Text("Mono respects your privacy. Notifications are only used for important app updates and never for marketing.")
                    .foregroundColor(.cassetteTextMedium)
            }

            if settingsManager.notificationsEnabled {
                Section {
                    Button("Open Notification Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .foregroundColor(.cassetteTeal)
                } header: {
                    Text("System Settings")
                        .foregroundColor(.cassetteTextMedium)
                } footer: {
                    Text("Customize notification types and sounds in your device's Settings app.")
                        .foregroundColor(.cassetteTextMedium)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.cassetteWarmGray.opacity(0.1))
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .alert("Notification Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To enable notifications, please allow them in Settings.")
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    settingsManager.notificationsEnabled = true
                    settingsManager.saveSettings()

                    // Haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
}


// MARK: - Recording Settings View
struct RecordingSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { settingsManager.autoVoiceDetectionEnabled },
                    set: { newVal in
                        settingsManager.autoVoiceDetectionEnabled = newVal
                        settingsManager.saveSettings()
                    }
                )) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.cassetteTeal)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto Voice Detection (VOX)")
                                .font(.headline)
                                .foregroundColor(.cassetteTextDark)
                            Text("Start recording automatically when voice is detected.")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                }
                .tint(.cassetteTeal)

                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.cassetteTextMedium)
                        .frame(width: 24)
                    Text("Activation Threshold")
                        .foregroundColor(.cassetteTextDark)
                    Spacer()
                    Slider(value: Binding(
                        get: { settingsManager.voiceActivationThreshold },
                        set: { val in settingsManager.voiceActivationThreshold = val; settingsManager.saveSettings() }
                    ), in: 0.05...0.4)
                    .frame(width: 160)
                }
            } header: {
                Text("Voice Activation")
                    .foregroundColor(.cassetteTextMedium)
            } footer: {
                Text("When enabled, Summarize’s mic can start automatically based on your voice. Adjust the threshold to tune sensitivity.")
                    .foregroundColor(.cassetteTextMedium)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.cassetteWarmGray.opacity(0.1))
        .navigationTitle("Recording")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Privacy Settings View
// Custom enum to avoid iOS 17+ deprecation warnings
enum MicrophonePermissionStatus {
    case undetermined
    case denied
    case granted

    // Convert from AVAudioSession.RecordPermission
    init(from audioSessionPermission: AVAudioSession.RecordPermission) {
        switch audioSessionPermission {
        case .undetermined:
            self = .undetermined
        case .denied:
            self = .denied
        case .granted:
            self = .granted
        @unknown default:
            self = .undetermined
        }
    }


}

struct PrivacySettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var microphonePermissionStatus: MicrophonePermissionStatus = .undetermined
    @State private var showingPermissionAlert = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { settingsManager.analyticsEnabled },
                    set: { newValue in
                        settingsManager.analyticsEnabled = newValue
                        settingsManager.saveSettings()

                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                )) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.cassetteBlue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analytics")
                                .foregroundColor(.cassetteTextDark)

                            Text("Help improve Mono with usage data")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                }
                .tint(.cassetteOrange)

                Toggle(isOn: Binding(
                    get: { settingsManager.crashReportingEnabled },
                    set: { newValue in
                        settingsManager.crashReportingEnabled = newValue
                        settingsManager.saveSettings()

                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                )) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.cassetteGold)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Crash Reporting")
                                .foregroundColor(.cassetteTextDark)

                            Text("Send crash reports to help fix bugs")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                }
                .tint(.cassetteOrange)
            } footer: {
                Text("All data is anonymized and used solely to improve the app experience. No personal information or conversation content is ever collected.")
                    .foregroundColor(.cassetteTextMedium)
            }

            Section {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.cassetteSage)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local Storage")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        Text("All conversations are stored locally on your device and never sent to external servers except for AI processing.")
                            .font(.caption)
                            .foregroundColor(.cassetteTextMedium)
                    }
                }
                .padding(.vertical, 4)

                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.cassetteTeal)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Security")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        Text("Your API key is stored securely in the device keychain and transmitted only to Groq's servers for AI processing.")
                            .font(.caption)
                            .foregroundColor(.cassetteTextMedium)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Data Protection")
                    .foregroundColor(.cassetteTextMedium)
            }

            // Microphone Permission Section
            Section {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(microphonePermissionColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Microphone Access")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        Text(microphonePermissionDescription)
                            .font(.caption)
                            .foregroundColor(.cassetteTextMedium)
                    }

                    Spacer()

                    Button(action: handleMicrophonePermission) {
                        Text(microphonePermissionButtonText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(microphonePermissionColor)
                            .cornerRadius(8)
                    }
                    .disabled(microphonePermissionStatus == .granted)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Permissions")
                    .foregroundColor(.cassetteTextMedium)
            } footer: {
                Text("Mono needs microphone access to record voice messages and create audio memories. You can change this permission in Settings.")
                    .foregroundColor(.cassetteTextMedium)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.cassetteWarmGray.opacity(0.1))
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            checkMicrophonePermission()
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To use voice recording features, please enable microphone access in Settings > Privacy & Security > Microphone > Mono.")
        }
    }

    // MARK: - Microphone Permission Helpers
    private var microphonePermissionColor: Color {
        switch microphonePermissionStatus {
        case .granted:
            return .green
        case .denied:
            return .red
        case .undetermined:
            return .orange
        }
    }

    private var microphonePermissionDescription: String {
        switch microphonePermissionStatus {
        case .granted:
            return "Microphone access is enabled. You can record voice messages and create audio memories."
        case .denied:
            return "Microphone access is disabled. Enable it in Settings to use voice recording features."
        case .undetermined:
            return "Microphone permission not yet requested. Tap 'Request Access' to enable voice recording."
        }
    }

    private var microphonePermissionButtonText: String {
        switch microphonePermissionStatus {
        case .granted:
            return "Enabled"
        case .denied:
            return "Settings"
        case .undetermined:
            return "Request Access"
        }
    }

    private func checkMicrophonePermission() {
        // SAFE: Don't check permission status immediately to avoid triggering early access
        // Instead, assume undetermined and only check when user interacts
        microphonePermissionStatus = .undetermined

        // Only perform actual check when explicitly needed (when user taps)
        // This prevents early microphone access that causes the crash
    }

    private func handleMicrophonePermission() {
        // Check current permission status safely when user actually taps
        let currentStatus: AVAudioSession.RecordPermission
        if #available(iOS 17.0, *) {
            // Non-deprecated: map AVAudioApplication permission directly to our enum
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined:
                microphonePermissionStatus = .undetermined
            case .denied:
                microphonePermissionStatus = .denied
            case .granted:
                microphonePermissionStatus = .granted
            @unknown default:
                microphonePermissionStatus = .undetermined
            }
            return
        } else {
            let currentStatus = AVAudioSession.sharedInstance().recordPermission
            microphonePermissionStatus = MicrophonePermissionStatus(from: currentStatus)
        }

        switch microphonePermissionStatus {
        case .undetermined:
            requestMicrophonePermission()
        case .denied:
            showingPermissionAlert = true
        case .granted:
            // Already granted, no action needed
            break
        }
    }

    private func requestMicrophonePermission() {
        // Use proper permission request API based on iOS version
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionStatus = granted ? .granted : .denied

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: granted ? .light : .medium)
                    impactFeedback.impactOccurred()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionStatus = granted ? .granted : .denied

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: granted ? .light : .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }


// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon and Title
                    VStack(spacing: 16) {
                        // App Icon placeholder (you can replace with actual icon)
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [.cassetteOrange, .cassetteRed],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("🎧")
                                    .font(.system(size: 50))
                            )
                            .shadow(color: .cassetteBrown.opacity(0.3), radius: 8, x: 0, y: 4)

                        VStack(spacing: 4) {
                            Text("Mono")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.cassetteTextDark)

                            Text("Minimalist AI Chat")
                                .font(.headline)
                                .foregroundColor(.cassetteTextMedium)

                            Text("Version \(getAppVersion())")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About Mono")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        Text("Mono is a beautiful, minimalist AI chat application that brings the warmth of vintage cassette tapes to modern AI conversations. With its hand-drawn aesthetic and thoughtful design, Mono creates a calm, focused environment for meaningful interactions with AI.")
                            .font(.body)
                            .foregroundColor(.cassetteTextMedium)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "brain.head.profile", title: "AI Personality Modes", description: "Smart, Quiet, and Play modes for different conversation styles")
                            FeatureRow(icon: "opticaldisc", title: "Cassette Memories", description: "Organize conversations like vintage cassette tapes")
                            FeatureRow(icon: "pencil", title: "Handwriting Mode", description: "Get responses in beautiful handwritten style")
                            FeatureRow(icon: "sparkles", title: "Quick Prompts", description: "Instant conversation starters and enhancers")
                        }
                    }
                    .padding(.horizontal, 20)

                    // Technical Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Technical Details")
                            .font(.headline)
                            .foregroundColor(.cassetteTextDark)

                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Framework", value: "SwiftUI + SwiftData")
                            InfoRow(label: "AI Provider", value: "Groq API (Llama 3.1)")
                            InfoRow(label: "Storage", value: "Local SwiftData")
                            InfoRow(label: "Platform", value: "iOS 18.5+")
                            InfoRow(label: "Build", value: getBuildInfo())
                        }
                    }
                    .padding(.horizontal, 20)

                    // Links
                    VStack(spacing: 12) {
                        Button(action: {
                            if let url = URL(string: "https://github.com/skari85/mono") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .foregroundColor(.cassetteTextMedium)

                                Text("View Source Code")
                                    .foregroundColor(.cassetteTeal)
                                    .fontWeight(.medium)

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cassetteBeige.opacity(0.5))
                            )
                        }

                        Button(action: {
                            if let url = URL(string: "https://mono-app.com") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.cassetteTextMedium)

                                Text("Visit Website")
                                    .foregroundColor(.cassetteTeal)
                                    .fontWeight(.medium)

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cassetteBeige.opacity(0.5))
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Copyright
                    VStack(spacing: 8) {
                        Text("© 2025 Mono App")
                            .font(.caption)
                            .foregroundColor(.cassetteTextMedium)

                        Text("Made with ❤️ for thoughtful conversations")
                            .font(.caption)
                            .foregroundColor(.cassetteTextMedium)
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(Color.cassetteWarmGray.opacity(0.1))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cassetteOrange)
                }
            }
        }
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func getBuildInfo() -> String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Build \(build)"
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cassetteOrange)
                .frame(width: 24)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.cassetteTextDark)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.cassetteTextMedium)
                    .lineSpacing(2)
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.cassetteTextMedium)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.cassetteTextDark)
        }
    }
}
