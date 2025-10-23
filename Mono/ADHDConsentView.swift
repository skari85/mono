//
//  ADHDConsentView.swift
//  Mono
//
//  Privacy-first consent for ADHD tracking
//

import SwiftUI

struct ADHDConsentView: View {
    @StateObject private var tracker = ADHDTrackerManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager
    
    @State private var hasReadDisclaimer = false
    @State private var acceptsPrivacy = false
    @State private var understandsLimitations = false
    
    var canProceed: Bool {
        hasReadDisclaimer && acceptsPrivacy && understandsLimitations
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.cassetteTeal)
                        
                        Text("Privacy & Consent")
                            .font(settingsManager.fontSize.titleFont)
                            .fontWeight(.bold)
                            .foregroundColor(.cassetteTextDark)
                        
                        Text("Your privacy and wellbeing come first")
                            .font(settingsManager.fontSize.bodyFont)
                            .foregroundColor(.cassetteTextMedium)
                    }
                    .padding(.top, 20)
                    
                    // Important Disclaimers
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Important Information")
                            .font(settingsManager.fontSize.headlineFont)
                            .fontWeight(.bold)
                        
                        DisclaimerSection(
                            icon: "exclamationmark.triangle.fill",
                            title: "Not a Medical Tool",
                            description: "This toolkit is NOT a diagnostic tool and cannot replace professional medical advice, diagnosis, or treatment. If you have concerns about ADHD, please consult a qualified healthcare professional.",
                            color: .cassetteRed
                        )
                        
                        DisclaimerSection(
                            icon: "lock.shield.fill",
                            title: "Your Data Stays Private",
                            description: "All tracking data is stored locally on your device. Nothing is shared with third parties, sent to servers, or used for advertising. You can export or delete your data at any time.",
                            color: .cassetteTeal
                        )
                        
                        DisclaimerSection(
                            icon: "chart.bar.fill",
                            title: "For Personal Reflection Only",
                            description: "Insights and scores are meant to help you understand your own patterns. They are not clinical assessments and should not be used for medical decisions.",
                            color: .cassetteBlue
                        )
                        
                        DisclaimerSection(
                            icon: "person.fill.questionmark",
                            title: "Seek Professional Help",
                            description: "If you're struggling, please reach out to a mental health professional. This app supports your journey but doesn't replace clinical care.",
                            color: .cassetteSage
                        )
                    }
                    .padding(.horizontal)
                    
                    // Consent Checkboxes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Please Confirm")
                            .font(settingsManager.fontSize.headlineFont)
                            .fontWeight(.bold)
                        
                        ConsentCheckbox(
                            isChecked: $hasReadDisclaimer,
                            text: "I have read and understood the disclaimers above"
                        )
                        
                        ConsentCheckbox(
                            isChecked: $acceptsPrivacy,
                            text: "I understand my data is stored locally and I can delete it anytime"
                        )
                        
                        ConsentCheckbox(
                            isChecked: $understandsLimitations,
                            text: "I understand this is not a replacement for professional medical care"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            tracker.enableTracking(withConsent: true)
                            dismiss()
                        }) {
                            Text("I Agree - Enable Tracking")
                                .font(settingsManager.fontSize.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                                        .fill(canProceed ? Color.cassetteTeal : Color.gray)
                                )
                        }
                        .disabled(!canProceed)
                        
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(settingsManager.fontSize.bodyFont)
                                .foregroundColor(.cassetteTextMedium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(
                Color.cassetteWarmGray.opacity(0.3)
                    .overlay(PaperTexture(opacity: 0.2, seed: 0xC0A5E47))
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DisclaimerSection: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.cassetteTextDark)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.cassetteTextMedium)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                .fill(color.opacity(0.1))
        )
    }
}

struct ConsentCheckbox: View {
    @Binding var isChecked: Bool
    let text: String
    
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isChecked ? .cassetteTeal : .gray)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(.cassetteTextDark)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views for Symptom Logger & Habit Creator

struct SymptomLoggerView: View {
    @StateObject private var tracker = ADHDTrackerManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager
    
    @State private var selectedSymptom: ADHDSymptom.SymptomType = .inattention
    @State private var severity: Int = 3
    @State private var triggers: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Symptom Type") {
                    Picker("Type", selection: $selectedSymptom) {
                        ForEach(ADHDSymptom.SymptomType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section("Severity (1-5)") {
                    Stepper("\(severity)", value: $severity, in: 1...5)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= severity ? Color.cassetteOrange : Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                
                Section("Triggers (optional)") {
                    TextField("What triggered this? (e.g., stress, lack of sleep)", text: $triggers)
                }
                
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: saveSymptom) {
                        Text("Log Symptom")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.cassetteTeal)
                }
            }
            .navigationTitle("Log Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveSymptom() {
        let triggerList = triggers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        tracker.recordSymptom(
            type: selectedSymptom,
            severity: severity,
            triggers: triggerList,
            notes: notes
        )
        dismiss()
    }
}

struct HabitCreatorView: View {
    @StateObject private var tracker = ADHDTrackerManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager
    
    @State private var habitName: String = ""
    @State private var habitDescription: String = ""
    @State private var frequency: Habit.HabitFrequency = .daily
    @State private var category: Habit.HabitCategory = .exercise
    @State private var enableReminder: Bool = false
    @State private var reminderTime: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name (keep it short!)", text: $habitName)
                    TextField("Description (optional)", text: $habitDescription)
                }
                
                Section("Frequency") {
                    Picker("How often?", selection: $frequency) {
                        ForEach([Habit.HabitFrequency.daily, .weekly, .custom], id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach([Habit.HabitCategory.exercise, .mindfulness, .sleep, .nutrition, .medication, .organization], id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section("Reminder") {
                    Toggle("Enable Reminder", isOn: $enableReminder)
                    if enableReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section {
                    Text("💡 ADHD-Friendly Tip: Start with small, achievable habits (2-5 minutes). Build consistency before increasing difficulty.")
                        .font(.caption)
                        .foregroundColor(.cassetteTeal)
                }
                
                Section {
                    Button(action: createHabit) {
                        Text("Create Habit")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.cassetteTeal)
                    .disabled(habitName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Create Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createHabit() {
        let habit = Habit(
            name: habitName,
            description: habitDescription,
            frequency: frequency,
            reminderTime: enableReminder ? reminderTime : nil,
            category: category,
            isADHDFriendly: habitName.count < 30 // Short habits are ADHD-friendly
        )
        tracker.addHabit(habit)
        dismiss()
    }
}

