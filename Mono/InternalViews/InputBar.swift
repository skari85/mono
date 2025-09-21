import SwiftUI

struct InputBar: View {
    @Binding var input: String
    var isInputFocused: FocusState<Bool>.Binding
    @ObservedObject var viewModel: ChatViewModel

    @Binding var handwritingMode: Bool
    @Binding var showingVoiceRecording: Bool

    @Binding var suggestionTopN: Int
    @Binding var suggestionUseContext: Bool
    @Binding var lastSuggestion: String

    let suggestFromInput: () async -> Void
    let insertLastSuggestionIntoChat: () async -> Void
    let onShowQuickPrompts: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main Input Area - Fixed layout to prevent constraint conflicts
            VStack(spacing: 12) {
                HStack {
                    Text("Message")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()

                    // Integrated suggestion menu
                    Menu {
                        Picker("Top N", selection: $suggestionTopN) {
                            Text("Top 3").tag(3)
                            Text("Top 5").tag(5)
                            Text("Top 10").tag(10)
                        }
                        Toggle("Use chat context", isOn: $suggestionUseContext)
                        Divider()
                        Button { Task { await suggestFromInput() } } label: {
                            Label("Suggest now", systemImage: "sparkles")
                        }
                        if !lastSuggestion.isEmpty {
                            Button { Task { await insertLastSuggestionIntoChat() } } label: {
                                Label("Use this summary in chat", systemImage: "arrow.down.doc")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                            Text("AI")
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                    }
                }

                // Large text input area with fixed constraints
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Type your message...", text: $input, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .submitLabel(.send)
                        .font(.body)
                        .foregroundColor(.primary)
                        .focused(isInputFocused)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isInputFocused.wrappedValue ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .onSubmit {
                            sendMessage()
                        }
                        .scrollDismissesKeyboard(.interactively)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(input.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .accentColor)
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Footer with action buttons - Fixed height to prevent constraint conflicts
            HStack(spacing: 16) {
                // Quick Prompts Button
                Button(action: onShowQuickPrompts) {
                    VStack(spacing: 2) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Prompts")
                            .font(.caption2)
                    }
                    .foregroundColor(.accentColor)
                }

                Spacer()

                // Handwriting toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { handwritingMode.toggle() }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: handwritingMode ? "pencil.circle.fill" : "pencil.circle")
                            .font(.title2)
                        Text("Write")
                            .font(.caption2)
                    }
                    .foregroundColor(handwritingMode ? .accentColor : .secondary)
                }

                Spacer()

                // Chat Mic button
                Button(action: { showingVoiceRecording = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "mic.circle.fill")
                            .font(.title2)
                        Text("Chat")
                            .font(.caption2)
                    }
                    .foregroundColor(.red)
                }

                // Summarize mic quick access
                Button(action: {
                    NotificationCenter.default.post(name: .startSummarizeAutoRecord, object: nil)
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "mic.circle.fill")
                            .font(.title2)
                        Text("Summary")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }

                Spacer()
            }
            .frame(height: 60) // Fixed height to prevent constraint conflicts
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }

    private func sendMessage() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = trimmed
        input = ""
        Task {
            await viewModel.sendMessage(message, handwritingMode: handwritingMode)
            isInputFocused.wrappedValue = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

