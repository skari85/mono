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
        HStack(spacing: 12) {
            // Quick Prompts Button
            Button(action: onShowQuickPrompts) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cassetteOrange)
                    .padding(8)
                    .background(HandDrawnCircle(roughness: 3.0).fill(Color.cassetteOrange.opacity(0.2)))
            }

            // Input field and send button
            HStack(spacing: 8) {
                TextField("Type your message...", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .font(.body)
                    .foregroundColor(.cassetteTextDark)
                    .focused(isInputFocused)
                    .onSubmit {
                        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let message = trimmed
                        input = ""
                        Task { await viewModel.sendMessage(message, handwritingMode: handwritingMode) }
                        isInputFocused.wrappedValue = false
                    }

                Button(action: {
                    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let message = trimmed
                    input = ""
                    Task {
                        await viewModel.sendMessage(message, handwritingMode: handwritingMode)
                        isInputFocused.wrappedValue = false
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(input.trimmingCharacters(in: .whitespaces).isEmpty ? .cassetteTextMedium : .cassetteOrange)
                }
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                HandDrawnRoundedRectangle(cornerRadius: 24, roughness: 4.0)
                    .fill(Color.cassetteBeige)
                    .shadow(color: .cassetteBrown.opacity(0.15), radius: 4, x: 0, y: 3)
            )

            // Handwriting toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { handwritingMode.toggle() }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                VStack(spacing: 2) {
                    Image(systemName: handwritingMode ? "pencil.circle.fill" : "pencil.circle")
                        .font(.title2)
                        .foregroundColor(handwritingMode ? .white : .cassetteTextMedium)
                    if handwritingMode {
                        Text("ON").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                    }
                }
                .padding(8)
                .background(HandDrawnCircle(roughness: 3.0).fill(handwritingMode ? Color.cassetteTeal : Color.cassetteBeige))
            }

            // Mic button
            Button(action: { showingVoiceRecording = true }) {
                Image(systemName: "mic.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cassetteRed)
                    .padding(8)
                    .background(HandDrawnCircle(roughness: 3.0).fill(Color.cassetteRed.opacity(0.2)))
            }

            // Suggest menu
            Menu {
                Picker("Top N", selection: $suggestionTopN) {
                    Text("Top 3").tag(3)
                    Text("Top 5").tag(5)
                    Text("Top 10").tag(10)
                }
                Toggle("Use chat context", isOn: $suggestionUseContext)
                Button { Task { await suggestFromInput() } } label: { Label("Suggest now", systemImage: "sparkles") }
                if !lastSuggestion.isEmpty {
                    Button { Task { await insertLastSuggestionIntoChat() } } label: { Label("Use this summary in chat", systemImage: "arrow.down.doc") }
                }
            } label: {
                Image(systemName: "list.number")
                    .font(.title2)
                    .foregroundColor(.cassetteBlue)
                    .padding(8)
                    .background(HandDrawnCircle(roughness: 3.0).fill(Color.cassetteBlue.opacity(0.2)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cassetteCream.shadow(color: .cassetteBrown.opacity(0.15), radius: 3, x: 0, y: -2))
    }
}

