import SwiftUI
import Combine


extension Notification.Name {
    static let summarizeSendToChat = Notification.Name("summarizeSendToChat")
}


struct SummarizeView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var audioManager = AudioManager.shared

    @State private var transcript: String = ""
    @State private var summary: String = ""
    @State private var structuredSummary: StructuredSummary? = nil
    @State private var showingExport: Bool = false
    @State private var sharePayload: String? = nil
    @State private var isSummarizing: Bool = false
    @State private var recordingId: UUID = UUID()
    @State private var isRecording: Bool = false
    @State private var errorMessage: String?

    @State private var showDueDatePicker: Bool = false
    @State private var bulkDueDate: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24*60*60)


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Clean header
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        Text("Summarize AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.top, 8)

                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Input")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button {
                            transcript = buildChatContext()
                        } label: {
                            Image(systemName: "text.bubble")
                            Text("Use Chat")
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        .disabled(dataManager.chatMessages.isEmpty)
                    }

                    TextEditor(text: $transcript)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            Group {
                                if transcript.isEmpty {
                                    VStack {
                                        HStack {
                                            Text("Record audio, paste text, or type your notes here...")
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 4)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .padding(12)
                                    .allowsHitTesting(false)
                                }
                            }
                        )
                }


                // Controls
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: toggleRecording) {
                            HStack(spacing: 6) {
                                Image(systemName: audioManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                Text(audioManager.isRecording ? "Stop Recording" : "Record")
                            }
                            .frame(minWidth: 120)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: runSummarize) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.alignleft")
                                Text("Summarize")
                            }
                            .frame(minWidth: 100)
                        }
                        .buttonStyle(.bordered)
                        .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSummarizing)

                        Button(action: runStructured) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.grid.2x2")
                                Text("Sheets")
                            }
                            .frame(minWidth: 80)
                        }
                        .buttonStyle(.bordered)
                        .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSummarizing)
                    }

                    // Auto-summarize toggle (more compact)
                    HStack {
                        Toggle("Auto-summarize after recording", isOn: Binding(
                            get: { UserDefaults.standard.bool(forKey: "auto_summarize_after_recording") },
                            set: { UserDefaults.standard.set($0, forKey: "auto_summarize_after_recording") }
                        ))
                        .font(.caption)
                        Spacer()
                    }
                }

                // Summary Output - Main Feature
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Summary")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        if isSummarizing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let s = structuredSummary {
                                StructuredSheetsView(s: s)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                            } else {
                                Text(summary.isEmpty ? "Your summarized content will appear here.\n\nRecord audio or paste text above, then tap Summarize or Sheets to generate insights." : summary)
                                    .font(settingsManager.fontSize.bodyFont)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 300) // Much larger minimum height
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )

                    // Clean action toolbar at bottom
                    if !summary.isEmpty || structuredSummary != nil {
                        HStack(spacing: 16) {
                            Button(action: { showingExport = true }) {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }

                            if structuredSummary != nil {
                                Button(action: { saveThought() }) {
                                    Label("Save", systemImage: "tray.and.arrow.down.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            }

                            if !(structuredSummary?.actionItems.isEmpty ?? true) {
                                Button(action: { showDueDatePicker = true }) {
                                    Label("Add Tasks", systemImage: "checklist")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            }

                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { trailingToolbar }
            .sheet(isPresented: $showingExport) { exportSheet }
            .sheet(item: $sharePayload) { text in
                ActivityView(activityItems: [text])
            }

        }
        .onAppear { _ = audioManager.isReady }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: .startSummarizeAutoRecord)) { _ in
            Task { await startAutoOnVoice() }
        }
    }

    @MainActor
    private func startAutoOnVoice() async {
        // Optional voice detection controlled from Settings
        guard settingsManager.autoVoiceDetectionEnabled else { return }
        let ok = await audioManager.startRecording(for: recordingId, quality: .high)
        if !ok { errorMessage = "Could not start recording"; return }
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
                structuredSummary = nil

                summary = result

            } catch {
                errorMessage = "Summarization failed: \(error.localizedDescription)"
            }
        }
    }

    private func runStructured() {
        Task {
            isSummarizing = true
            defer { isSummarizing = false }
            do {
                let result = try await SummarizationService.shared.summarizeStructured(text: transcript)
                structuredSummary = result
                summary = result.toMarkdown()
            } catch {
                errorMessage = "Summarization failed: \(error.localizedDescription)"
            }
        }
    }
}
extension SummarizeView {
    fileprivate var trailingToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { UIPasteboard.general.string = summary } label: { Image(systemName: "doc.on.doc") }
                .disabled(summary.isEmpty)

            Button { saveThought() } label: { Image(systemName: "tray.and.arrow.down.fill") }
                .disabled(structuredSummary == nil)

            Button { showingExport = true } label: { Image(systemName: "square.and.arrow.up") }

            Button {
                UIPasteboard.general.string = summary
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                NotificationCenter.default.post(name: .summarizeSendToChat, object: summary)
            } label: { Image(systemName: "arrow.down.doc") }
            .disabled(summary.isEmpty)

            Button(action: { transcript = ""; summary = "" }) { Image(systemName: "trash") }
        }
    }

    fileprivate func saveThought() {
        guard let s = structuredSummary else { return }
        let title = (s.keyPoints.first ?? s.keyInsights.first ?? s.actionItems.first ?? "New Thought").prefix(60)
        let t = Thought(
            title: String(title),
            languageCode: UserDefaults.standard.string(forKey: "transcription_language"),
            tags: s.tags,
            keyPoints: s.keyPoints,
            actionItems: s.actionItems,
            keyInsights: s.keyInsights,
            sourceTranscript: transcript
        )
        dataManager.addThought(t)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func addActionItemsToTasks(due: Date) {
        guard let s = structuredSummary else { return }
        for item in s.actionItems {
            let lowered = item.lowercased()
            let priority: TaskPriority
            if lowered.contains("urgent") || lowered.contains("asap") || lowered.contains("high priority") || lowered.contains("immediately") {
                priority = .high
            } else if lowered.contains("maybe") || lowered.contains("later") || lowered.contains("someday") {
                priority = .low
            } else {
                priority = .normal
            }
            let t = TaskItem(title: item, dueDate: due, priority: priority)
            dataManager.addTask(t)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }


    @MainActor private func buildChatContext() -> String {
        let lines = dataManager.chatMessages.map { m in
            let speaker = m.isUser ? "You" : "Mono"
            return "\(speaker): \(m.text)"
        }
        return lines.joined(separator: "\n")
    }


    @ViewBuilder
    fileprivate var exportSheet: some View {
        let md = structuredSummary?.toMarkdown() ?? summary
        let json = structuredSummary?.toJSON(pretty: true) ?? "{}"
        NavigationView {
            List {
                Section(header: Text("Copy")) {
                    Button("Copy Plain Text") { UIPasteboard.general.string = summary }
                    Button("Copy Markdown") { UIPasteboard.general.string = md }
                    Button("Copy JSON") { UIPasteboard.general.string = json }
                    Button("Copy Checklist (Tasks)") {
                        let checklist = (structuredSummary?.actionItems ?? summary.components(separatedBy: "\n")).map { "- [ ] \($0)" }.joined(separator: "\n")
                        UIPasteboard.general.string = checklist
                    }
                }
                Section(header: Text("Share")) {
                    Button("Share Markdown") { sharePayload = md }
                    Button("Share JSON") { sharePayload = json }
                    Button("Share as HTML") {
                        let html = """
                        <html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head><body style=\"font-family:-apple-system;line-height:1.4\">
                        <h2>Summary</h2>
                        <pre>\(md.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</pre>
                        </body></html>
                        """
                        sharePayload = html
                    }
                    Button("Share as Email Draft") {
                        let subject = "Summary from Mono"
                        let body = md.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? md
                        let urlString = "mailto:?subject=\(subject)&body=\(body)"
                        if let url = URL(string: urlString) { UIApplication.shared.open(url) }
                    }
                }
                Section(header: Text("Tasks")) {
                    Button("Add Action Items to Tasks") { showDueDatePicker = true }
                        .disabled(structuredSummary?.actionItems.isEmpty ?? true)
                }
            }
            .navigationTitle("Export")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showingExport = false } } }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showDueDatePicker) {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Choose due date for action items").font(.headline)
                    DatePicker("Due", selection: $bulkDueDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    HStack {
                        Button("Today") { bulkDueDate = Calendar.current.startOfDay(for: Date()); addActionItemsToTasks(due: bulkDueDate); showDueDatePicker = false }
                        Spacer()
                        Button("Tomorrow") { bulkDueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date(); addActionItemsToTasks(due: bulkDueDate); showDueDatePicker = false }
                        Spacer()
                        Button("Use Selected") { addActionItemsToTasks(due: bulkDueDate); showDueDatePicker = false }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .navigationTitle("Set Due Date")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showDueDatePicker = false } } }
            }
            .presentationDetents([.medium])
        }

    }

}

