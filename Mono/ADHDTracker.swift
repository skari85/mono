//
//  ADHDTracker.swift
//  Mono
//
//  ADHD-friendly productivity and symptom tracking
//

import Foundation
import SwiftUI

// MARK: - Behavioral Metadata Models

struct BehavioralInsight: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let category: InsightCategory
    let value: Double // 0.0-1.0 scale
    let context: String
    
    enum InsightCategory: String, Codable, CaseIterable {
        case focus = "Focus Level"
        case energy = "Energy"
        case distraction = "Distraction Events"
        case taskCompletion = "Task Completion"
        case moodPositive = "Positive Mood"
        case moodNegative = "Negative Mood"
        case sessionLength = "Session Duration"
        case taskSwitching = "Task Switching"
    }
}

struct ADHDSymptom: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let symptomType: SymptomType
    let severity: Int // 1-5 scale
    let triggers: [String]
    let notes: String
    
    enum SymptomType: String, Codable, CaseIterable {
        case inattention = "Difficulty Focusing"
        case hyperactivity = "Restlessness"
        case impulsivity = "Impulsive Actions"
        case timeBlindness = "Time Management Issues"
        case overwhelm = "Feeling Overwhelmed"
        case procrastination = "Procrastination"
        case forgetfulness = "Forgetfulness"
        case emotionalRegulation = "Emotional Dysregulation"
    }
}

struct ProductivitySession: Identifiable, Codable {
    var id = UUID()
    let startTime: Date
    var endTime: Date?
    let taskType: String
    var completedSubtasks: Int
    let totalSubtasks: Int
    var distractionCount: Int = 0
    var focusScore: Double = 0.0 // 0-1
}

struct HabitEntry: Identifiable, Codable {
    var id = UUID()
    let habitId: UUID
    let date: Date
    let completed: Bool
    let notes: String
    let timeOfDay: Date
}

struct Habit: Identifiable, Codable {
    var id = UUID()
    let name: String
    let description: String
    let frequency: HabitFrequency
    let reminderTime: Date?
    var streak: Int = 0
    let category: HabitCategory
    let isADHDFriendly: Bool // Simple, short habits
    
    enum HabitFrequency: String, Codable {
        case daily = "Daily"
        case weekly = "Weekly"
        case custom = "Custom"
    }
    
    enum HabitCategory: String, Codable {
        case exercise = "Movement"
        case mindfulness = "Mindfulness"
        case sleep = "Sleep"
        case nutrition = "Nutrition"
        case medication = "Medication"
        case organization = "Organization"
    }
}

// MARK: - Gamification Models

struct Achievement: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let icon: String
    var unlockedAt: Date?
    let requirement: Int
    var progress: Int = 0
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
}

struct DailyStreak: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: Date?
}

// MARK: - ADHD Tracker Manager

class ADHDTrackerManager: ObservableObject {
    static let shared = ADHDTrackerManager()
    
    @Published var isTrackingEnabled: Bool = false
    @Published var userConsented: Bool = false
    @Published var behavioralInsights: [BehavioralInsight] = []
    @Published var symptoms: [ADHDSymptom] = []
    @Published var productivitySessions: [ProductivitySession] = []
    @Published var habits: [Habit] = []
    @Published var habitEntries: [HabitEntry] = []
    @Published var achievements: [Achievement] = []
    @Published var dailyStreak = DailyStreak()
    
    // Active session tracking
    @Published var currentSession: ProductivitySession?
    
    private init() {
        load()
        setupDefaultAchievements()
    }
    
    // MARK: - Consent & Privacy
    
    func enableTracking(withConsent: Bool) {
        userConsented = withConsent
        isTrackingEnabled = withConsent
        save()
    }
    
    func exportAllData() -> String {
        // Export all tracking data for user transparency
        let data = ADHDTrackerSnapshot(
            behavioralInsights: behavioralInsights,
            symptoms: symptoms,
            productivitySessions: productivitySessions,
            habits: habits,
            habitEntries: habitEntries
        )
        
        guard let jsonData = try? JSONEncoder().encode(data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "Error exporting data"
        }
        
        return jsonString
    }
    
    func deleteAllTrackingData() {
        behavioralInsights.removeAll()
        symptoms.removeAll()
        productivitySessions.removeAll()
        habitEntries.removeAll()
        save()
    }
    
    // MARK: - Behavioral Tracking
    
    func recordBehavioralInsight(category: BehavioralInsight.InsightCategory, value: Double, context: String = "") {
        guard isTrackingEnabled else { return }
        
        let insight = BehavioralInsight(
            timestamp: Date(),
            category: category,
            value: min(1.0, max(0.0, value)),
            context: context
        )
        behavioralInsights.append(insight)
        save()
    }
    
    func recordSymptom(type: ADHDSymptom.SymptomType, severity: Int, triggers: [String] = [], notes: String = "") {
        guard isTrackingEnabled else { return }
        
        let symptom = ADHDSymptom(
            date: Date(),
            symptomType: type,
            severity: min(5, max(1, severity)),
            triggers: triggers,
            notes: notes
        )
        symptoms.append(symptom)
        save()
    }
    
    // MARK: - Productivity Session Tracking
    
    func startProductivitySession(taskType: String, totalSubtasks: Int) {
        guard isTrackingEnabled else { return }
        
        currentSession = ProductivitySession(
            startTime: Date(),
            taskType: taskType,
            completedSubtasks: 0,
            totalSubtasks: totalSubtasks
        )
    }
    
    func recordDistraction() {
        guard isTrackingEnabled, var session = currentSession else { return }
        session.distractionCount += 1
        currentSession = session
    }
    
    func completeSubtask() {
        guard isTrackingEnabled, var session = currentSession else { return }
        session.completedSubtasks = min(session.totalSubtasks, session.completedSubtasks + 1)
        currentSession = session
    }
    
    func endProductivitySession(focusScore: Double) {
        guard isTrackingEnabled, var session = currentSession else { return }
        
        session.endTime = Date()
        session.focusScore = min(1.0, max(0.0, focusScore))
        productivitySessions.append(session)
        currentSession = nil
        
        // Record behavioral insight
        recordBehavioralInsight(
            category: .focus,
            value: focusScore,
            context: "Session: \(session.taskType)"
        )
        
        save()
        checkAchievements()
    }
    
    // MARK: - Habit Tracking
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
    }
    
    func recordHabitCompletion(habitId: UUID, completed: Bool, notes: String = "") {
        let entry = HabitEntry(
            habitId: habitId,
            date: Date(),
            completed: completed,
            notes: notes,
            timeOfDay: Date()
        )
        habitEntries.append(entry)
        
        // Update streak
        if completed, let habitIndex = habits.firstIndex(where: { $0.id == habitId }) {
            habits[habitIndex].streak += 1
        }
        
        updateDailyStreak()
        save()
        checkAchievements()
    }
    
    func getHabitStreak(habitId: UUID) -> Int {
        return habits.first(where: { $0.id == habitId })?.streak ?? 0
    }
    
    // MARK: - Insights & Analytics
    
    func getFocusTrend(days: Int = 7) -> [Double] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let focusInsights = behavioralInsights.filter {
            $0.category == .focus && $0.timestamp >= startDate
        }
        
        var dailyScores: [Double] = []
        for day in 0..<days {
            let dayStart = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayInsights = focusInsights.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            
            // Calculate average and ensure it's valid
            var avgScore: Double
            if dayInsights.isEmpty {
                avgScore = 0.0
            } else {
                let sum = dayInsights.map(\.value).reduce(0, +)
                avgScore = sum / Double(dayInsights.count)
            }
            
            // Ensure the score is a valid number
            if !avgScore.isFinite {
                avgScore = 0.0
            }
            
            dailyScores.insert(avgScore, at: 0)
        }
        
        return dailyScores
    }
    
    func getSymptomFrequency(type: ADHDSymptom.SymptomType, days: Int = 30) -> Int {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return symptoms.filter { $0.symptomType == type && $0.date >= startDate }.count
    }
    
    func getProductivityScore() -> Double {
        let recentSessions = productivitySessions.suffix(10)
        guard !recentSessions.isEmpty else { return 0.0 }
        
        let sum = recentSessions.map(\.focusScore).reduce(0, +)
        let score = sum / Double(recentSessions.count)
        
        // Ensure the score is valid (not NaN or Infinity)
        return score.isFinite ? score : 0.0
    }
    
    // MARK: - Gamification
    
    private func setupDefaultAchievements() {
        if achievements.isEmpty {
            achievements = [
                Achievement(title: "First Step", description: "Complete your first task", icon: "star.fill", unlockedAt: nil, requirement: 1),
                Achievement(title: "Week Warrior", description: "7-day streak", icon: "flame.fill", unlockedAt: nil, requirement: 7),
                Achievement(title: "Focus Master", description: "Complete 10 focused sessions", icon: "brain.head.profile", unlockedAt: nil, requirement: 10),
                Achievement(title: "Habit Hero", description: "Complete 30 habits", icon: "checkmark.circle.fill", unlockedAt: nil, requirement: 30),
                Achievement(title: "Consistency King", description: "30-day streak", icon: "crown.fill", unlockedAt: nil, requirement: 30)
            ]
        }
    }
    
    private func checkAchievements() {
        // Update achievement progress
        for index in achievements.indices {
            let achievement = achievements[index]
            guard !achievement.isUnlocked else { continue }
            
            var currentProgress = 0
            switch achievement.title {
            case "First Step":
                currentProgress = productivitySessions.filter { $0.completedSubtasks > 0 }.count
            case "Week Warrior":
                currentProgress = dailyStreak.currentStreak
            case "Focus Master":
                currentProgress = productivitySessions.count
            case "Habit Hero":
                currentProgress = habitEntries.filter(\.completed).count
            case "Consistency King":
                currentProgress = dailyStreak.longestStreak
            default:
                break
            }
            
            achievements[index].progress = currentProgress
            
            if currentProgress >= achievement.requirement {
                achievements[index].unlockedAt = Date()
                // Show celebration
                NotificationCenter.default.post(name: .achievementUnlocked, object: achievement)
            }
        }
        save()
    }
    
    private func updateDailyStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastActive = dailyStreak.lastActiveDate {
            let lastActiveDay = Calendar.current.startOfDay(for: lastActive)
            let daysSinceLastActive = Calendar.current.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
            
            if daysSinceLastActive == 0 {
                // Same day, no change
                return
            } else if daysSinceLastActive == 1 {
                // Consecutive day
                dailyStreak.currentStreak += 1
                dailyStreak.longestStreak = max(dailyStreak.longestStreak, dailyStreak.currentStreak)
            } else {
                // Streak broken
                dailyStreak.currentStreak = 1
            }
        } else {
            dailyStreak.currentStreak = 1
        }
        
        dailyStreak.lastActiveDate = today
        save()
    }
    
    // MARK: - Persistence
    
    private struct ADHDTrackerSnapshot: Codable {
        let behavioralInsights: [BehavioralInsight]
        let symptoms: [ADHDSymptom]
        let productivitySessions: [ProductivitySession]
        let habits: [Habit]
        let habitEntries: [HabitEntry]
    }
    
    func save() {
        let snapshot = ADHDTrackerSnapshot(
            behavioralInsights: behavioralInsights,
            symptoms: symptoms,
            productivitySessions: productivitySessions,
            habits: habits,
            habitEntries: habitEntries
        )
        
        if let encoded = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(encoded, forKey: "adhd_tracker_data")
            UserDefaults.standard.set(isTrackingEnabled, forKey: "adhd_tracking_enabled")
            UserDefaults.standard.set(userConsented, forKey: "adhd_user_consented")
        }
    }
    
    func load() {
        isTrackingEnabled = UserDefaults.standard.bool(forKey: "adhd_tracking_enabled")
        userConsented = UserDefaults.standard.bool(forKey: "adhd_user_consented")
        
        if let data = UserDefaults.standard.data(forKey: "adhd_tracker_data"),
           let snapshot = try? JSONDecoder().decode(ADHDTrackerSnapshot.self, from: data) {
            behavioralInsights = snapshot.behavioralInsights
            symptoms = snapshot.symptoms
            productivitySessions = snapshot.productivitySessions
            habits = snapshot.habits
            habitEntries = snapshot.habitEntries
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

