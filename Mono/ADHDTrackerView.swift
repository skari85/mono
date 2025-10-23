//
//  ADHDTrackerView.swift
//  Mono
//
//  ADHD-friendly tracking interface
//

import SwiftUI
import Charts

struct ADHDTrackerView: View {
    @StateObject private var tracker = ADHDTrackerManager.shared
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var selectedTab = 0
    @State private var showingConsentSheet = false
    @State private var showingSymptomLogger = false
    @State private var showingHabitCreator = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                
                if !tracker.userConsented {
                    consentRequiredView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("ADHD Toolkit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingConsentSheet = true }) {
                            Label("Privacy & Data", systemImage: "hand.raised.fill")
                        }
                        Button(action: exportData) {
                            Label("Export My Data", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.cassetteOrange)
                    }
                }
            }
            .sheet(isPresented: $showingConsentSheet) {
                ADHDConsentView()
            }
            .sheet(isPresented: $showingSymptomLogger) {
                SymptomLoggerView()
            }
            .sheet(isPresented: $showingHabitCreator) {
                HabitCreatorView()
            }
        }
    }
    
    private var backgroundView: some View {
        Color.cassetteWarmGray.opacity(0.3)
            .overlay(PaperTexture(opacity: 0.2, seed: 0xAD4D))
            .ignoresSafeArea()
    }
    
    private var consentRequiredView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.cassetteTeal)
            
            Text("ADHD Toolkit")
                .font(settingsManager.fontSize.titleFont)
                .fontWeight(.bold)
                .foregroundColor(.cassetteTextDark)
            
            Text("Track your focus, habits, and symptoms to better understand your patterns.")
                .font(settingsManager.fontSize.bodyFont)
                .foregroundColor(.cassetteTextMedium)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                DisclaimerBox(text: "⚠️ This is NOT a medical diagnostic tool")
                DisclaimerBox(text: "✓ Your data stays private on your device")
                DisclaimerBox(text: "📊 Insights are for personal reflection only")
            }
            
            Button(action: { showingConsentSheet = true }) {
                Text("Get Started")
                    .font(settingsManager.fontSize.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        HandDrawnRoundedRectangle(cornerRadius: 20, roughness: 4.0)
                            .fill(Color.cassetteOrange)
                            .shadow(color: .cassetteBrown.opacity(0.3), radius: 6, x: 0, y: 4)
                    )
            }
        }
        .padding()
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Daily Streak Card
                streakCard
                
                // Quick Actions
                quickActionsSection
                
                // Tabs
                Picker("View", selection: $selectedTab) {
                    Text("Dashboard").tag(0)
                    Text("Habits").tag(1)
                    Text("Symptoms").tag(2)
                    Text("Insights").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0: dashboardView
                    case 1: habitsView
                    case 2: symptomsView
                    case 3: insightsView
                    default: EmptyView()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private var streakCard: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(tracker.dailyStreak.currentStreak)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.cassetteOrange)
                Text("Day Streak")
                    .font(settingsManager.fontSize.captionFont)
                    .foregroundColor(.cassetteTextMedium)
            }
            
            Divider()
                .frame(height: 60)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.cassetteOrange)
                    Text("Keep going!")
                        .font(settingsManager.fontSize.bodyFont)
                        .fontWeight(.semibold)
                }
                Text("Best: \(tracker.dailyStreak.longestStreak) days")
                    .font(settingsManager.fontSize.captionFont)
                    .foregroundColor(.cassetteTextMedium)
            }
        }
        .padding(20)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 16, roughness: 4.0)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .cassetteBrown.opacity(0.2), radius: 6, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(settingsManager.fontSize.headlineFont)
                .fontWeight(.bold)
                .foregroundColor(.cassetteTextDark)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                ADHDQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Log Symptom",
                    color: .cassetteTeal,
                    action: {
                        showingSymptomLogger = true
                    }
                )
                
                ADHDQuickActionButton(
                    icon: "checkmark.circle.fill",
                    title: "Complete Habit",
                    color: .cassetteSage,
                    action: {
                        // Show habit completion
                    }
                )
                
                ADHDQuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "View Progress",
                    color: .cassetteBlue,
                    action: {
                        selectedTab = 3
                    }
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var dashboardView: some View {
        VStack(spacing: 16) {
            // Productivity Score
            ScoreCard(
                title: "Focus Score",
                score: tracker.getProductivityScore(),
                icon: "brain.head.profile",
                color: .cassetteTeal
            )
            
            // Achievements
            achievementsSection
            
            // Recent Activity
            recentActivitySection
        }
    }
    
    private var habitsView: some View {
        VStack(spacing: 16) {
            Button(action: { showingHabitCreator = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Create New Habit")
                        .font(settingsManager.fontSize.bodyFont)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.cassetteOrange)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                        .fill(Color.cassetteOrange.opacity(0.1))
                )
            }
            
            ForEach(tracker.habits) { habit in
                HabitRow(habit: habit)
            }
        }
    }
    
    private var symptomsView: some View {
        VStack(spacing: 16) {
            ForEach(ADHDSymptom.SymptomType.allCases, id: \.self) { symptomType in
                let frequency = tracker.getSymptomFrequency(type: symptomType, days: 30)
                SymptomFrequencyCard(
                    symptomType: symptomType,
                    frequency: frequency
                )
            }
        }
    }
    
    private var insightsView: some View {
        VStack(spacing: 16) {
            Text("7-Day Focus Trend")
                .font(settingsManager.fontSize.headlineFont)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let focusTrend = tracker.getFocusTrend(days: 7)
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(focusTrend.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Focus", value)
                        )
                        .foregroundStyle(Color.cassetteTeal)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(
                    HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                        .fill(Color.white.opacity(0.95))
                )
            } else {
                SimpleFocusChart(data: focusTrend)
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(settingsManager.fontSize.headlineFont)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(tracker.achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(settingsManager.fontSize.headlineFont)
                .fontWeight(.bold)
            
            ForEach(tracker.productivitySessions.suffix(5).reversed(), id: \.id) { session in
                SessionRow(session: session)
            }
        }
    }
    
    private func exportData() {
        let data = tracker.exportAllData()
        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct DisclaimerBox: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.cassetteTextDark)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                    .fill(Color.cassetteBeige.opacity(0.5))
            )
            .padding(.horizontal, 40)
    }
}

struct ADHDQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.cassetteTextDark)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                    .fill(color.opacity(0.1))
            )
        }
    }
}

struct ScoreCard: View {
    let title: String
    let score: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.cassetteTextMedium)
                
                // Ensure score is valid before displaying
                let validScore = score.isFinite ? score : 0.0
                Text("\(Int(validScore * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.cassetteTextDark)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                .fill(Color.white.opacity(0.95))
        )
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? .cassetteGold : .gray)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.cassetteTextDark)
            
            if !achievement.isUnlocked {
                ProgressView(value: Double(achievement.progress), total: Double(achievement.requirement))
                    .tint(.cassetteOrange)
                    .scaleEffect(x: 1, y: 0.5)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                .fill(achievement.isUnlocked ? Color.cassetteGold.opacity(0.2) : Color.gray.opacity(0.1))
        )
    }
}

struct HabitRow: View {
    let habit: Habit
    @StateObject private var tracker = ADHDTrackerManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.cassetteOrange)
                    Text("\(habit.streak) day streak")
                        .font(.caption)
                        .foregroundColor(.cassetteTextMedium)
                }
            }
            
            Spacer()
            
            Button(action: {
                tracker.recordHabitCompletion(habitId: habit.id, completed: true)
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cassetteSage)
            }
        }
        .padding(16)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                .fill(Color.white.opacity(0.95))
        )
    }
}

struct SessionRow: View {
    let session: ProductivitySession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.taskType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(session.completedSubtasks)/\(session.totalSubtasks) completed")
                    .font(.caption)
                    .foregroundColor(.cassetteTextMedium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Ensure focus score is valid
                let validScore = session.focusScore.isFinite ? session.focusScore : 0.0
                Text("\(Int(validScore * 100))%")
                    .font(.headline)
                    .foregroundColor(.cassetteTeal)
                Text("focus")
                    .font(.caption2)
                    .foregroundColor(.cassetteTextMedium)
            }
        }
        .padding(12)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                .fill(Color.cassetteBeige.opacity(0.3))
        )
    }
}

struct SymptomFrequencyCard: View {
    let symptomType: ADHDSymptom.SymptomType
    let frequency: Int
    
    var body: some View {
        HStack {
            Text(symptomType.rawValue)
                .font(.subheadline)
                .foregroundColor(.cassetteTextDark)
            
            Spacer()
            
            Text("\(frequency) times")
                .font(.caption)
                .foregroundColor(.cassetteTextMedium)
        }
        .padding(12)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                .fill(Color.white.opacity(0.95))
        )
    }
}

struct SimpleFocusChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty, data.count > 1 else { return }
                
                // Ensure we have valid data
                let validData = data.map { $0.isFinite ? $0 : 0.0 }
                let maxValue = max(validData.max() ?? 1.0, 0.01) // Avoid division by zero
                let stepX = geometry.size.width / CGFloat(validData.count - 1)
                let stepY = geometry.size.height
                
                // Validate dimensions
                guard stepX.isFinite && stepX > 0 && stepY.isFinite && stepY > 0 else { return }
                
                let firstValue = validData[0] / maxValue
                let firstY = stepY * (1 - CGFloat(firstValue))
                guard firstY.isFinite else { return }
                
                path.move(to: CGPoint(x: 0, y: firstY))
                
                for (index, value) in validData.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = value / maxValue
                    let y = stepY * (1 - CGFloat(normalizedValue))
                    
                    // Only add valid points
                    if x.isFinite && y.isFinite {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.cassetteTeal, lineWidth: 3)
        }
        .frame(height: 200)
        .padding()
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                .fill(Color.white.opacity(0.95))
        )
    }
}

