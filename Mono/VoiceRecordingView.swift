//
//  VoiceRecordingView.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-07.
//

import SwiftUI
import AVFoundation
import Metal
import MetalKit

// MARK: - Numeric Validation Extensions
extension CGFloat {
    var safeValue: CGFloat {
        return self.isFinite ? self : 0.0
    }

    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        let safe = self.safeValue
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, safe))
    }
}

extension Float {
    var safeValue: Float {
        return self.isFinite ? self : 0.0
    }

    func clamped(to range: ClosedRange<Float>) -> Float {
        let safe = self.safeValue
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, safe))
    }
}

extension TimeInterval {
    var safeValue: TimeInterval {
        return self.isFinite ? self : 0.0
    }

    func clamped(to range: ClosedRange<TimeInterval>) -> TimeInterval {
        let safe = self.safeValue
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, safe))
    }
}

struct VoiceRecordingView: View {
    @StateObject private var audioManager = AudioManager.shared
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    let onRecordingComplete: (UUID) -> Void

    @State private var recordingId = UUID()
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var showingPermissionAlert = false
    @State private var showingPermissionDeniedAlert = false
    @State private var showingFirstTimePermissionAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isProcessing = false // Add loading state

    // Recording limits and quality settings
    private let maxRecordingDuration: TimeInterval = 300 // 5 minutes
    private let minRecordingDuration: TimeInterval = 0.5

    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Playback preview state
    @State private var isPlayingPreview = false
    @State private var showingQualitySettings = false
    @State private var selectedQuality: RecordingQuality = .high

    // Metal performance optimization with defensive initialization
    @State private var useOptimizedRendering = false // Default to false for safety
    private let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                mainContentView
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingQualitySettings) {
            qualitySettingsSheet
        }
        .alert("Microphone Access Needed", isPresented: $showingFirstTimePermissionAlert) {
            firstTimePermissionAlert
        } message: {
            Text("Mono needs microphone access to record your voice messages. This allows you to create audio memories and have conversations with AI. Your recordings are stored securely on your device.")
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionDeniedAlert) {
            permissionDeniedAlert
        } message: {
            Text("Mono needs microphone access to record voice messages. Please enable microphone access in Settings > Privacy & Security > Microphone > Mono.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Initialize Metal with error handling
            DispatchQueue.global(qos: .userInitiated).async {
                checkMetalPerformance()

                DispatchQueue.main.async {
                    checkMicrophonePermissionStatus()
                }
            }
        }
        .onDisappear {
            // Cleanup when view disappears
            recordingTimer?.invalidate()
            recordingTimer = nil
            if audioManager.isRecording {
                audioManager.stopRecording()
            }
            if isPlayingPreview {
                audioManager.stopPlayback()
                isPlayingPreview = false
            }
        }
    }

    private var backgroundView: some View {
        Color.cassetteWarmGray.opacity(0.3)
            .overlay(PaperTexture(opacity: 0.2, seed: 0xABCDEF01))
            .ignoresSafeArea()
    }

    private var mainContentView: some View {
        VStack(spacing: 40) {
            titleAndQualitySection
            recordingVisualizationSection
            recordingControlsSection
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
    }

    private var titleAndQualitySection: some View {
        VStack(spacing: 12) {
            Text("Voice Recording")
                .font(settingsManager.fontSize.titleFont)
                .fontWeight(.bold)
                .foregroundColor(.cassetteTextDark)

            // Quality Settings Button
            Button(action: {
                impactFeedback.impactOccurred()
                showingQualitySettings = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.system(size: 14))
                    Text(selectedQuality.rawValue)
                        .font(settingsManager.fontSize.captionFont)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(.cassetteTextMedium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.cassetteBeige.opacity(0.5))
                .cornerRadius(16)
            }
        }
    }

    private var recordingVisualizationSection: some View {
        VStack(spacing: 20) {
            microphoneIconView

            if audioManager.isRecording {
                recordingIndicatorView
            }
        }
    }

    private var microphoneIconView: some View {
        ZStack {
            Circle()
                .fill(audioManager.isRecording ? Color.cassetteOrange.opacity(0.3) : Color.cassetteBeige.opacity(0.5))
                .frame(width: 120, height: 120)
                .scaleEffect(audioManager.isRecording ? 1.1 + Double(audioManager.recordingLevel) * 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: audioManager.recordingLevel)

            Image(systemName: "mic.fill")
                .font(.system(size: 40))
                .foregroundColor(audioManager.isRecording ? .cassetteOrange : .cassetteTextMedium)
        }
    }

    private var recordingIndicatorView: some View {
        VStack(spacing: 8) {
            Text("Recording...")
                .font(settingsManager.fontSize.headlineFont)
                .foregroundColor(.cassetteOrange)

            waveformView

            VStack(spacing: 4) {
                Text(formatDuration(recordingDuration))
                    .font(settingsManager.fontSize.bodyFont)
                    .foregroundColor(recordingDuration > maxRecordingDuration * 0.9 ? .red : .cassetteTextMedium)
                    .monospacedDigit()

                // Duration limit indicator
                Text("Max: \(formatDuration(maxRecordingDuration))")
                    .font(settingsManager.fontSize.captionFont)
                    .foregroundColor(.cassetteTextMedium.opacity(0.7))
            }
        }
    }

    private var waveformView: some View {
        Group {
            if useOptimizedRendering && metalDevice != nil {
                // High-performance Metal-optimized version with error handling
                OptimizedWaveformView(
                    recordingLevel: audioManager.recordingLevel,
                    isRecording: audioManager.isRecording,
                    useMetalOptimization: useOptimizedRendering
                )
                .frame(height: 40)
            } else {
                // Fallback simple visualization for compatibility
                SimpleWaveformView(
                    recordingLevel: audioManager.recordingLevel,
                    isRecording: audioManager.isRecording
                )
                .frame(height: 40)
            }
        }
    }

    private var recordingControlsSection: some View {
        Group {
            if !audioManager.isRecording {
                VStack(spacing: 8) {
                    Text("Tap to start recording")
                        .font(settingsManager.fontSize.bodyFont)
                        .foregroundColor(.cassetteTextMedium)

                    if recordingDuration > 0 {
                        Text("Recording saved: \(formatDuration(recordingDuration))")
                            .font(settingsManager.fontSize.captionFont)
                            .foregroundColor(.green)
                    }
                }
            }

            controlButtonsView
        }
    }

    private var controlButtonsView: some View {
        HStack(spacing: 40) {
            cancelButton
            recordStopButton

            if audioManager.isRecording {
                saveButton
            }
        }
    }

    private var cancelButton: some View {
        Button(action: {
            if audioManager.isRecording {
                stopRecording(save: false)
            } else {
                dismiss()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.cassetteTextMedium)

                Text("Cancel")
                    .font(settingsManager.fontSize.captionFont)
                    .foregroundColor(.cassetteTextMedium)
            }
        }
    }

    private var recordStopButton: some View {
        Button(action: {
            if audioManager.isRecording {
                stopRecording(save: true)
            } else {
                startRecording()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .cassetteOrange))
                    } else {
                        Image(systemName: audioManager.isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(audioManager.isRecording ? .red : .cassetteOrange)
                    }
                }

                Text(isProcessing ? "Processing..." : (audioManager.isRecording ? "Stop" : "Record"))
                    .font(settingsManager.fontSize.captionFont)
                    .foregroundColor(.cassetteTextDark)
            }
        }
        .disabled(isProcessing)
    }

    private var saveButton: some View {
        Group {
            if !audioManager.isRecording && recordingDuration > 0 {
                HStack(spacing: 20) {
                    previewButton
                    finalSaveButton
                }
            }
        }
    }

    private var previewButton: some View {
        Button(action: {
            impactFeedback.impactOccurred()
            togglePreviewPlayback()
        }) {
            VStack(spacing: 8) {
                Image(systemName: isPlayingPreview ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.cassetteBlue)

                Text(isPlayingPreview ? "Pause" : "Preview")
                    .font(settingsManager.fontSize.captionFont)
                    .foregroundColor(.cassetteTextDark)
            }
        }
    }

    private var finalSaveButton: some View {
        Button(action: {
            notificationFeedback.notificationOccurred(.success)
            saveRecording()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.green)

                Text("Save")
                    .font(settingsManager.fontSize.captionFont)
                    .foregroundColor(.cassetteTextDark)
            }
        }
    }

    private var firstTimePermissionAlert: some View {
        Group {
            Button("Allow Access") {
                handleFirstTimePermissionRequest()
            }
            Button("Not Now", role: .cancel) {
                // User declined, do nothing
            }
        }
    }

    private var permissionDeniedAlert: some View {
        Group {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
    }

    private var qualitySettingsSheet: some View {
        QualitySettingsView(selectedQuality: $selectedQuality, settingsManager: settingsManager)
    }
    
    private func startRecording() {
        guard !isProcessing else { return }

        // Haptic feedback for start
        impactFeedback.impactOccurred()

        recordingId = UUID()
        recordingDuration = 0
        isProcessing = true

        Task {
            defer { isProcessing = false }

            // Check current permission status first
            let currentPermissionStatus = audioManager.checkMicrophonePermissionStatus()

            switch currentPermissionStatus {
            case .undetermined:
                // First time - show informative alert before requesting permission
                print("🎤 First time microphone access - showing informative alert")
                await MainActor.run {
                    showingFirstTimePermissionAlert = true
                }
                return

            case .denied:
                // Permission was previously denied - show settings alert
                print("❌ Microphone permission previously denied")
                await MainActor.run {
                    showingPermissionDeniedAlert = true
                }
                notificationFeedback.notificationOccurred(.error)
                return

            case .granted:
                // Permission already granted - proceed with recording
                print("✅ Microphone permission already granted - starting recording")
                break
            }

            // Request permission if needed and start recording
            print("🎤 Requesting microphone permission")
            let permissionGranted = await audioManager.requestMicrophonePermission()

            if !permissionGranted {
                notificationFeedback.notificationOccurred(.error)
                await MainActor.run {
                    showingPermissionDeniedAlert = true
                }
                print("❌ Microphone permission not granted")
                return
            }

            print("✅ Microphone permission confirmed - starting recording")
            let success = await audioManager.startRecording(for: recordingId, quality: selectedQuality, checkPermission: false)
            if success {
                startTimer()
                notificationFeedback.notificationOccurred(.success)
                print("✅ Voice recording started in UI")
            } else {
                notificationFeedback.notificationOccurred(.error)
                errorMessage = "Failed to start recording. Please try again."
                showingErrorAlert = true
            }
        }
    }
    
    private func stopRecording(save: Bool) {
        guard !isProcessing else { return }
        isProcessing = true

        // Haptic feedback for stop
        impactFeedback.impactOccurred()

        audioManager.stopRecording(discard: !save)
        recordingTimer?.invalidate()
        recordingTimer = nil

        defer { isProcessing = false }

        if save && recordingDuration >= minRecordingDuration {
            notificationFeedback.notificationOccurred(.success)
            saveRecording()
        } else if !save {
            // Delete the recording file if not saving
            audioManager.deleteAudioFile(for: recordingId)
            dismiss()
        } else if save && recordingDuration < minRecordingDuration {
            // Show error for too short recording
            notificationFeedback.notificationOccurred(.error)
            errorMessage = "Recording too short. Please record for at least \(minRecordingDuration) seconds."
            showingErrorAlert = true
            audioManager.deleteAudioFile(for: recordingId)
        }
    }
    
    private func saveRecording() {
        onRecordingComplete(recordingId)
        dismiss()
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                // Safe duration increment
                let increment: TimeInterval = 0.1
                let newDuration = (recordingDuration + increment).safeValue
                recordingDuration = newDuration.clamped(to: 0.0...maxRecordingDuration)

                // Auto-stop when reaching maximum duration
                if recordingDuration >= maxRecordingDuration {
                    stopRecording(save: true)
                    let maxMinutes = Int(maxRecordingDuration / 60)
                    errorMessage = "Recording stopped automatically after reaching maximum duration of \(maxMinutes) minutes."
                    showingErrorAlert = true
                }

                // Warning haptic at 90% of max duration
                let warningThreshold = maxRecordingDuration * 0.9
                let warningWindow = warningThreshold + 0.2
                if recordingDuration >= warningThreshold && recordingDuration < warningWindow {
                    notificationFeedback.notificationOccurred(.warning)
                }
            }
        }
    }
    
    private func togglePreviewPlayback() {
        if isPlayingPreview {
            audioManager.stopPlayback()
            isPlayingPreview = false
        } else {
            Task {
                let success = await audioManager.playAudio(for: recordingId)
                if success {
                    isPlayingPreview = true
                    // Monitor playback completion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        checkPlaybackStatus()
                    }
                } else {
                    errorMessage = "Failed to play preview. Please try again."
                    showingErrorAlert = true
                }
            }
        }
    }

    private func checkPlaybackStatus() {
        if !audioManager.isPlaying && isPlayingPreview {
            isPlayingPreview = false
        } else if audioManager.isPlaying && isPlayingPreview {
            // Continue checking
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkPlaybackStatus()
            }
        }
    }

    private func checkMetalPerformance() {
        // Check if Metal is available and working properly
        guard let device = metalDevice else {
            print("⚠️ Metal device not available, using fallback rendering")
            useOptimizedRendering = false
            return
        }

        // Test Metal functionality with error handling
        if let commandQueue = device.makeCommandQueue() {
            // Test command queue creation
            let commandBuffer = commandQueue.makeCommandBuffer()
            if commandBuffer != nil {
                useOptimizedRendering = true
                print("✅ Metal rendering enabled")
            } else {
                print("⚠️ Metal command buffer creation failed, using fallback")
                useOptimizedRendering = false
            }
        } else {
            print("⚠️ Metal command queue creation failed, using fallback")
            useOptimizedRendering = false
        }
    }

    private func checkMicrophonePermissionStatus() {
        // Use AudioManager's permission check to avoid direct AVAudioSession access
        let permissionStatus = audioManager.checkMicrophonePermissionStatus()
        switch permissionStatus {
        case .undetermined:
            // Permission will be requested when user tries to record
            break
        case .denied:
            showingPermissionDeniedAlert = true
        case .granted:
            // Permission is already granted
            break
        @unknown default:
            break
        }
    }

    private func handleFirstTimePermissionRequest() {
        Task {
            print("🎤 Handling first-time permission request")
            let permissionGranted = await audioManager.requestMicrophonePermission()

            await MainActor.run {
                if permissionGranted {
                    print("✅ First-time permission granted - starting recording")
                    // Permission granted, now start recording
                    startRecordingAfterPermission()
                } else {
                    print("❌ First-time permission denied")
                    showingPermissionDeniedAlert = true
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }

    private func startRecordingAfterPermission() {
        guard !isProcessing else { return }

        recordingId = UUID()
        recordingDuration = 0
        isProcessing = true

        Task {
            defer { isProcessing = false }

            print("✅ Starting recording after permission granted")
            let success = await audioManager.startRecording(for: recordingId, quality: selectedQuality, checkPermission: false)
            if success {
                startTimer()
                notificationFeedback.notificationOccurred(.success)
                print("✅ Voice recording started in UI")
            } else {
                notificationFeedback.notificationOccurred(.error)
                errorMessage = "Failed to start recording. Please try again."
                showingErrorAlert = true
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        // Ensure duration is a valid number
        let safeDuration = duration.isFinite ? max(0, duration) : 0.0

        let minutes = Int(safeDuration) / 60
        let seconds = Int(safeDuration) % 60
        let remainder = safeDuration.truncatingRemainder(dividingBy: 1)
        let centiseconds = Int(remainder.isFinite ? remainder * 10 : 0)

        return String(format: "%02d:%02d.%01d", minutes, seconds, centiseconds)
    }
}

// MARK: - Optimized Waveform Components
struct OptimizedWaveformView: View {
    let recordingLevel: Float
    let isRecording: Bool
    let useMetalOptimization: Bool

    private var safeRecordingLevel: Float {
        recordingLevel.clamped(to: 0.0...1.0)
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<20, id: \.self) { index in
                let normalizedIndex = Float(index) / 20.0
                let isActive = safeRecordingLevel > normalizedIndex
                let baseHeight = CGFloat(12 + (index % 5) * 4).safeValue
                let dynamicComponent = CGFloat(safeRecordingLevel * 15).safeValue
                let dynamicHeight = baseHeight + dynamicComponent
                let finalHeight = dynamicHeight.clamped(to: 8.0...40.0)

                Rectangle()
                    .fill(isActive ? Color.cassetteOrange : Color.cassetteTextMedium.opacity(0.2))
                    .frame(width: 3, height: finalHeight)
                    .animation(.linear(duration: 0.1), value: safeRecordingLevel)
            }
        }
        .modifier(ConditionalMetalOptimization(useOptimization: useMetalOptimization))
    }
}

// Custom modifier to conditionally apply Metal optimization
struct ConditionalMetalOptimization: ViewModifier {
    let useOptimization: Bool
    
    func body(content: Content) -> some View {
        if useOptimization {
            // Only apply drawingGroup if Metal is working properly
            content.drawingGroup()
        } else {
            // Use standard rendering without Metal acceleration
            content
        }
    }
}

struct SimpleWaveformView: View {
    let recordingLevel: Float
    let isRecording: Bool

    private var safeRecordingLevel: Float {
        recordingLevel.clamped(to: 0.0...1.0)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                let normalizedIndex = Float(index) / 10.0
                let isActive = safeRecordingLevel > normalizedIndex
                let baseHeight = CGFloat(8 + index * 3).safeValue
                let height = baseHeight.clamped(to: 8.0...35.0)

                Rectangle()
                    .fill(isActive ? Color.cassetteOrange : Color.cassetteTextMedium.opacity(0.3))
                    .frame(width: 4, height: height)
                    .animation(.easeInOut(duration: 0.2), value: safeRecordingLevel)
            }
        }
    }
}

// MARK: - Quality Settings View
struct QualitySettingsView: View {
    @Binding var selectedQuality: RecordingQuality
    let settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.cassetteWarmGray.opacity(0.3)
                    .overlay(PaperTexture(opacity: 0.2, seed: 0xABCDEF02))
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Recording Quality")
                        .font(settingsManager.fontSize.titleFont)
                        .fontWeight(.bold)
                        .foregroundColor(.cassetteTextDark)
                        .padding(.top, 20)

                    VStack(spacing: 16) {
                        ForEach(RecordingQuality.allCases, id: \.self) { quality in
                            Button(action: {
                                selectedQuality = quality
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(quality.rawValue)
                                            .font(settingsManager.fontSize.bodyFont)
                                            .fontWeight(.medium)
                                            .foregroundColor(.cassetteTextDark)

                                        Text(qualityDescription(for: quality))
                                            .font(settingsManager.fontSize.captionFont)
                                            .foregroundColor(.cassetteTextMedium)
                                    }

                                    Spacer()

                                    if selectedQuality == quality {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.cassetteOrange)
                                            .font(.system(size: 20))
                                    } else {
                                        Circle()
                                            .stroke(Color.cassetteTextMedium.opacity(0.3), lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedQuality == quality ? Color.cassetteOrange.opacity(0.1) : Color.cassetteBeige.opacity(0.3))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cassetteOrange)
                }
            }
        }
    }

    private func qualityDescription(for quality: RecordingQuality) -> String {
        switch quality {
        case .low:
            return "22kHz, smaller file size"
        case .medium:
            return "44kHz, balanced quality"
        case .high:
            return "44kHz, best quality"
        }
    }
}

#Preview {
    VoiceRecordingView { _ in
        // Preview completion handler
    }
}
