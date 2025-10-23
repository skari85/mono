import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var adhdTracker = ADHDTrackerManager.shared
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var newTaskTitle: String = ""
    @State private var calendarMode: Int = 0 // 0=Month, 1=Week
    @State private var remindersEnabled: Bool = false
    @State private var showProductivitySession = false
    @State private var currentTaskForSession: TaskItem?

    private func color(for priority: TaskPriority) -> Color {
        switch priority { case .high: return .cassetteRed; case .normal: return .cassetteTeal; case .low: return .cassetteTextMedium }
    }

    @State private var showDatePicker: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ADHD-friendly productivity banner
                if adhdTracker.isTrackingEnabled {
                    productivityBanner
                }
                
                // Calendar mode toggle
                Picker("Mode", selection: $calendarMode) {
                    Text("Month").tag(0)
                    Text("Week").tag(1)
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                // Date selector
                if calendarMode == 0 {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)
                } else {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                }

                // Reminders toggle
                Toggle(isOn: $remindersEnabled) {
                    Label("Reminders", systemImage: "bell")
                }
                .padding(.horizontal)
                .onChange(of: remindersEnabled) { _, enabled in
                    if enabled { dataManager.requestNotificationPermissionsIfNeeded() }
                }

                List {
                    Section(header: Text("Tasks")) {
                        ForEach(filteredTasks) { task in
                            HStack {
                                Circle()
                                    .fill(color(for: task.priority))
                                    .frame(width: 8, height: 8)
                                Button(action: {
                                    completeTask(task)
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .strikethrough(task.isCompleted)
                                    
                                    // ADHD-friendly: Show task breakdown hint
                                    if task.title.count > 30 && !task.isCompleted {
                                        Text("💡 Break into smaller steps")
                                            .font(.caption2)
                                            .foregroundColor(.cassetteOrange)
                                    }
                                }
                                
                                Spacer()
                                
                                // Focus session button for ADHD tracking
                                if adhdTracker.isTrackingEnabled && !task.isCompleted {
                                    Button(action: {
                                        startFocusSession(for: task)
                                    }) {
                                        Image(systemName: "brain")
                                            .font(.caption)
                                            .foregroundColor(.cassetteTeal)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if let due = task.dueDate {
                                    DatePicker("", selection: Binding(
                                        get: { due },
                                        set: { dataManager.updateTaskDueDate(task.id, newDate: $0) }
                                    ), displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.cassetteTeal)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Menu {
                                    Button("High") { if let idx = dataManager.tasks.firstIndex(where: { $0.id == task.id }) { dataManager.tasks[idx].priority = .high; dataManager.save() } }
                                    Button("Normal") { if let idx = dataManager.tasks.firstIndex(where: { $0.id == task.id }) { dataManager.tasks[idx].priority = .normal; dataManager.save() } }
                                    Button("Low") { if let idx = dataManager.tasks.firstIndex(where: { $0.id == task.id }) { dataManager.tasks[idx].priority = .low; dataManager.save() } }
                                } label: {
                                    Label("Priority", systemImage: "flag")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    dataManager.removeTask(task.id)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                HStack {
                    TextField("New task…", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let t = TaskItem(title: newTaskTitle, dueDate: selectedDate, priority: .normal)
                        dataManager.addTask(t)
                        newTaskTitle = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                .padding()
            }
            .navigationTitle("Tasks")
            .sheet(isPresented: $showProductivitySession) {
                if let task = currentTaskForSession {
                    FocusSessionView(task: task)
                }
            }
        }
    }
    
    private var productivityBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🎯 Focus Mode Available")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.cassetteTextDark)
                Text("Tap brain icon to start a tracked session")
                    .font(.caption2)
                    .foregroundColor(.cassetteTextMedium)
            }
            Spacer()
        }
        .padding(12)
        .background(
            HandDrawnRoundedRectangle(cornerRadius: 8, roughness: 3.0)
                .fill(Color.cassetteTeal.opacity(0.15))
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func completeTask(_ task: TaskItem) {
        dataManager.toggleTask(task.id)
        if task.isCompleted {
            NotificationsManager.cancelTaskReminder(id: task.id)
        }
        
        // Track completion in ADHD tracker
        if adhdTracker.isTrackingEnabled && !task.isCompleted {
            adhdTracker.recordBehavioralInsight(
                category: .taskCompletion,
                value: 1.0,
                context: "Completed: \(task.title)"
            )
        }
    }
    
    private func startFocusSession(for task: TaskItem) {
        currentTaskForSession = task
        showProductivitySession = true
    }

    private var filteredTasks: [TaskItem] {
        dataManager.tasks.filter { task in
            if let due = task.dueDate {
                return Calendar.current.isDate(due, inSameDayAs: selectedDate)
            }
            return false
        }
        .sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }
}

// MARK: - Focus Session View for ADHD-friendly productivity tracking

struct FocusSessionView: View {
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tracker = ADHDTrackerManager.shared
    @State private var sessionStartTime = Date()
    @State private var subtasksCompleted = 0
    @State private var totalSubtasks = 3
    @State private var distractionCount = 0
    @State private var sessionDuration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Task title
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Timer
                Text(formattedDuration(sessionDuration))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.cassetteTeal)
                
                // Subtasks progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Subtasks")
                            .font(.headline)
                        Spacer()
                        Text("\(subtasksCompleted)/\(totalSubtasks)")
                            .font(.headline)
                            .foregroundColor(.cassetteTeal)
                    }
                    
                    ProgressView(value: Double(subtasksCompleted), total: Double(totalSubtasks))
                        .tint(.cassetteTeal)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            if subtasksCompleted < totalSubtasks {
                                subtasksCompleted += 1
                                tracker.completeSubtask()
                            }
                        }) {
                            Label("Complete Step", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.cassetteTeal)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            totalSubtasks += 1
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.cassetteTextMedium)
                        }
                    }
                }
                .padding()
                .background(
                    HandDrawnRoundedRectangle(cornerRadius: 12, roughness: 4.0)
                        .fill(Color.cassetteBeige.opacity(0.3))
                )
                
                // Distraction counter
                VStack(spacing: 8) {
                    Text("Distractions: \(distractionCount)")
                        .font(.subheadline)
                        .foregroundColor(.cassetteTextMedium)
                    
                    Button(action: {
                        distractionCount += 1
                        tracker.recordDistraction()
                        tracker.recordSymptom(type: .inattention, severity: 2, notes: "During task: \(task.title)")
                    }) {
                        Label("Log Distraction", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.cassetteOrange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.cassetteOrange.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                // End session button
                Button(action: endSession) {
                    Text("End Focus Session")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cassetteOrange)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Focus Session")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                tracker.startProductivitySession(taskType: task.title, totalSubtasks: totalSubtasks)
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            sessionDuration += 1
        }
    }
    
    private func endSession() {
        timer?.invalidate()
        
        // Calculate focus score based on completion and distractions
        let completionRate = Double(subtasksCompleted) / Double(totalSubtasks)
        let distractionPenalty = Double(distractionCount) * 0.1
        let focusScore = max(0.0, min(1.0, completionRate - distractionPenalty))
        
        tracker.endProductivitySession(focusScore: focusScore)
        dismiss()
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

