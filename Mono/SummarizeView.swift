import SwiftUI
import SwiftUI
import Combine

extension Notification.Name {
    static let summarizeSendToChat = Notification.Name("summarizeSendToChat")
}


struct SummarizeView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @StateObject private var audioManager = AudioManager.shared

    @State private var transcript: String = ""
    @State private var summary: String = ""
    @State private var isSummarizing: Bool = false
    @State private var recordingId: UUID = UUID()
    @State private var isRecording: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Transcript Input / Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcript")
                        .font(settingsManager.fontSize.captionFont)
                        .foregroundColor(.cassetteTextMedium)
                    TextEditor(text: $transcript)
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(
                            HandDrawnRoundedRectangle(cornerRadius: 10, roughness: 3)
                                .fill(Color.cassetteWarmGray.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.cassetteWarmGray.opacity(0.3), lineWidth: 1)
                        )
                }
                        HStack(spacing: 8) {
                            Button { UIPasteboard.general.string = transcript } label: { Image(systemName: "doc.on.doc") }
                            if #available(iOS 16.0, *) {
                                ShareLink(item: transcript) { Image(systemName: "square.and.arrow.up") }
                            }
                        }
                        .disabled(transcript.isEmpty)


                // Controls
                HStack(spacing: 12) {
                    Button(action: toggleRecording) {
                        HStack(spacing: 6) {
                            Image(systemName: audioManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            Text(audioManager.isRecording ? "Stop" : "Record")
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: runSummarize) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.alignleft")
                            Text("Summarize")
                        }
                    }
                    .buttonStyle(.bordered)
                    // Auto-summarize toggle
                    Toggle("Auto-summarize after recording", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "auto_summarize_after_recording") },
                        set: { UserDefaults.standard.set($0, forKey: "auto_summarize_after_recording") }
                    ))
                    .toggleStyle(.switch)

                    .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSummarizing)

                    Spacer()

                    if isSummarizing { ProgressView().scaleEffect(0.9) }
                }

                // Summary Output
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(settingsManager.fontSize.captionFont)
                        .foregroundColor(.cassetteTextMedium)
                    ScrollView {
                        Text(summary.isEmpty ? "Your summarized bullet points will appear here." : summary)
                            .font(settingsManager.fontSize.bodyFont)
                            .foregroundColor(.cassetteTextDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                    .frame(minHeight: 160)
                    .padding(8)
                    .background(
                        HandDrawnRoundedRectangle(cornerRadius: 10, roughness: 3)
                            .fill(Color.cassetteBeige.opacity(0.4))
                    )
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle("Summarize AI")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Copy
                    Button {
                        UIPasteboard.general.string = summary
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .disabled(summary.isEmpty)

                    // Share
                    if #available(iOS 16.0, *) {
                        ShareLink(item: summary) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    // Send summary to chat
                    Button {
                        UIPasteboard.general.string = summary
                        // Optional: Haptic
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        NotificationCenter.default.post(name: .summarizeSendToChat, object: summary)
                    } label: {
                        Image(systemName: "arrow.down.doc")
                    }
                    .disabled(summary.isEmpty)

                        .disabled(summary.isEmpty)
                    }

                    // Clear
                    Button(action: { transcript = ""; summary = "" }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .onAppear { _ = audioManager.isReady }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func toggleRecording() {
        Task {
            if audioManager.isRecording {
                audioManager.stopRecording(discard: false)
                // Transcribe the just-recorded audio
                do {
                    let lang = UserDefaults.standard.string(forKey: "transcription_language")
                    let language = (lang == nil || lang == "auto") ? nil : lang
                    let whisperModel = UserDefaults.standard.string(forKey: "whisper_model") ?? "whisper-large-v3-turbo"
                    let text = try await TranscriptionService.shared.transcribeGroqWhisper(messageId: recordingId, model: whisperModel, language: language)
                    transcript = text

                    // Auto-summarize if enabled
                    if UserDefaults.standard.bool(forKey: "auto_summarize_after_recording") {
                        await MainActor.run { isSummarizing = true }
                        do {
                            let result = try await SummarizationService.shared.summarize(text: text)
                            await MainActor.run { summary = result }
                        } catch {
                            await MainActor.run { errorMessage = "Auto-summarize failed: \(error.localizedDescription)" }
                        }
                        await MainActor.run { isSummarizing = false }
                    }
                } catch {
                    errorMessage = "Transcription failed: \(error.localizedDescription)"
                }
                isRecording = false
            } else {
                recordingId = UUID()
                let ok = await audioManager.startRecording(for: recordingId, quality: .high)
                if ok {
                    isRecording = true
                } else {
                    errorMessage = "Could not start recording. Check mic permissions."
                }
            }
        }
    }

    private func runSummarize() {
        Task {
            isSummarizing = true
            defer { isSummarizing = false }
            do {
                let result = try await SummarizationService.shared.summarize(text: transcript)
                summary = result
            } catch {
                errorMessage = "Summarization failed: \(error.localizedDescription)"
            }
        }
    }
}

