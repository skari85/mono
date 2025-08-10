import SwiftUI
import SwiftData

// Warm, analog color palette inspired by vintage cassette aesthetics
extension Color {
    // Warm, muted background colors
    static let cassetteBeige = Color(red: 0.95, green: 0.92, blue: 0.85)
    static let cassetteCream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let cassetteWarmGray = Color(red: 0.88, green: 0.86, blue: 0.82)
    static let cassetteDarkGray = Color(red: 0.45, green: 0.42, blue: 0.38)

    // Warm accent colors
    static let cassetteOrange = Color(red: 0.85, green: 0.52, blue: 0.25)
    static let cassetteRed = Color(red: 0.78, green: 0.35, blue: 0.32)
    static let cassetteBrown = Color(red: 0.52, green: 0.35, blue: 0.25)
    static let cassetteGold = Color(red: 0.82, green: 0.68, blue: 0.42)

    // Muted blues and greens for accents
    static let cassetteTeal = Color(red: 0.35, green: 0.58, blue: 0.55)
    static let cassetteBlue = Color(red: 0.42, green: 0.55, blue: 0.68)
    static let cassetteSage = Color(red: 0.58, green: 0.65, blue: 0.52)

    // Text colors
    static let cassetteTextDark = Color(red: 0.25, green: 0.22, blue: 0.18)
    static let cassetteTextMedium = Color(red: 0.55, green: 0.52, blue: 0.48)
}

// Analog texture overlay for that vintage cassette feel
struct PaperTexture: View {
    let opacity: Double
    let seed: UInt64

    var body: some View {
        Canvas { context, size in
            var rng = SeededRandomNumberGenerator(seed: seed)
            // Create subtle paper grain texture
            for _ in 0..<Int(size.width * size.height / 100) {
                let x = Double.random(in: 0...size.width, using: &rng)
                let y = Double.random(in: 0...size.height, using: &rng)
                let brightness = Double.random(in: 0.8...1.2, using: &rng)
                let alpha = Double.random(in: 0.1...0.3, using: &rng) * opacity

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(alpha * brightness))
                )
            }

            // Add some darker grain for depth
            for _ in 0..<Int(size.width * size.height / 200) {
                let x = Double.random(in: 0...size.width, using: &rng)
                let y = Double.random(in: 0...size.height, using: &rng)
                let alpha = Double.random(in: 0.05...0.15, using: &rng) * opacity

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.black.opacity(alpha))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// Organic typography modifiers for that hand-drawn feel
extension View {
    func organicFont(_ font: Font) -> some View {
        self
            .font(font)
            .kerning(0.2) // Slightly looser letter spacing for organic feel
    }

    func organicShadow() -> some View {
        self
            .shadow(color: .cassetteBrown.opacity(0.1), radius: 0.5, x: 0.5, y: 0.5)
    }

    func organicBreathing() -> some View {
        self
            .scaleEffect(1.0)
            .animation(
                Animation.easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
    }
}

// Custom hand-drawn style shapes with more naive, pronounced irregularities
struct HandDrawnRoundedRectangle: Shape {
    let cornerRadius: CGFloat
    let roughness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Create much more organic, sketch-like shapes with natural imperfections
        let segments = Int.random(in: 16...24) // Variable segments for organic feel
        var points: [CGPoint] = []

        // Generate organic perimeter with multiple layers of irregularity
        for i in 0..<segments {
            let progress = Double(i) / Double(segments)
            let angle = progress * 2 * .pi

            // Create natural sketch-like irregularities
            let primaryWobble = CGFloat.random(in: -roughness*1.5...roughness*1.5)
            let secondaryWobble = CGFloat.random(in: -roughness*0.3...roughness*0.3)
            let microDetail = CGFloat.random(in: -roughness*0.1...roughness*0.1)
            let totalWobble = primaryWobble + secondaryWobble + microDetail

            // Create more rectangular base shape with organic corners
            var x: CGFloat
            var y: CGFloat

            // Determine which edge we're on and add organic variation
            if angle < .pi/4 || angle > 7 * .pi/4 { // Right edge region
                x = width - cornerRadius + totalWobble
                let edgeProgress = angle < .pi/4 ? angle / (.pi/4) : (2 * .pi - angle) / (.pi/4)
                y = cornerRadius + (height - 2*cornerRadius) * edgeProgress + CGFloat.random(in: -roughness*0.8...roughness*0.8)
            } else if angle < 3 * .pi/4 { // Top edge region
                let edgeProgress = (angle - .pi/4) / (.pi/2)
                x = width - cornerRadius - (width - 2*cornerRadius) * edgeProgress + CGFloat.random(in: -roughness*0.8...roughness*0.8)
                y = cornerRadius + totalWobble
            } else if angle < 5 * .pi/4 { // Left edge region
                x = cornerRadius + totalWobble
                let edgeProgress = (angle - 3 * .pi/4) / (.pi/2)
                y = height - cornerRadius - (height - 2*cornerRadius) * edgeProgress + CGFloat.random(in: -roughness*0.8...roughness*0.8)
            } else { // Bottom edge region
                let edgeProgress = (angle - 5 * .pi/4) / (.pi/2)
                x = cornerRadius + (width - 2*cornerRadius) * edgeProgress + CGFloat.random(in: -roughness*0.8...roughness*0.8)
                y = height - cornerRadius + totalWobble
            }

            // Ensure points stay within bounds with some tolerance for organic feel
            x = max(-roughness*0.5, min(width + roughness*0.5, x))
            y = max(-roughness*0.5, min(height + roughness*0.5, y))

            points.append(CGPoint(x: x, y: y))
        }

        // Draw organic path with natural curves and line weight variation
        if !points.isEmpty {
            path.move(to: points[0])

            for i in 1..<points.count {
                let currentPoint = points[i]
                let previousPoint = points[i-1]

                // Add natural curves with slight randomness for sketch-like feel
                let shouldCurve = Bool.random() && i % 3 != 0 // Vary curve frequency

                if shouldCurve {
                    let controlOffset = CGFloat.random(in: -2...2)
                    let controlPoint = CGPoint(
                        x: (previousPoint.x + currentPoint.x) / 2 + controlOffset,
                        y: (previousPoint.y + currentPoint.y) / 2 + controlOffset
                    )
                    path.addQuadCurve(to: currentPoint, control: controlPoint)
                } else {
                    path.addLine(to: currentPoint)
                }
            }

            // Close with organic curve
            let firstPoint = points[0]
            let lastPoint = points[points.count-1]
            let controlPoint = CGPoint(
                x: (lastPoint.x + firstPoint.x) / 2 + CGFloat.random(in: -1...1),
                y: (lastPoint.y + firstPoint.y) / 2 + CGFloat.random(in: -1...1)
            )
            path.addQuadCurve(to: firstPoint, control: controlPoint)
        }

        return path
    }
}

struct HandDrawnCircle: Shape {
    let roughness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Create organic, sketch-like circle with natural imperfections
        let points = Int.random(in: 18...28) // Variable point count for organic feel
        var circlePoints: [CGPoint] = []

        // Generate points with multiple layers of natural variation
        for i in 0..<points {
            let angle = Double(i) * 2 * .pi / Double(points)

            // Layer different types of irregularities like real hand drawing
            let baseWobble = CGFloat.random(in: -roughness*2...roughness*2)
            let tremor = CGFloat.random(in: -roughness*0.4...roughness*0.4) // Hand tremor effect
            let pressure = CGFloat.random(in: -roughness*0.6...roughness*0.6) // Pressure variation
            let totalRadius = radius + baseWobble + tremor + pressure

            let x = center.x + totalRadius * cos(angle)
            let y = center.y + totalRadius * sin(angle)

            circlePoints.append(CGPoint(x: x, y: y))
        }

        // Draw with natural curves instead of straight lines
        if !circlePoints.isEmpty {
            path.move(to: circlePoints[0])

            for i in 1..<circlePoints.count {
                let currentPoint = circlePoints[i]
                let previousPoint = circlePoints[i-1]

                // Add natural sketch-like curves with varying control points
                let shouldCurve = i % 2 == 0 || Bool.random() // Mix curves and lines naturally

                if shouldCurve {
                    // Create control point with natural hand movement
                    let controlDistance = CGFloat.random(in: -roughness*0.8...roughness*0.8)
                    let controlAngle = atan2(currentPoint.y - previousPoint.y, currentPoint.x - previousPoint.x) + .pi/2
                    let controlPoint = CGPoint(
                        x: (previousPoint.x + currentPoint.x) / 2 + controlDistance * cos(controlAngle),
                        y: (previousPoint.y + currentPoint.y) / 2 + controlDistance * sin(controlAngle)
                    )
                    path.addQuadCurve(to: currentPoint, control: controlPoint)
                } else {
                    path.addLine(to: currentPoint)
                }
            }

            // Close the circle with a natural curve
            let firstPoint = circlePoints[0]
            let lastPoint = circlePoints[circlePoints.count-1]
            let closeControlDistance = CGFloat.random(in: -roughness*0.5...roughness*0.5)
            let closeControlAngle = atan2(firstPoint.y - lastPoint.y, firstPoint.x - lastPoint.x) + .pi/2
            let closeControlPoint = CGPoint(
                x: (lastPoint.x + firstPoint.x) / 2 + closeControlDistance * cos(closeControlAngle),
                y: (lastPoint.y + firstPoint.y) / 2 + closeControlDistance * sin(closeControlAngle)
            )
            path.addQuadCurve(to: firstPoint, control: closeControlPoint)
        }

        return path
    }
}

// Organic sketch-like line for dividers
struct WobblyLine: Shape {
    let roughness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = Int.random(in: 12...18) // Variable segments for natural feel
        let step = rect.width / CGFloat(points)

        // Start with natural imperfection
        let startY = rect.midY + CGFloat.random(in: -roughness*1.2...roughness*1.2)
        path.move(to: CGPoint(x: 0, y: startY))

        var previousY = startY

        for i in 1...points {
            let x = step * CGFloat(i)

            // Create natural line variation with momentum
            let momentum = (previousY - rect.midY) * 0.3 // Carry some previous direction
            let newVariation = CGFloat.random(in: -roughness*1.5...roughness*1.5)
            let microTremor = CGFloat.random(in: -roughness*0.2...roughness*0.2)
            let y = rect.midY + momentum + newVariation + microTremor

            // Add natural curves instead of straight lines
            let shouldCurve = Bool.random() && i % 2 == 0

            if shouldCurve {
                let controlY = (previousY + y) / 2 + CGFloat.random(in: -roughness*0.5...roughness*0.5)
                let controlX = x - step * 0.5 + CGFloat.random(in: -step*0.1...step*0.1)
                path.addQuadCurve(
                    to: CGPoint(x: x, y: y),
                    control: CGPoint(x: controlX, y: controlY)
                )
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }

            previousY = y
        }

        return path
    }
}

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject private var settingsManager: SettingsManager

    @State private var input = ""

    @State private var showingQuickPrompts = false
    @State private var showingSettings = false
    @State private var showingVoiceRecording = false
    @State private var selectedMessage: ChatMessage?
    @State private var keyboardHeight: CGFloat = 0
    @State private var handwritingMode = false
    @FocusState private var isInputFocused: Bool
    @State private var suggestionTopN: Int = 5
    @State private var suggestionUseContext: Bool = true
    @State private var lastSuggestion: String = ""


    init() {
        // Initialize with the shared data manager
        _viewModel = StateObject(wrappedValue: ChatViewModel(dataManager: DataManager.shared))
    }


    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Bar - Analog Mono Header
                HStack {
                    // Mono Brand with analog feel
                    HStack(spacing: 8) {
                        Text("M")
                            .organicFont(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.cassetteTextDark)
                            .organicShadow()
                        Text("o")
                            .organicFont(.largeTitle)
                            .fontWeight(.medium)
                            .foregroundColor(.cassetteOrange)
                            .organicShadow()
                        Text("n")
                            .organicFont(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.cassetteTextDark)
                            .organicShadow()
                        Text("o")
                            .organicFont(.largeTitle)
                            .fontWeight(.medium)
                            .foregroundColor(.cassetteTeal)
                            .organicShadow()
                    }
                    .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)

                    Spacer()

                    // Mode indicator (small, subtle)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cyclePersonalityMode()
                        }
                    }) {
                        Text(viewModel.currentMode.rawValue.lowercased())
                            .organicFont(settingsManager.fontSize.captionFont)
                            .fontWeight(.medium)
                            .foregroundColor(.cassetteTextMedium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 2.0)
                                    .fill(Color.cassetteWarmGray.opacity(0.6))
                            )
                    }

                    HStack(spacing: 12) {
                        // Save as Memory Button removed (cassette feature deprecated)


                        // Settings Button
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.cassetteTextDark)
                                .padding(8)
                                .background(
                                    HandDrawnCircle(roughness: 2.5)
                                        .fill(Color.cassetteBeige)
                                        .opacity(0.9)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Color.cassetteCream
                        .shadow(color: .cassetteBrown.opacity(0.15), radius: 3, x: 0, y: 2)
                )

                // Wobbly divider
                WobblyLine(roughness: 2.0)
                    .stroke(Color.cassetteBrown.opacity(0.3), lineWidth: 2)
                    .frame(height: 4)
                    .padding(.horizontal, 8)

                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message if no messages
                            if dataManager.chatMessages.isEmpty {
                                VStack(spacing: 20) {
                                    Text("👋 Welcome to Mono")
                                        .organicFont(settingsManager.fontSize.titleFont)
                                        .fontWeight(.bold)
                                        .foregroundColor(.cassetteTextDark)
                                        .organicShadow()

                                    Text("Your minimalist AI companion. Tap the + button for quick prompts, or just start typing.")
                                        .font(settingsManager.fontSize.bodyFont)
                                        .foregroundColor(.cassetteTextMedium)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                        .lineSpacing(2)

                                    // Hand-drawn style tip box
                                    VStack(spacing: 8) {
                                        Text("💡 Tip: Tap the mode name at the top to switch personalities")
                                            .font(settingsManager.fontSize.captionFont)
                                            .foregroundColor(.cassetteTeal)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                    }
                                    .background(
                                        HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 4.0)
                                            .fill(Color.cassetteTeal.opacity(0.15))
                                    )
                                }
                                .padding(.top, 80)
                                .padding(.bottom, 40)
                            }

                            ForEach(dataManager.chatMessages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                                if isValid(message.text) {
                                    MessageBubble(message: message, onAction: { action in
                                        handleMessageAction(action, for: message)
                                    }, settingsManager: settingsManager)
                                    .id(message.id)
                                }
                            }

                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text(viewModel.loadingLabel.isEmpty ? "Thinking..." : viewModel.loadingLabel)
                                            .font(.caption)
                                            .foregroundColor(.cassetteTextMedium)
                                    }
                                    .padding()
                                    .background(
                                        HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 3.0)
                                            .fill(Color.cassetteWarmGray.opacity(0.8))
                                    )
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, keyboardHeight > 0 ? 20 : 0)
                    }
                    .onChange(of: dataManager.chatMessages.count) { _, _ in
                        if let last = dataManager.chatMessages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                // Input Bar extracted to reduce compiler workload
                InputBar(
                    input: $input,
                    isInputFocused: $isInputFocused,
                    viewModel: viewModel,
                    handwritingMode: $handwritingMode,
                    showingVoiceRecording: $showingVoiceRecording,
                    suggestionTopN: $suggestionTopN,
                    suggestionUseContext: $suggestionUseContext,
                    lastSuggestion: $lastSuggestion,
                    suggestFromInput: { await suggestFromInput() },
                    insertLastSuggestionIntoChat: { await insertLastSuggestionIntoChat() },
                    onShowQuickPrompts: { showingQuickPrompts = true }
                )
                // Input bar moved into InputBar view
            }
            .background(
                ZStack {
                    // Inline toast for errors
                    if let err = viewModel.lastError {
                        VStack {
                            Spacer()
                            Toast(message: err, isError: true, actionTitle: "Retry") {
                                withAnimation { viewModel.lastError = nil }
                                Task { await viewModel.retryLast() }
                            }
                        }
                        .animation(.spring(), value: viewModel.lastError)
                    }

                    Color.cassetteWarmGray.opacity(0.3)
                    PaperTexture(opacity: 0.4, seed: 0xC0FFEECAFE)
                }
            )
        }
        .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        .sheet(isPresented: $showingQuickPrompts) {
            QuickPromptsView { prompt in
                input = prompt
                showingQuickPrompts = false
                Task {
                    await sendMessage()

                    isInputFocused = false
                }
            }
            .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        }
        .sheet(isPresented: $showingVoiceRecording) {
            VoiceRecordingView { recordingId in
                // Create a voice message
                let voiceMessage = ChatMessage(
                    text: "🎤 Voice Message",
                    isUser: true,
                    hasAudioRecording: true,
                    recordingId: recordingId
                )

                // Add to data manager
                dataManager.addChatMessage(voiceMessage)

                // Send to AI for response
                Task {
                    await viewModel.sendVoiceMessage(voiceMessage)
                }
            }
            .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        }
        .onAppear {
            if UserDefaults.standard.string(forKey: "groq_api_key") == nil {
                showingSettings = true
            }
            // App initialization complete
            // Setup keyboard notifications
            setupKeyboardNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .summarizeSendToChat)) { note in
            if let text = note.object as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let aiMessage = ChatMessage(text: text, isUser: false)
                dataManager.addChatMessage(aiMessage)
            }
        }
        .onDisappear {
            // Remove keyboard notifications
            NotificationCenter.default.removeObserver(self)
        }
    }


    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }

            let safeAreaBottom = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 0
            let adjustedHeight = max(0, keyboardFrame.height - safeAreaBottom)

            withAnimation(.easeOut(duration: duration)) {
                keyboardHeight = adjustedHeight
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }

            withAnimation(.easeOut(duration: duration)) {
                keyboardHeight = 0
            }
        }
    }

    private func sendMessage() async {
        let message = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !message.isEmpty {
            // Clear input and dismiss keyboard immediately to prevent lag
            await MainActor.run {
                input = ""
                isInputFocused = false
            }

            // Small delay to let UI update
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            await viewModel.sendMessage(message, handwritingMode: handwritingMode)
        }
    }

    private func suggestFromInput() async {
        let q = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        await MainActor.run { isInputFocused = false }
        do {
            let hints = suggestionUseContext ? buildContextHints() : nil
            let suggestion = try await SuggestionService.shared.suggest(query: q, topN: suggestionTopN, contextHints: hints)
            await MainActor.run {
                lastSuggestion = suggestion
                let aiMessage = ChatMessage(text: suggestion.isEmpty ? "[No suggestions]" : suggestion, isUser: false)
                dataManager.addChatMessage(aiMessage)
            }
        } catch {
            await MainActor.run {
                let errMsg = ChatMessage(text: "[Suggestion failed]", isUser: false)
                dataManager.addChatMessage(errMsg)
                viewModel.lastError = "Suggestion error. Check API key."
            }
        }
    }

    private func hideKeyboard() {
        isInputFocused = false
    }

    private func cyclePersonalityMode() {
        let modes = PersonalityMode.allCases
        if let currentIndex = modes.firstIndex(of: viewModel.currentMode) {
            let nextIndex = (currentIndex + 1) % modes.count
            viewModel.currentMode = modes[nextIndex]

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }

    private func handleMessageAction(_ action: MessageAction, for message: ChatMessage) {
        switch action {
        case .regenerate:
            Task {
                await viewModel.sendMessage(message.text)
            }
        case .makeShorter:
            break
        case .expandIdea:
            break
        case .surpriseMe:
            break
        }
    }

    private func buildContextHints() -> String {
        // Use last few chat messages as plain text hints
        let recent = dataManager.chatMessages.suffix(6)
        return recent.map { ($0.isUser ? "User: " : "Mono: ") + $0.text }.joined(separator: "\n")
    }

    private func insertLastSuggestionIntoChat() async {
        let text = lastSuggestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        await MainActor.run {
            let aiMessage = ChatMessage(text: text, isUser: false)
            dataManager.addChatMessage(aiMessage)
        }
    }

        }

    func isValid(_ text: String) -> Bool {
        let lower = text.lowercased()
        return !text.isEmpty && !lower.contains("nan") && !lower.contains("infinity")
    }


// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let onAction: (MessageAction) -> Void
    let settingsManager: SettingsManager

    @State private var showingActions = false
    @StateObject private var audioManager = AudioManager.shared

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 12) {
            HStack {

                if message.isUser { Spacer() }
                    if message.hasAudioRecording {
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    if audioManager.isPlaying { audioManager.stopPlayback() }
                                    else { Task { await audioManager.playAudio(for: message.id) } }
                                }) {
                                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.cassetteOrange)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.text)
                                        .font(settingsManager.fontSize.bodyFont)
                                        .fontWeight(.medium)
                                        .foregroundColor(message.isUser ? Color(white: 0.2) : Color.black)
                                    HStack(spacing: 2) {
                                        ForEach(0..<20, id: \.self) { _ in
                                            Rectangle().fill(Color.cassetteOrange.opacity(0.6))
                                                .frame(width: 2, height: CGFloat.random(in: 4...16))
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            HandDrawnRoundedRectangle(cornerRadius: 20, roughness: 5.0)
                                .fill(message.isUser ? Color.cassetteOrange.opacity(0.9) : Color.white.opacity(0.95))
                                .shadow(color: .cassetteBrown.opacity(0.2), radius: 6, x: 0, y: 4)
                        )
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
                    } else if message.isHandwritten && !message.isUser {
                        HandwrittenText(text: message.text, style: message.handwritingStyleEnum, animate: false)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    } else {
                        Text(message.text)
                            .font(settingsManager.fontSize.bodyFont)
                            .fontWeight(.medium)
                            .lineSpacing(2)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                HandDrawnRoundedRectangle(cornerRadius: 20, roughness: 5.0)
                                    .fill(message.isUser ? Color.cassetteOrange.opacity(0.9) : Color.white.opacity(0.95))
                                    .shadow(color: .cassetteBrown.opacity(0.2), radius: 6, x: 0, y: 4)
                            )
                            .foregroundColor(message.isUser ? Color(white: 0.2) : Color.black)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
                    }

                if !message.isUser { Spacer() }
            }

            if !message.isUser && showingActions {
                HStack(spacing: 20) {
                    ActionButton(title: "🔁", action: "Regenerate") {
                        onAction(.regenerate)
                        showingActions = false
                    }
                    ActionButton(title: "✂️", action: "Shorter") {
                        onAction(.makeShorter)
                        showingActions = false
                    }
                    ActionButton(title: "🌱", action: "Expand") {
                        onAction(.expandIdea)
                        showingActions = false
                    }
                    ActionButton(title: "🤯", action: "Surprise") {
                        onAction(.surpriseMe)
                        showingActions = false
                    }
                }
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let action: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title3)
                Text(action)
                    .font(.caption2)
                    .foregroundColor(.cassetteTextMedium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                    .fill(Color.cassetteWarmGray)
                    .shadow(color: .cassetteBrown.opacity(0.15), radius: 3, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Quick Prompts View
struct QuickPromptsView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager

    private let prompts = [
        "What am I missing?",
        "Write it tighter.",
        "Ask me questions.",
        "Help me think through this.",
        "Give me a fresh perspective.",
        "What's the core issue?",
        "Challenge my assumptions.",
        "Make this actionable."
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Prompts")
                    .font(settingsManager.fontSize.titleFont)
                    .fontWeight(.bold)
                    .foregroundColor(.cassetteTextDark)
                    .padding(.top)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(prompts, id: \.self) { prompt in
                        Button(action: { onSelect(prompt) }) {
                            Text(prompt)
                                .font(settingsManager.fontSize.quickPromptFont)
                                .fontWeight(.semibold)
                                .foregroundColor(.cassetteTextDark)
                                .multilineTextAlignment(.leading)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    HandDrawnRoundedRectangle(cornerRadius: 16, roughness: 5.0)
                                        .fill(Color.white.opacity(0.95))
                                        .shadow(color: .cassetteBrown.opacity(0.25), radius: 6, x: 0, y: 4)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var apiKey = ""
    @State private var showingResetAlert = false
    @State private var showingAbout = false

    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        NavigationView {
            List {
                // API Configuration Section
                Section {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.cassetteOrange)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Configuration")
                                .font(.headline)
                                .foregroundColor(.cassetteTextDark)

                            SecureField("Enter your Groq API key", text: $apiKey)
                                .textFieldStyle(.plain)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                    .padding(.vertical, 4)

                    Button(action: {
                        if let url = URL(string: "https://groq.com") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.cassetteTeal)
                                .frame(width: 24)

                            Text("Get API Key from Groq")
                                .foregroundColor(.cassetteTeal)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.cassetteTeal)
                        }
                    }
                } header: {
                    Text("Configuration")
                        .foregroundColor(.cassetteTextMedium)
                } footer: {
                    Text("Your API key is stored securely on your device and never shared.")
                        .foregroundColor(.cassetteTextMedium)
                }

                // App Preferences Section
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.cassetteBlue)
                                .frame(width: 24)

                            Text("Appearance")
                                .foregroundColor(.cassetteTextDark)
                        }
                    }

                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.cassetteRed)
                                .frame(width: 24)

                            Text("Notifications")
                                .foregroundColor(.cassetteTextDark)
                        }
                    }

                    NavigationLink(destination: ModelSettingsView()) {
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(.cassetteTeal)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Model")
                                    .foregroundColor(.cassetteTextDark)
                                Text(settingsManager.llmModel == "llama-3.1-70b" ? "Llama 3.1 70B (Quality)" : (settingsManager.llmModel == "llama-3.1-8b-instant" ? "Llama 3.1 8B (Instant)" : settingsManager.llmModel))
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                        }
                    }

                    NavigationLink(destination: TranscriptionSettingsView()) {
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .foregroundColor(.cassetteOrange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Transcription")
                                    .foregroundColor(.cassetteTextDark)
                                Text(settingsManager.transcriptionLanguage == "auto" ? "Auto-detect" : settingsManager.transcriptionLanguage.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }

                    NavigationLink(destination: WhisperModelSettingsView()) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(.cassetteTeal)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Whisper Model")
                                    .foregroundColor(.cassetteTextDark)
                                Text(settingsManager.whisperModel)
                                    .font(.caption)
                                    .foregroundColor(.cassetteTextMedium)
                            }
                        }
                    }

                        }
                    }

                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.cassetteSage)
                                .frame(width: 24)

                            Text("Privacy")
                                .foregroundColor(.cassetteTextDark)
                        }
                    }
                } header: {
                    Text("Preferences")
                        .foregroundColor(.cassetteTextMedium)
                }

                // Support Section
                Section {
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX?action=write-review") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.cassetteGold)
                                .frame(width: 24)

                            Text("Rate This App")
                                .foregroundColor(.cassetteTextDark)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }

                    Button(action: {
                        if let url = URL(string: "mailto:support@mono-app.com?subject=Mono%20Support") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.cassetteTeal)
                                .frame(width: 24)

                            Text("Contact Support")
                                .foregroundColor(.cassetteTextDark)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                } header: {
                    Text("Support")
                        .foregroundColor(.cassetteTextMedium)
                }

                // Legal Section
                Section {
                    Button(action: {
                        if let url = URL(string: "https://mono-app.com/terms") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.cassetteTextMedium)
                                .frame(width: 24)

                            Text("Terms of Service")
                                .foregroundColor(.cassetteTextDark)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }

                    Button(action: {
                        if let url = URL(string: "https://mono-app.com/privacy") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.cassetteTextMedium)
                                .frame(width: 24)

                            Text("Privacy Policy")
                                .foregroundColor(.cassetteTextDark)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                } header: {
                    Text("Legal")
                        .foregroundColor(.cassetteTextMedium)
                }

                // Data Management Section
                Section {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.cassetteRed)
                                .frame(width: 24)

                            Text("Clear All Data")
                                .foregroundColor(.cassetteRed)
                        }
                    }
                } header: {
                    Text("Data")
                        .foregroundColor(.cassetteTextMedium)
                } footer: {
                    Text("This will permanently delete all your conversations.")
                        .foregroundColor(.cassetteTextMedium)
                }

                // About Section
                Section {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.cassetteBlue)
                                .frame(width: 24)

                            Text("About Mono")
                                .foregroundColor(.cassetteTextDark)

                            Spacer()

                            Text(getAppVersion())
                                .foregroundColor(.cassetteTextMedium)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("About")
                        .foregroundColor(.cassetteTextMedium)
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.cassetteWarmGray.opacity(0.1))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save API key
                        UserDefaults.standard.set(apiKey, forKey: "groq_api_key")

                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()

                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cassetteOrange)
                }
            }
        }
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: "groq_api_key") ?? ""
        }
        .alert("Clear All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This action cannot be undone. All your conversations will be permanently deleted.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private func clearAllData() {
        // Clear UserDefaults (but preserve settings)
        let keysToPreserve = ["groq_api_key", "appearance_mode", "font_size", "notifications_enabled", "analytics_enabled", "crash_reporting_enabled"]
        let domain = Bundle.main.bundleIdentifier!
        let defaults = UserDefaults.standard
        let dictionary = defaults.persistentDomain(forName: domain) ?? [:]

        // Save preserved keys
        var preservedValues: [String: Any] = [:]
        for key in keysToPreserve {
            if let value = dictionary[key] {
                preservedValues[key] = value
            }
        }

        // Clear domain
        defaults.removePersistentDomain(forName: domain)

        // Restore preserved values
        for (key, value) in preservedValues {
            defaults.set(value, forKey: key)
        }
        defaults.synchronize()

        // Clear in-memory data
        DataManager.shared.reset()

        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)

        dismiss()
    }
}

// MARK: - Enums
enum MessageAction {
    case regenerate
    case makeShorter
    case expandIdea
    case surpriseMe
}
