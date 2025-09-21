//  AudioManager.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-07.
//

import Foundation
import AVFoundation
import SwiftUI

enum RecordingQuality: String, CaseIterable {
    case low = "Low Quality"
    case medium = "Medium Quality"
    case high = "High Quality"

    var audioSettings: [String: Any] {
        switch self {
        case .low:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 22050,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 32000,
                AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
            ]
        case .medium:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 64000,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
        case .high:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 96000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        }
    }
}

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentRecordingURL: URL?
    @Published var recordingLevel: Float = 0.0
    @Published var isReady = false

    // Playback logging (local only)
    @Published var playbackCurrentTime: TimeInterval = 0
    @Published var playbackDuration: TimeInterval = 0

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()
    private var levelTimer: Timer?
    private var playbackTimer: Timer?

    // Caches
    private var durationCache: [String: TimeInterval] = [:]

    // MARK: - Initialization
    override init() {
        super.init()
        print("🎤 Initializing AudioManager...")
        setupAudioSession()

        // Set ready state on main thread
        DispatchQueue.main.async {
            self.isReady = true
            print("✅ AudioManager initialized and ready")
        }
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            // Configure audio session for voice recording/playback but don't activate yet
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try audioSession.setPreferredSampleRate(44100)
            try audioSession.setPreferredIOBufferDuration(0.01)
            print("✅ Audio session category/mode configured for voice")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            print("❌ Audio session setup error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Audio session setup error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ Audio session setup error userInfo: \(nsError.userInfo)")
            }
        }

        // Observe interruptions and route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }

    private func activateAudioSession() throws {
        do {
            // First check if we can activate the session
            print("🎤 Checking audio session availability...")
            let currentCategory = audioSession.category
            let currentMode = audioSession.mode
            print("🎤 Current category: \(currentCategory), mode: \(currentMode)")

            // Try to activate with options to handle interruptions
            print("🎤 Attempting to activate audio session...")
            try audioSession.setActive(true, options: [])
            print("✅ Audio session activated successfully")


        } catch let error as NSError {
            print("❌ Failed to activate audio session: \(error)")
            print("❌ Audio session error details: \(error.localizedDescription)")
            print("❌ Audio session error domain: \(error.domain), code: \(error.code)")
            print("❌ Audio session error userInfo: \(error.userInfo)")

            // Handle specific audio session errors
            switch error.code {
            case AVAudioSession.ErrorCode.cannotInterruptOthers.rawValue:
                print("❌ Cannot interrupt other audio sessions")
            case AVAudioSession.ErrorCode.unspecified.rawValue:
                print("❌ Unspecified audio session error")
            case AVAudioSession.ErrorCode.incompatibleCategory.rawValue:
                print("❌ Incompatible audio category")
            default:
                print("❌ Unknown audio session error code: \(error.code)")
            }

            throw error
        }
    }

    private func deactivateAudioSession() {
        do {
            try audioSession.setActive(false)
            print("✅ Audio session deactivated")
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Permission Handling
    func checkMicrophonePermissionStatus() -> MicrophonePermissionStatus {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return .granted
            case .denied: return .denied
            case .undetermined: return .undetermined
            @unknown default: return .undetermined
            }
        } else {
            switch audioSession.recordPermission {
            case .granted: return .granted
            case .denied: return .denied
            case .undetermined: return .undetermined
            @unknown default: return .undetermined
            }
        }
    }

    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    print("🎤 Permission result: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    print("🎤 Permission result: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Session Notifications
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            print("⚠️ Audio session interruption began")
            if isRecording { stopRecording() }
            if isPlaying { stopPlayback() }
        case .ended:
            print("ℹ️ Audio session interruption ended")
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        print("ℹ️ Audio route changed: \(reason)")
        if reason == .oldDeviceUnavailable {
            // Headphones unplugged or BT disconnected: stop if recording/playing
            if isRecording { stopRecording() }
            if isPlaying { stopPlayback() }
        }
    }

    // MARK: - Recording Methods
    func startRecording(for recordingId: UUID, quality: RecordingQuality, checkPermission: Bool = true) async -> Bool {
        print("🎤 Starting recording process...")

        // Check if AudioManager is ready
        guard isReady else {
            print("❌ AudioManager not ready yet")
            return false
        }

        // Check permission if requested
        if checkPermission {
            let permissionStatus = checkMicrophonePermissionStatus()
            print("🎤 Permission status: \(permissionStatus)")

            switch permissionStatus {
            case .granted:
                print("✅ Permission granted, proceeding with recording")
            case .denied:
                print("❌ Recording failed: Permission denied")
                return false
            case .undetermined:
                print("❌ Recording failed: Permission undetermined")
                return false
            }
        }

        // Stop any existing recording
        if isRecording {
            print("🎤 Stopping existing recording...")
            stopRecording()
        }

        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingURL = documentsPath.appendingPathComponent("recording_\(recordingId.uuidString).m4a")
        print("🎤 Recording URL: \(recordingURL.path)")

        do {
            // Validate recording URL
            print("🎤 Validating recording URL...")
            let parentDirectory = recordingURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parentDirectory.path) {
                try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created directory: \(parentDirectory.path)")
            }

            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: recordingURL.path) {
                try FileManager.default.removeItem(at: recordingURL)
                print("🎤 Removed existing file at: \(recordingURL.path)")
            }

            // Activate audio session
            print("🎤 Activating audio session...")
            try activateAudioSession()

            // Validate audio settings
            print("🎤 Validating audio settings...")
            let settings = quality.audioSettings
            print("🎤 Audio settings: \(settings)")

            // Check if the format is supported (robust type handling)
            let formatID: UInt32
            if let v = settings[AVFormatIDKey] as? UInt32 {
                formatID = v
            } else if let v = settings[AVFormatIDKey] as? Int {
                formatID = UInt32(v)
            } else if let v = settings[AVFormatIDKey] as? NSNumber {
                formatID = v.uint32Value
            } else {
                throw NSError(domain: "AudioManagerError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid audio format ID"])
            }

            // Ensure sample rate is a valid number
            let sampleRate: Double
            if let d = settings[AVSampleRateKey] as? Double, d > 0 {
                sampleRate = d
            } else if let i = settings[AVSampleRateKey] as? Int, i > 0 {
                sampleRate = Double(i)
            } else if let n = settings[AVSampleRateKey] as? NSNumber, n.doubleValue > 0 {
                sampleRate = n.doubleValue
            } else {
                throw NSError(domain: "AudioManagerError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Invalid sample rate"])
            }

            print("🎤 Format ID: \(formatID), Sample Rate: \(sampleRate)")

            // Create and configure audio recorder with additional safety
            print("🎤 Creating audio recorder...")
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)

            guard let recorder = audioRecorder else {
                throw NSError(domain: "AudioManagerError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio recorder"])
            }

            recorder.delegate = self
            recorder.isMeteringEnabled = true

            // Prepare the recorder
            print("🎤 Preparing audio recorder...")
            let prepared = recorder.prepareToRecord()
            if !prepared {
                throw NSError(domain: "AudioManagerError", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare audio recorder"])
            }

            // Start recording
            print("🎤 Starting audio recorder...")
            let success = recorder.record()

            if success {
                await MainActor.run {
                    self.isRecording = true
                    self.currentRecordingURL = recordingURL
                }
                startLevelMonitoring()
                print("✅ Recording started successfully: \(recordingURL.lastPathComponent)")
                return true
            } else {
                print("❌ Failed to start recording - recorder.record() returned false")
                deactivateAudioSession()
                return false
            }

        } catch {
            print("❌ Recording setup failed with error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }

            // Clean up on error
            audioRecorder = nil
            deactivateAudioSession()
            return false
        }
    }

    func stopRecording(discard: Bool = false) {
        guard isRecording else { return }

        let url = currentRecordingURL
        stopLevelMonitoring()
        audioRecorder?.stop()
        audioRecorder = nil

        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingLevel = 0.0
        }

        deactivateAudioSession()
        print("✅ Recording stopped")

        if discard, let url {
            _ = deleteRecording(url: url)
            currentRecordingURL = nil
        }
    }

    // MARK: - Level Monitoring
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateRecordingLevel()
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateRecordingLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10.0, averagePower / 20.0)

        DispatchQueue.main.async {
            self.recordingLevel = Float(normalizedLevel)
        }
    }

    // MARK: - Playback Methods
    func startPlayback(url: URL) async -> Bool {
        // Stop any existing playback
        if isPlaying {
            stopPlayback()
        }

        do {
            // Activate audio session for playback
            try activateAudioSession()

            // Create and configure audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self

            // Prepare and capture duration
            audioPlayer?.prepareToPlay()
            let total = audioPlayer?.duration ?? 0
            await MainActor.run {
                self.playbackDuration = total
                self.playbackCurrentTime = 0
            }

            // Start playback
            let success = audioPlayer?.play() ?? false

            if success {
                await MainActor.run {
                    self.isPlaying = true
                }
                // Start progress timer
                startPlaybackTimer()

                print("✅ Playback started: \(url.lastPathComponent)")
                return true
            } else {
                print("❌ Failed to start playback")
                deactivateAudioSession()
                return false
            }

        } catch {
            print("❌ Playback setup failed: \(error)")
            deactivateAudioSession()
            return false
        }
    }

    func stopPlayback() {
        guard isPlaying else { return }

        audioPlayer?.stop()
        audioPlayer = nil

        DispatchQueue.main.async {
            self.isPlaying = false
        }

        deactivateAudioSession()
        print("✅ Playback stopped")
    }

    // MARK: - Message-based Audio Methods
    func playAudio(for messageId: UUID) async -> Bool {
        // Generate the expected audio file URL for this message
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(messageId.uuidString).m4a")

        // Check if the audio file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("❌ Audio file not found for message: \(messageId)")
            return false
        }

        // Use the existing startPlayback method
        return await startPlayback(url: audioURL)
    }

    @discardableResult
    func deleteAudioFile(for messageId: UUID) -> Bool {
        // Generate the expected audio file URL for this message
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(messageId.uuidString).m4a")

        // Use the existing deleteRecording method
        return deleteRecording(url: audioURL)
    }

    // MARK: - Utility Methods
    func getRecordingDuration(url: URL) -> TimeInterval {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            return audioPlayer.duration
        } catch {
            print("❌ Failed to get recording duration: \(error)")
            return 0
        }
    }

    func getRecordingDurationCached(for messageId: UUID) -> TimeInterval {
        let key = messageId.uuidString
        if let cached = durationCache[key] { return cached }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(messageId.uuidString).m4a")
        let d = getRecordingDuration(url: audioURL)
        durationCache[key] = d
        return d
    }

    func invalidateDurationCache(for messageId: UUID) {
        durationCache.removeValue(forKey: messageId.uuidString)
    }

    func invalidateAllDurationCache() { durationCache.removeAll() }

    func deleteRecording(url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            print("✅ Recording deleted: \(url.lastPathComponent)")
            return true
        } catch {
            print("❌ Failed to delete recording: \(error)")
            return false
        }
    }

    func getRecordingSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("❌ Failed to get recording size: \(error)")
            return 0
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
        }

        if flag {
            print("✅ Recording finished successfully")
        } else {
            print("❌ Recording finished with error")
        }

        deactivateAudioSession()
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Recording encode error: \(error?.localizedDescription ?? "Unknown error")")

        DispatchQueue.main.async {
            self.isRecording = false
        }

        deactivateAudioSession()
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.playbackCurrentTime = 0
        }
        playbackTimer?.invalidate()

        if flag {
            print("✅ Playback finished successfully")
        } else {
            print("❌ Playback finished with error")
        }

        deactivateAudioSession()
    }
    // MARK: - Progress Timer
    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        guard let _ = audioPlayer else { return }
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let p = self.audioPlayer else { return }
            DispatchQueue.main.async {
                self.playbackCurrentTime = p.currentTime
                if !p.isPlaying {
                    self.playbackTimer?.invalidate()
                }
            }
        }
    }

        func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
            print("❌ Playback decode error: \(error?.localizedDescription ?? "Unknown error")")
            DispatchQueue.main.async {
                self.isPlaying = false
                self.playbackCurrentTime = 0
            }
            playbackTimer?.invalidate()
            deactivateAudioSession()
        }
}
