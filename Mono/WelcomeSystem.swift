//
//  WelcomeSystem.swift
//  Mono
//
//  Welcome and Tutorial System for Mono
//

import SwiftUI

// MARK: - Welcome Data Models

struct WelcomeFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let detailedDescription: String
    let category: FeatureCategory
    let isNew: Bool
    
    enum FeatureCategory: String, CaseIterable {
        case core = "Core Features"
        case privacy = "Privacy & Security"
        case intelligence = "Smart Features"
        case integration = "Apple Integration"
        case personality = "AI Personalities"
    }
}

// MARK: - Feature Data

extension WelcomeFeature {
    static let allFeatures: [WelcomeFeature] = [
        // Core Features
        WelcomeFeature(
            icon: "bubble.left.and.bubble.right",
            title: "Minimalist Chat",
            description: "Clean, distraction-free conversations with AI",
            detailedDescription: "Mono provides a beautiful, vintage-inspired interface focused on what matters: your conversations. No clutter, no distractions—just you and AI working together.",
            category: .core,
            isNew: false
        ),
        WelcomeFeature(
            icon: "mic",
            title: "Voice Messages",
            description: "Speak naturally, get transcribed automatically",
            detailedDescription: "Record voice messages that are automatically transcribed using advanced AI. Perfect for when typing isn't convenient—while walking, driving, or just thinking out loud.",
            category: .core,
            isNew: false
        ),
        WelcomeFeature(
            icon: "plus.bubble",
            title: "Quick Prompts",
            description: "Instant conversation starters for any situation",
            detailedDescription: "Tap the + button for contextual prompts that adapt to your current Focus Mode. Whether you're working, relaxing, or exploring ideas, get the right conversation starter.",
            category: .core,
            isNew: false
        ),
        
        // Privacy & Security
        WelcomeFeature(
            icon: "lock.shield",
            title: "100% Private",
            description: "Your data never leaves your device",
            detailedDescription: "Everything stays local on your iPhone. No analytics, no tracking, no cloud storage of your conversations. Only optional iCloud sync that you control completely.",
            category: .privacy,
            isNew: false
        ),
        WelcomeFeature(
            icon: "key",
            title: "Your AI Keys",
            description: "Bring your own API keys for complete control",
            detailedDescription: "Use your own OpenAI, Groq, or other AI provider keys. Stored securely in iOS Keychain. You control costs, models, and data—we never see your conversations.",
            category: .privacy,
            isNew: false
        ),
        
        // Smart Features (NEW)
        WelcomeFeature(
            icon: "link",
            title: "Smart Cross-References",
            description: "AI finds connections between your conversations",
            detailedDescription: "Mono intelligently analyzes your conversations to find meaningful connections, patterns, and insights. Discover how your thoughts and ideas relate across different chats.",
            category: .intelligence,
            isNew: true
        ),
        WelcomeFeature(
            icon: "brain",
            title: "Memory Palace",
            description: "AI-powered knowledge management",
            detailedDescription: "Your conversations become a smart knowledge base. Mono creates memory nodes, finds connections, and helps you recall important information when you need it.",
            category: .intelligence,
            isNew: true
        ),
        WelcomeFeature(
            icon: "magnifyingglass.circle",
            title: "Intelligent Search",
            description: "Find information by meaning, not just keywords",
            detailedDescription: "Search for concepts, ideas, or themes across all your conversations. AI understands context and meaning to surface exactly what you're looking for.",
            category: .intelligence,
            isNew: true
        ),
        
        // Apple Integration (NEW)
        WelcomeFeature(
            icon: "calendar.badge.plus",
            title: "Calendar Integration",
            description: "Turn conversations into calendar events",
            detailedDescription: "Mono can analyze your conversations and automatically create calendar events with smart scheduling. Discuss a meeting? Mono can add it to your calendar with all the details.",
            category: .integration,
            isNew: true
        ),
        WelcomeFeature(
            icon: "moon.stars",
            title: "Focus Mode Awareness",
            description: "Adapts to your iOS Focus Modes",
            detailedDescription: "When you're in Work focus, Mono suggests productivity prompts. In Personal focus, it offers creative and reflective conversations. Seamless integration with your daily routine.",
            category: .integration,
            isNew: true
        ),
        WelcomeFeature(
            icon: "note.text",
            title: "Apple Notes Integration",
            description: "Full integration with Apple Notes app",
            detailedDescription: "Access your Apple Notes directly from Mono. View, search, and create notes seamlessly. Export conversations to Notes with proper formatting. Your notes and conversations work together.",
            category: .integration,
            isNew: true
        ),
        WelcomeFeature(
            icon: "brain",
            title: "ADHD Focus Toolkit",
            description: "Productivity and focus tracking tools",
            detailedDescription: "Specialized tools for ADHD users: focus sessions, habit tracking, productivity insights, and behavioral patterns. Track your focus, complete tasks, and understand your productivity patterns.",
            category: .intelligence,
            isNew: true
        ),
        
        // AI Personalities
        WelcomeFeature(
            icon: "brain.head.profile",
            title: "Smart Mode",
            description: "Thoughtful, well-structured responses",
            detailedDescription: "Perfect for work, learning, and deep thinking. Smart mode provides comprehensive, analytical responses with clear structure and practical insights.",
            category: .personality,
            isNew: false
        ),
        WelcomeFeature(
            icon: "moon.zzz",
            title: "Quiet Mode",
            description: "Concise, peaceful interactions",
            detailedDescription: "Ideal for reflection, mindfulness, or when you need brief, calming responses. Quiet mode speaks softly and gets to the point without overwhelming.",
            category: .personality,
            isNew: false
        ),
        WelcomeFeature(
            icon: "theatermasks",
            title: "Play Mode",
            description: "Creative, engaging, and fun",
            detailedDescription: "Perfect for brainstorming, creative projects, or when you want engaging conversations. Play mode brings humor, creativity, and energy to your chats.",
            category: .personality,
            isNew: false
        )
    ]
}

// MARK: - Welcome Views

struct WelcomeMainView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var selectedCategory: WelcomeFeature.FeatureCategory = .core

    private let pages = ["intro", "features", "privacy", "start"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentPage ? Color.cassetteTeal : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)

                        if index < pages.count - 1 {
                            Rectangle()
                                .fill(index < currentPage ? Color.cassetteTeal : Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                TabView(selection: $currentPage) {
                    // Page 0: Introduction
                    WelcomeIntroPage()
                        .tag(0)

                    // Page 1: Features Overview
                    WelcomeFeaturesPage(selectedCategory: $selectedCategory)
                        .tag(1)

                    // Page 2: Privacy Focus
                    WelcomePrivacyPage()
                        .tag(2)

                    // Page 3: Get Started
                    WelcomeStartPage {
                        dismiss()
                    }
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.cassetteTeal)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.cassetteTextMedium)
                }
            }
        }
        .preferredColorScheme(.light) // Use light mode for better readability
    }
}

struct WelcomeIntroPage: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 32) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image("Monotrans")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .background(
                                Circle()
                                    .fill(Color.cassetteTeal.opacity(0.1))
                                    .frame(width: 140, height: 140)
                            )
                            .shadow(color: .cassetteTeal.opacity(0.2), radius: 10, x: 0, y: 5)

                        VStack(spacing: 8) {
                            Text("Welcome to Mono")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Your Minimalist AI Companion")
                                .font(.title3)
                                .foregroundColor(.cassetteTextMedium)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)

                    // What is Mono?
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("What is Mono?")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            WelcomeInfoRow(
                                icon: "sparkles",
                                title: "AI-Powered Conversations",
                                description: "Chat with advanced AI using your own API keys"
                            )

                            WelcomeInfoRow(
                                icon: "lock.shield",
                                title: "Privacy-First Design",
                                description: "Everything stays on your device—no tracking or analytics"
                            )

                            WelcomeInfoRow(
                                icon: "brain",
                                title: "Smart Memory System",
                                description: "AI finds connections and insights across your conversations"
                            )

                            WelcomeInfoRow(
                                icon: "apple.logo",
                                title: "Apple Integration",
                                description: "Works seamlessly with Calendar, Notes, and Focus Modes"
                            )
                        }
                    }

                    // Who is it for?
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Perfect for:")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            WelcomeTargetRow(icon: "briefcase", text: "Professionals who need AI for work")
                            WelcomeTargetRow(icon: "studentdesk", text: "Students and researchers")
                            WelcomeTargetRow(icon: "lightbulb", text: "Creative thinkers and writers")
                            WelcomeTargetRow(icon: "heart.text.square", text: "Anyone who values privacy")
                            WelcomeTargetRow(icon: "brain.head.profile", text: "Deep thinkers who love connections")
                        }
                    }

                    // Call to action
                    VStack(spacing: 16) {
                        Text("Ready to get started?")
                            .font(.headline)
                            .foregroundColor(.cassetteTeal)

                        Text("Swipe left to explore features →")
                            .font(.subheadline)
                            .foregroundColor(.cassetteTextMedium)
                            .italic()
                    }
                    .padding(.vertical, 20)

                    // Bottom spacing for safe scrolling
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

struct WelcomeFeaturesPage: View {
    @Binding var selectedCategory: WelcomeFeature.FeatureCategory

    var filteredFeatures: [WelcomeFeature] {
        WelcomeFeature.allFeatures.filter { $0.category == selectedCategory }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text("🚀 Features Overview")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Discover what makes Mono special")
                            .font(.subheadline)
                            .foregroundColor(.cassetteTextMedium)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Category Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(WelcomeFeature.FeatureCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedCategory = category
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text(category.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)

                                        if selectedCategory == category {
                                            Rectangle()
                                                .fill(Color.cassetteTeal)
                                                .frame(height: 2)
                                                .transition(.scale)
                                        } else {
                                            Rectangle()
                                                .fill(Color.clear)
                                                .frame(height: 2)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .foregroundColor(selectedCategory == category ? .cassetteTeal : .cassetteTextMedium)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Features List
                    LazyVStack(spacing: 16) {
                        ForEach(filteredFeatures) { feature in
                            WelcomeFeatureCard(feature: feature)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedCategory)

                    // Bottom spacing for safe scrolling
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct WelcomePrivacyPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Privacy Hero
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Privacy First")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your data is yours alone")
                        .font(.title3)
                        .foregroundColor(.cassetteTextMedium)
                        .multilineTextAlignment(.center)
                }
                
                // Privacy Guarantees
                VStack(alignment: .leading, spacing: 20) {
                    WelcomePrivacyRow(
                        icon: "iphone",
                        title: "100% Local Storage",
                        description: "All conversations, thoughts, and data stay on your iPhone. Nothing is sent to our servers—ever."
                    )
                    
                    WelcomePrivacyRow(
                        icon: "eye.slash",
                        title: "Zero Tracking",
                        description: "No analytics, no telemetry, no usage data collection. We don't know how you use Mono."
                    )
                    
                    WelcomePrivacyRow(
                        icon: "key",
                        title: "Your API Keys",
                        description: "Bring your own OpenAI, Groq, or other AI keys. Stored securely in iOS Keychain."
                    )
                    
                    WelcomePrivacyRow(
                        icon: "icloud",
                        title: "Optional iCloud Sync",
                        description: "Backup through your personal iCloud if you choose. You control this completely."
                    )
                    
                    WelcomePrivacyRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Open Source",
                        description: "Full transparency in how your data is handled. Inspect the code yourself."
                    )
                }
                
                // Trust Badge
                VStack(spacing: 12) {
                    Text("🏆 Privacy Promise")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("We built Mono the way we want our own apps to work: completely private, fully local, and transparently honest about data handling.")
                        .font(.subheadline)
                        .foregroundColor(.cassetteTextMedium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct WelcomeStartPage: View {
    let onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                // Ready to Start
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("You're All Set!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Let's set up your first AI provider and start chatting")
                        .font(.title3)
                        .foregroundColor(.cassetteTextMedium)
                        .multilineTextAlignment(.center)
                }
                
                // Quick Setup Steps
                VStack(alignment: .leading, spacing: 20) {
                    Text("Quick Setup (2 minutes):")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    WelcomeStepRow(
                        number: 1,
                        title: "Choose AI Provider",
                        description: "Pick OpenAI, Groq, or another provider"
                    )
                    
                    WelcomeStepRow(
                        number: 2,
                        title: "Add API Key",
                        description: "Securely store your API key in iOS Keychain"
                    )
                    
                    WelcomeStepRow(
                        number: 3,
                        title: "Start Chatting",
                        description: "Try different personalities and explore features"
                    )
                }
                
                // Pro Tips
                VStack(alignment: .leading, spacing: 16) {
                    Text("💡 Pro Tips:")
                        .font(.headline)
                        .foregroundColor(.cassetteTeal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Tap the personality name to switch between Smart, Quiet, and Play modes")
                        Text("• Use the + button for contextual quick prompts")
                        Text("• Long-press messages for actions like 'Make Shorter' or 'Expand'")
                        Text("• Try voice messages for hands-free conversations")
                        Text("• Explore the settings menu (⚙️) for calendar and notes integration")
                    }
                    .font(.subheadline)
                    .foregroundColor(.cassetteTextMedium)
                }
                
                // Start Button
                Button(action: onComplete) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Let's Start!")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cassetteTeal)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Helper Views

struct WelcomeInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cassetteTeal)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.cassetteTextMedium)
            }
            
            Spacer()
        }
    }
}

struct WelcomeTargetRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.cassetteTeal)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.cassetteTextMedium)
            
            Spacer()
        }
    }
}

struct WelcomeFeatureCard: View {
    let feature: WelcomeFeature
    @State private var isExpanded = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundColor(.cassetteTeal)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(feature.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if feature.isNew {
                                Text("NEW")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.orange)
                                    )
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                                .font(.title3)
                                .foregroundColor(.cassetteTeal)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }

                        Text(feature.description)
                            .font(.subheadline)
                            .foregroundColor(.cassetteTextMedium)
                            .multilineTextAlignment(.leading)

                        if isExpanded {
                            Divider()
                                .background(Color.cassetteTeal.opacity(0.3))

                            Text(feature.detailedDescription)
                                .font(.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 4)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .top))
                                ))
                        }
                    }
                }

                if !isExpanded {
                    HStack {
                        Spacer()
                        Text("Tap to learn more")
                            .font(.caption)
                            .foregroundColor(.cassetteTeal)
                            .italic()
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isExpanded ? Color.cassetteTeal.opacity(0.05) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isExpanded ? Color.cassetteTeal.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: isExpanded ? 2 : 1)
                    )
            )
            .scaleEffect(isExpanded ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WelcomePrivacyRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.cassetteTextMedium)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct WelcomeStepRow: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.cassetteTeal)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.cassetteTextMedium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Tutorial Guide View (for Settings)

struct TutorialGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: WelcomeFeature.FeatureCategory = .core
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("📚 How to Use Mono")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Complete guide to all features")
                        .font(.subheadline)
                        .foregroundColor(.cassetteTextMedium)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(WelcomeFeature.FeatureCategory.allCases, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedCategory == category ? Color.cassetteTeal : Color.gray.opacity(0.2))
                                    )
                                    .foregroundColor(selectedCategory == category ? .white : .cassetteTextMedium)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 16)
                
                // Features List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(WelcomeFeature.allFeatures.filter { $0.category == selectedCategory }) { feature in
                            WelcomeFeatureCard(feature: feature)
                        }
                        
                        // Quick Tips Section
                        if selectedCategory == .core {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("💡 Quick Tips")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.cassetteTeal)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    TipRow(tip: "Tap the mode name (🧠 Smart) to cycle between AI personalities")
                                    TipRow(tip: "Tap the focus indicator (🏠 Work) to cycle through focus modes")
                                    TipRow(tip: "Long-press any AI message for quick actions like 'Make Shorter'")
                                    TipRow(tip: "Use the + button for contextual prompts based on your Focus Mode")
                                    TipRow(tip: "Voice messages are automatically transcribed—perfect for hands-free use")
                                    TipRow(tip: "Export conversations to Apple Notes via the context menu")
                                    TipRow(tip: "Use the Focus tab for ADHD productivity tracking and insights")
                                    TipRow(tip: "Memory Palace automatically organizes your conversation insights")
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cassetteTeal.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cassetteTeal.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TipRow: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.cassetteTeal)
                .frame(width: 16)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(.cassetteTextMedium)
            
            Spacer()
        }
    }
}
