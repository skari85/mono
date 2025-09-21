import SwiftUI
import EventKit
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

    // Muted blues and greens for accents - enhanced for dark mode
    static let cassetteTeal = Color(red: 0.45, green: 0.68, blue: 0.65)
    static let cassetteBlue = Color(red: 0.42, green: 0.55, blue: 0.68)
    static let cassetteSage = Color(red: 0.58, green: 0.65, blue: 0.52)

    // Text colors - adaptive for dark mode
    static let cassetteTextDark = Color.primary
    static let cassetteTextMedium = Color.secondary
}

// Analog texture overlay for that vintage cassette feel
struct PaperTexture: View {
    let opacity: Double
    let seed: UInt64

    var body: some View {
        Canvas { context, size in
            // Guard against invalid dimensions
            guard size.width > 0 && size.height > 0 && size.width.isFinite && size.height.isFinite else {
                return
            }

            var rng = SeededRandomNumberGenerator(seed: seed)
            let area = size.width * size.height

            // Create subtle paper grain texture
            let grainCount = max(0, Int(area / 100))
            for _ in 0..<grainCount {
                let x = Double.random(in: 0...size.width, using: &rng)
                let y = Double.random(in: 0...size.height, using: &rng)
                let brightness = Double.random(in: 0.8...1.2, using: &rng)
                let alpha = Double.random(in: 0.1...0.3, using: &rng) * opacity

                // Ensure alpha is valid
                let finalAlpha = (alpha * brightness).isFinite ? alpha * brightness : 0.1

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(finalAlpha))
                )
            }

            // Add some darker grain for depth
            let darkGrainCount = max(0, Int(area / 200))
            for _ in 0..<darkGrainCount {
                let x = Double.random(in: 0...size.width, using: &rng)
                let y = Double.random(in: 0...size.height, using: &rng)
                let alpha = Double.random(in: 0.05...0.15, using: &rng) * opacity

                // Ensure alpha is valid
                let finalAlpha = alpha.isFinite ? alpha : 0.1

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.black.opacity(finalAlpha))
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

        // Guard against invalid dimensions
        guard width > 0 && height > 0 && width.isFinite && height.isFinite &&
              cornerRadius.isFinite && roughness.isFinite else {
            return path
        }

        // Create much more organic, sketch-like shapes with natural imperfections
        let segments = Int.random(in: 16...24) // Variable segments for organic feel
        var points: [CGPoint] = []

        // Generate organic perimeter with multiple layers of irregularity
        for i in 0..<segments {
            let progress = Double(i) / Double(segments)
            let angle = progress * 2 * .pi

            // Create natural sketch-like irregularities with bounds checking
            let safeRoughness = max(0, min(roughness, min(width, height) / 4))
            let primaryWobble = CGFloat.random(in: -safeRoughness*1.5...safeRoughness*1.5)
            let secondaryWobble = CGFloat.random(in: -safeRoughness*0.3...safeRoughness*0.3)
            let microDetail = CGFloat.random(in: -safeRoughness*0.1...safeRoughness*0.1)
            let totalWobble = primaryWobble + secondaryWobble + microDetail

            // Create more rectangular base shape with organic corners
            var x: CGFloat
            var y: CGFloat

            // Determine which edge we're on and add organic variation
            let safeCornerRadius = max(0, min(cornerRadius, min(width, height) / 2))

            if angle < .pi/4 || angle > 7 * .pi/4 { // Right edge region
                x = width - safeCornerRadius + totalWobble
                let edgeProgress = angle < .pi/4 ? angle / (.pi/4) : (2 * .pi - angle) / (.pi/4)
                y = safeCornerRadius + (height - 2*safeCornerRadius) * edgeProgress + CGFloat.random(in: -safeRoughness*0.8...safeRoughness*0.8)
            } else if angle < 3 * .pi/4 { // Top edge region
                let edgeProgress = (angle - .pi/4) / (.pi/2)
                x = width - safeCornerRadius - (width - 2*safeCornerRadius) * edgeProgress + CGFloat.random(in: -safeRoughness*0.8...safeRoughness*0.8)
                y = safeCornerRadius + totalWobble
            } else if angle < 5 * .pi/4 { // Left edge region
                x = safeCornerRadius + totalWobble
                let edgeProgress = (angle - 3 * .pi/4) / (.pi/2)
                y = height - safeCornerRadius - (height - 2*safeCornerRadius) * edgeProgress + CGFloat.random(in: -safeRoughness*0.8...safeRoughness*0.8)
            } else { // Bottom edge region
                let edgeProgress = (angle - 5 * .pi/4) / (.pi/2)
                x = safeCornerRadius + (width - 2*safeCornerRadius) * edgeProgress + CGFloat.random(in: -safeRoughness*0.8...safeRoughness*0.8)
                y = height - safeCornerRadius + totalWobble
            }

            // Ensure points stay within bounds with some tolerance for organic feel
            x = max(-safeRoughness*0.5, min(width + safeRoughness*0.5, x))
            y = max(-safeRoughness*0.5, min(height + safeRoughness*0.5, y))

            // Final validation to ensure no NaN values
            if x.isFinite && y.isFinite {
                points.append(CGPoint(x: x, y: y))
            }

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
                    let controlX = (previousPoint.x + currentPoint.x) / 2 + controlOffset
                    let controlY = (previousPoint.y + currentPoint.y) / 2 + controlOffset

                    // Validate control point
                    if controlX.isFinite && controlY.isFinite {
                        let controlPoint = CGPoint(x: controlX, y: controlY)
                        path.addQuadCurve(to: currentPoint, control: controlPoint)
                    } else {
                        path.addLine(to: currentPoint)
                    }
                } else {
                    path.addLine(to: currentPoint)
                }
            }

            // Close with organic curve
            let firstPoint = points[0]
            let lastPoint = points[points.count-1]
            let controlX = (lastPoint.x + firstPoint.x) / 2 + CGFloat.random(in: -1...1)
            let controlY = (lastPoint.y + firstPoint.y) / 2 + CGFloat.random(in: -1...1)

            // Validate closing control point
            if controlX.isFinite && controlY.isFinite {
                let controlPoint = CGPoint(x: controlX, y: controlY)
                path.addQuadCurve(to: firstPoint, control: controlPoint)
            } else {
                path.addLine(to: firstPoint)
            }
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

        // Guard against invalid dimensions
        guard rect.width > 0 && rect.height > 0 && rect.width.isFinite && rect.height.isFinite &&
              radius > 0 && radius.isFinite && roughness.isFinite else {
            return path
        }

        // Create organic, sketch-like circle with natural imperfections
        let points = Int.random(in: 18...28) // Variable point count for organic feel
        var circlePoints: [CGPoint] = []

        // Generate points with multiple layers of natural variation
        for i in 0..<points {
            let angle = Double(i) * 2 * .pi / Double(points)

            // Layer different types of irregularities like real hand drawing with bounds checking
            let safeRoughness = max(0, min(roughness, radius / 2))
            let baseWobble = CGFloat.random(in: -safeRoughness*2...safeRoughness*2)
            let tremor = CGFloat.random(in: -safeRoughness*0.4...safeRoughness*0.4) // Hand tremor effect
            let pressure = CGFloat.random(in: -safeRoughness*0.6...safeRoughness*0.6) // Pressure variation
            let totalRadius = max(0, radius + baseWobble + tremor + pressure)

            let x = center.x + totalRadius * cos(angle)
            let y = center.y + totalRadius * sin(angle)

            // Validate point before adding
            if x.isFinite && y.isFinite {
                circlePoints.append(CGPoint(x: x, y: y))
            }
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
                    let safeRoughness = max(0, min(roughness, radius / 4))
                    let controlDistance = CGFloat.random(in: -safeRoughness*0.8...safeRoughness*0.8)
                    let controlAngle = atan2(currentPoint.y - previousPoint.y, currentPoint.x - previousPoint.x) + .pi/2
                    let controlX = (previousPoint.x + currentPoint.x) / 2 + controlDistance * cos(controlAngle)
                    let controlY = (previousPoint.y + currentPoint.y) / 2 + controlDistance * sin(controlAngle)

                    // Validate control point
                    if controlX.isFinite && controlY.isFinite {
                        let controlPoint = CGPoint(x: controlX, y: controlY)
                        path.addQuadCurve(to: currentPoint, control: controlPoint)
                    } else {
                        path.addLine(to: currentPoint)
                    }
                } else {
                    path.addLine(to: currentPoint)
                }
            }

            // Close the circle with a natural curve
            if circlePoints.count > 1 {
                let firstPoint = circlePoints[0]
                let lastPoint = circlePoints[circlePoints.count-1]
                let safeRoughness = max(0, min(roughness, radius / 4))
                let closeControlDistance = CGFloat.random(in: -safeRoughness*0.5...safeRoughness*0.5)
                let closeControlAngle = atan2(firstPoint.y - lastPoint.y, firstPoint.x - lastPoint.x) + .pi/2
                let closeControlX = (lastPoint.x + firstPoint.x) / 2 + closeControlDistance * cos(closeControlAngle)
                let closeControlY = (lastPoint.y + firstPoint.y) / 2 + closeControlDistance * sin(closeControlAngle)

                // Validate closing control point
                if closeControlX.isFinite && closeControlY.isFinite {
                    let closeControlPoint = CGPoint(x: closeControlX, y: closeControlY)
                    path.addQuadCurve(to: firstPoint, control: closeControlPoint)
                } else {
                    path.addLine(to: firstPoint)
                }
            }
        }

        return path
    }
}

// Organic sketch-like line for dividers
struct WobblyLine: Shape {
    let roughness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Guard against invalid dimensions
        guard rect.width > 0 && rect.height > 0 && rect.width.isFinite && rect.height.isFinite &&
              roughness.isFinite else {
            return path
        }

        let points = Int.random(in: 12...18) // Variable segments for natural feel
        let step = rect.width / CGFloat(points)

        // Ensure step is valid
        guard step > 0 && step.isFinite else {
            return path
        }

        // Start with natural imperfection
        let safeRoughness = max(0, min(roughness, rect.height / 4))
        let startY = rect.midY + CGFloat.random(in: -safeRoughness*1.2...safeRoughness*1.2)

        // Validate starting point
        guard startY.isFinite else {
            return path
        }

        path.move(to: CGPoint(x: 0, y: startY))
        var previousY = startY

        for i in 1...points {
            let x = step * CGFloat(i)

            // Create natural line variation with momentum
            let momentum = (previousY - rect.midY) * 0.3 // Carry some previous direction
            let newVariation = CGFloat.random(in: -safeRoughness*1.5...safeRoughness*1.5)
            let microTremor = CGFloat.random(in: -safeRoughness*0.2...safeRoughness*0.2)
            let y = rect.midY + momentum + newVariation + microTremor

            // Validate y coordinate
            guard y.isFinite else {
                continue
            }

            // Add natural curves instead of straight lines
            let shouldCurve = Bool.random() && i % 2 == 0

            if shouldCurve {
                let controlY = (previousY + y) / 2 + CGFloat.random(in: -safeRoughness*0.5...safeRoughness*0.5)
                let controlX = x - step * 0.5 + CGFloat.random(in: -step*0.1...step*0.1)

                // Validate control point
                if controlX.isFinite && controlY.isFinite {
                    path.addQuadCurve(
                        to: CGPoint(x: x, y: y),
                        control: CGPoint(x: controlX, y: controlY)
                    )
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
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
    @EnvironmentObject private var calendarManager: CalendarManager
    @EnvironmentObject private var focusManager: FocusManager
    @EnvironmentObject private var notesManager: AppleNotesManager
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject private var settingsManager: SettingsManager

    @State private var input = ""

    @State private var showingQuickPrompts = false
    @State private var showingSettings = false
    @State private var showingVoiceRecording = false
    @State private var selectedMessage: ChatMessage?

    @State private var handwritingMode = false
    @FocusState private var isInputFocused: Bool
    @State private var suggestionTopN: Int = 5
    @State private var suggestionUseContext: Bool = true
    @State private var lastSuggestion: String = ""

    // Jump-to-bottom UI
    @State private var shouldShowJumpButton: Bool = false

    // Sidebar state
    @State private var showingSidebar: Bool = false

    private var sortedMessages: [ChatMessage] {
        dataManager.chatMessages.sorted { $0.timestamp < $1.timestamp }
    }


    init() {
        // Initialize with the shared data manager
        _viewModel = StateObject(wrappedValue: ChatViewModel(dataManager: DataManager.shared))
    }


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    // Top Bar - Compact Header (slightly larger, with settings)
                    HStack(alignment: .center, spacing: 8) {
                        // Sidebar toggle - Very noticeable
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSidebar.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Chats")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.cassetteOrange, .cassetteRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: .cassetteBrown.opacity(0.4), radius: 4, x: 0, y: 2)
                        }

                        // Mono logo
                        HStack(spacing: 2) {
                            Text("M").organicFont(.headline).fontWeight(.semibold).foregroundColor(.cassetteTextDark)
                            Text("o").organicFont(.headline).foregroundColor(.cassetteOrange)
                            Text("n").organicFont(.headline).foregroundColor(.cassetteTextDark)
                            Text("o").organicFont(.headline).foregroundColor(.cassetteTeal)
                        }
                        // New Chat (simple)
                        Button(action: { dataManager.newConversation() }) {
                            Label("New Chat", systemImage: "plus")
                                .font(.subheadline)
                                .foregroundColor(.cassetteTextDark)
                                .padding(6)
                                .background(
                                    HandDrawnCircle(roughness: 2.0)
                                        .fill(Color.cassetteBeige)
                                        .opacity(0.9)
                                )
                        }

                    Spacer()
                    
                    // Focus mode indicator
                    if focusManager.currentFocusMode != .unknown {
                        HStack(spacing: 4) {
                            Image(systemName: focusIconForMode(focusManager.currentFocusMode))
                                .font(.caption)
                                .foregroundColor(.cassetteTeal)
                            Text(focusManager.currentFocusMode.rawValue)
                                .font(.caption2)
                                .foregroundColor(.cassetteTextMedium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cassetteTeal.opacity(0.1))
                        )
                    }
                    
                    // Mode label (tap to cycle, adapts to focus)
                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { cyclePersonalityMode() } }) {
                        Label(viewModel.currentMode.rawValue.lowercased(), systemImage: "brain.head.profile")
                            .font(.subheadline)
                            .foregroundColor(.cassetteTextMedium)
                    }
                    // Settings (compact)
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.cassetteTextDark)
                            .padding(6)
                            .background(
                                HandDrawnCircle(roughness: 2.0)
                                    .fill(Color.cassetteBeige)
                                    .opacity(0.9)
                            )
                    }
                        .contextMenu {
                            Button(action: { Task { await addCurrentConversationToCalendar() } }) {
                                Label("Add to Calendar", systemImage: "calendar.badge.plus")
                            }
                            
                            Button(action: { Task { await loadSmartReferences() } }) {
                                Label("Find Related Conversations", systemImage: "link")
                            }
                            
                            Button(action: { exportCurrentConversationToNotes() }) {
                                Label("Export to Notes", systemImage: "square.and.arrow.up")
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(height: 46)
                .background(Color.cassetteCream)





                // Chat Messages
                ChatMessagesPane(
                    messages: sortedMessages,
                    isLoading: viewModel.isLoading,
                    loadingLabel: viewModel.loadingLabel,
                    settingsManager: settingsManager,
                    isValid: isValid,
                    handleMessageAction: { action, message in
                        handleMessageAction(action, for: message)
                    },
                    shouldShowJumpButton: $shouldShowJumpButton,
                    keyboardHeight: 0
                )

                // Input Bar pinned with safe area inset to ensure visibility above keyboard/home indicator
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        // subtle top divider
                        Rectangle()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 0.5)
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
                        .background(Color.cassetteCream)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom) // Prevent keyboard interference
                }
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

                // Sidebar overlay
                if showingSidebar {
                    HStack(spacing: 0) {
                        ConversationSidebar(
                            isVisible: $showingSidebar,
                            onConversationSelected: { conversationId in
                                selectConversation(conversationId)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSidebar = false
                                }
                            }
                        )
                        .transition(.move(edge: .leading))

                        // Overlay to close sidebar when tapping outside
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSidebar = false
                                }
                            }
                    }
                }
            }
        }
        .preferredColorScheme(settingsManager.appearanceMode.colorScheme)
        .sheet(isPresented: $showingReferences) {
            SmartReferencesView(references: currentReferences)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
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
            // Check if any AI provider is configured
            if AIServiceManager.shared.getConfiguredProviders().isEmpty {
                showingSettings = true
            }
            // App initialization complete
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

// MARK: - Extracted messages pane to reduce type-checker load
struct ChatMessagesPane: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    let loadingLabel: String
    let settingsManager: SettingsManager
    let isValid: (String) -> Bool
    let handleMessageAction: (MessageAction, ChatMessage) -> Void
    @Binding var shouldShowJumpButton: Bool
    let keyboardHeight: CGFloat

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if messages.isEmpty {
                            VStack(spacing: 20) {
                                Text("👋 Welcome to Mono")
                                    .organicFont(settingsManager.fontSize.titleFont)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .organicShadow()
                                Text("Your minimalist AI companion. Tap the + button for quick prompts, or just start typing.")
                                    .font(settingsManager.fontSize.bodyFont)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .lineSpacing(2)
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
                                        .overlay(
                                            HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 4.0)
                                                .stroke(Color.cassetteTeal.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.top, 80)
                            .padding(.bottom, 40)
                        }

                        ForEach(messages) { message in
                            if isValid(message.text) {
                                MessageBubble(message: message, onAction: { action in
                                    handleMessageAction(action, message)
                                }, settingsManager: settingsManager)
                                .id(message.id)
                            }
                        }

                        if isLoading {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(loadingLabel.isEmpty ? "Thinking..." : loadingLabel)
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)

                // Floating jump-to-bottom arrow
                Button(action: {
                    NotificationCenter.default.post(name: .scrollChatToBottom, object: nil)
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.cassetteTeal)
                        .shadow(radius: 2)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 24)
                .opacity(shouldShowJumpButton ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: shouldShowJumpButton)
            }
            .onReceive(NotificationCenter.default.publisher(for: .scrollChatToBottom)) { _ in
                if let last = messages.last {
                    withAnimation(.spring()) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onTapGesture {
                shouldShowJumpButton = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { shouldShowJumpButton = true }
            }
        }
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

    // MARK: - Smart Cross-References
    @State private var showingReferences = false
    @State private var currentReferences: [IntelligentReference] = []
    
    // MARK: - Share Integration
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    private func loadSmartReferences() async {
        guard let currentId = dataManager.selectedConversationId else { return }
        
        // Generate new references if we have multiple conversations
        if dataManager.conversations.count > 1 {
            await dataManager.generateIntelligentReferences(for: currentId)
        }
        
        let references = dataManager.getReferencesForConversation(currentId)
        await MainActor.run {
            currentReferences = references
            if !references.isEmpty {
                showingReferences = true
            }
        }
    }
    
    // MARK: - Calendar Integration
    private func addCurrentConversationToCalendar() async {
        // Ensure permission
        if !calendarManager.hasCalendarAccess {
            let granted = await calendarManager.requestCalendarAccess()
            if !granted { return }
        }

        guard let currentId = dataManager.selectedConversationId,
              let conversation = dataManager.conversations.first(where: { $0.id == currentId })
        else { return }

        _ = await calendarManager.createEventFromConversation(conversation)
    }
    
    // MARK: - Apple Notes Integration
    private func exportCurrentConversationToNotes() {
        guard let currentId = dataManager.selectedConversationId,
              let conversation = dataManager.conversations.first(where: { $0.id == currentId })
        else { return }
        
        let shareableItems = notesManager.createShareableContent(for: conversation)
        shareItems = shareableItems
        showingShareSheet = true
    }

    private func cyclePersonalityMode() {
        // Suggest focus-appropriate personality first
        let suggestedMode = focusManager.getSuggestedPersonality()
        if viewModel.currentMode != suggestedMode {
            viewModel.currentMode = suggestedMode
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            return
        }
        
        // Otherwise cycle through all modes
        let modes = PersonalityMode.allCases
        if let currentIndex = modes.firstIndex(of: viewModel.currentMode) {
            let nextIndex = (currentIndex + 1) % modes.count
            viewModel.currentMode = modes[nextIndex]

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func focusIconForMode(_ mode: FocusManager.FocusMode) -> String {
        switch mode {
        case .work:
            return "briefcase.fill"
        case .personal:
            return "house.fill"
        case .doNotDisturb:
            return "moon.fill"
        case .sleep:
            return "bed.double.fill"
        case .fitness:
            return "figure.run"
        case .driving:
            return "car.fill"
        case .unknown:
            return "questionmark.circle"
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

    func isValid(_ text: String) -> Bool {
        let lower = text.lowercased()
        return !text.isEmpty && !lower.contains("nan") && !lower.contains("infinity")
    }

    private func selectConversation(_ conversationId: UUID) {
        dataManager.selectConversation(conversationId)
    }


// MARK: - Message Bubble
}

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
                                        ForEach(0..<20, id: \.self) { index in
                                            let height = CGFloat.random(in: 4...16)
                                            Rectangle().fill(Color.cassetteOrange.opacity(0.6))
                                                .frame(width: 2, height: height.isFinite ? height : 8)
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
                            .contextMenu {
                                if !message.isUser {
                                    Button {
                                        let t = Thought(title: message.text.components(separatedBy: "\n").first ?? "Saved Answer",
                                                        tags: ["chat"],
                                                        keyPoints: [message.text],
                                                        actionItems: [],
                                                        keyInsights: [])
                                        DataManager.shared.addThought(t)
                                    } label: {
                                        Label("Save to Thoughts", systemImage: "tray.and.arrow.down.fill")
                                    }
                                }
                            }
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
    @EnvironmentObject private var focusManager: FocusManager

    private var prompts: [String] {
        // Get context-aware prompts based on current focus
        let contextualPrompts = focusManager.getContextualPrompts()
        let generalPrompts = [
            "What am I missing?",
            "Write it tighter.",
            "Ask me questions.",
            "Help me think through this.",
            "Give me a fresh perspective.",
            "What's the core issue?",
            "Challenge my assumptions.",
            "Make this actionable."
        ]
        
        // Combine contextual and general prompts
        return contextualPrompts + generalPrompts
    }

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
    @State private var showingLegalSafari = false
    @State private var selectedLegalURL: URL? = nil

    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var calendarManager: CalendarManager

    var body: some View {
        NavigationView {
            List {
                // Upcoming calendar events
                Section {
                    if !calendarManager.hasCalendarAccess {
                        Button(action: { Task { _ = await calendarManager.requestCalendarAccess() } }) {
                            Label("Enable Calendar Access", systemImage: "calendar")
                        }
                    } else if calendarManager.upcomingEvents.isEmpty {
                        Text("No events in the next 7 days")
                            .foregroundColor(.cassetteTextMedium)
                    } else {
                        ForEach(Array(calendarManager.upcomingEvents.prefix(3)), id: \.eventIdentifier) { evt in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.cassetteBlue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(evt.title)
                                        .foregroundColor(.cassetteTextDark)
                                    Text(formatEventDateRange(evt))
                                        .font(.caption)
                                        .foregroundColor(.cassetteTextMedium)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Upcoming")
                        .foregroundColor(.cassetteTextMedium)
                }
                // Quick AI Setup Section - Compact and prominent
                Section {
                    // Main AI Provider Card - More compact
                    NavigationLink(destination: AIProviderSettingsView()) {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.cassetteOrange)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI Provider & API Keys")
                                        .font(.headline)
                                        .foregroundColor(.cassetteTextDark)

                                    if let currentProvider = AIServiceManager.shared.currentProvider {
                                        Text("\(currentProvider.name) • \(AIServiceManager.shared.getConfiguredProviders().count) configured")
                                            .font(.caption)
                                            .foregroundColor(.cassetteTextMedium)
                                    } else {
                                        Text("Tap to configure your first AI service")
                                            .font(.caption)
                                            .foregroundColor(.cassetteRed)
                                    }
                                }

                                Spacer()

                                // Provider status indicators
                                HStack(spacing: 4) {
                                    ForEach(["groq", "openai"], id: \.self) { providerId in
                                        if let provider = AIServiceManager.shared.getProvider(id: providerId) {
                                            Circle()
                                                .fill(provider.isConfigured ? Color.green : Color.gray.opacity(0.3))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    Text("\(AIServiceManager.shared.getConfiguredProviders().count) of 2 configured")
                                        .font(.caption2)
                                        .foregroundColor(.cassetteTextMedium)
                                }
                            }

                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("AI Configuration")
                        .foregroundColor(.cassetteTextMedium)
                } footer: {
                    Text("Uses Groq AI or OpenAI for AI features. Tap to configure your API keys.")
                        .foregroundColor(.cassetteTextMedium)
                }

                // AI Model & Voice Settings - Compact section
                Section {
                    NavigationLink(destination: ModelSettingsView()) {
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(.cassetteTeal)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("AI Model & Voice")
                                    .font(.subheadline)
                                    .foregroundColor(.cassetteTextDark)

                                if let currentProvider = AIServiceManager.shared.currentProvider {
                                    let currentModel = settingsManager.llmModel
                                    Text("\(currentProvider.name) • \(currentModel)")
                                        .font(.caption2)
                                        .foregroundColor(.cassetteTextMedium)
                                } else {
                                    Text("Configure AI provider first")
                                        .font(.caption2)
                                        .foregroundColor(.cassetteRed)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                } header: {
                    Text("Model Settings")
                        .foregroundColor(.cassetteTextMedium)
                }

                // App Preferences Section - Streamlined
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.cassetteBlue)
                                .frame(width: 20)

                            Text("Appearance")
                                .font(.subheadline)
                                .foregroundColor(.cassetteTextDark)
                        }
                    }

                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.cassetteSage)
                                .frame(width: 20)

                            Text("Privacy & Data")
                                .font(.subheadline)
                                .foregroundColor(.cassetteTextDark)
                        }
                    }

                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.cassetteRed)
                                .frame(width: 20)

                            Text("Notifications")
                                .font(.subheadline)
                                .foregroundColor(.cassetteTextDark)
                        }
                    }
                } header: {
                    Text("App Settings")
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
                        if let url = URL(string: "https://giannakoudakisatelier.app/terms") {
                            selectedLegalURL = url
                            showingLegalSafari = true
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
                        if let url = URL(string: "https://giannakoudakisatelier.app/privacy") {
                            selectedLegalURL = url
                            showingLegalSafari = true
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

                .sheet(isPresented: $showingLegalSafari) {
                    if let url = selectedLegalURL {
                        SafariView(url: url)
                            .ignoresSafeArea()
                    }
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

    private func formatEventDateRange(_ event: EKEvent) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return "\(fmt.string(from: event.startDate)) – \(fmt.string(from: event.endDate))"
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private func clearAllData() {
        // Clear UserDefaults (but preserve settings)
        let keysToPreserve = ["groq_api_key", "appearance_mode", "font_size", "notifications_enabled", "crash_reporting_enabled"]
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

// MARK: - Smart References View
struct SmartReferencesView: View {
    let references: [IntelligentReference]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            List {
                if references.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "link.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.cassetteTextMedium)
                            
                            Text("No Related Conversations Found")
                                .font(.headline)
                                .foregroundColor(.cassetteTextDark)
                            
                            Text("As you have more conversations, I'll find intelligent connections between them.")
                                .font(.body)
                                .foregroundColor(.cassetteTextMedium)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    Section {
                        ForEach(references.sorted { $0.confidenceScore > $1.confidenceScore }) { reference in
                            VStack(alignment: .leading, spacing: 12) {
                                // Connection type and confidence
                                HStack {
                                    Text(reference.connectionType.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.cassetteTeal)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.cassetteTeal.opacity(0.15))
                                        )
                                    
                                    Spacer()
                                    
                                    Text("Confidence: \(Int(reference.confidenceScore * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.cassetteTextMedium)
                                }
                                
                                // Quote from related conversation
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("From previous conversation:")
                                        .font(.caption)
                                        .foregroundColor(.cassetteTextMedium)
                                    
                                    Text("\"\(reference.relevantQuote)\"")
                                        .font(.body)
                                        .foregroundColor(.cassetteTextDark)
                                        .italic()
                                        .padding(.leading, 8)
                                }
                                
                                // Context explanation
                                Text(reference.contextSummary)
                                    .font(.subheadline)
                                    .foregroundColor(.cassetteTextMedium)
                                
                                // Action button
                                Button(action: {
                                    navigateToConversation(reference.sourceConversationId)
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.right.circle")
                                        Text("View Conversation")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.cassetteOrange)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Related Conversations")
                            .foregroundColor(.cassetteTextMedium)
                    } footer: {
                        Text("These conversations contain relevant information based on AI analysis.")
                            .foregroundColor(.cassetteTextMedium)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.cassetteWarmGray.opacity(0.1))
            .navigationTitle("Smart References")
            .navigationBarTitleDisplayMode(.large)
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
    
    private func navigateToConversation(_ conversationId: UUID) {
        dataManager.selectConversation(conversationId)
        dismiss()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Exclude some activities that don't make sense for conversations
        controller.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .postToWeibo
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Enums
enum MessageAction {
    case regenerate
    case makeShorter
    case expandIdea
    case surpriseMe
}
