import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var newTaskTitle: String = ""
    @State private var calendarMode: Int = 0 // 0=Month, 1=Week
    @State private var remindersEnabled: Bool = false

    private func color(for priority: TaskPriority) -> Color {
        switch priority { case .high: return .cassetteRed; case .normal: return .cassetteTeal; case .low: return .cassetteTextMedium }
    }

    @State private var showDatePicker: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                .onChange(of: remindersEnabled) { enabled in
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
                                    dataManager.toggleTask(task.id)
                                    if task.isCompleted { NotificationsManager.cancelTaskReminder(id: task.id) }
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                                Text(task.title)
                                    .strikethrough(task.isCompleted)
                                Spacer()
                                if let due = task.dueDate {
                                    DatePicker("", selection: Binding(
                                        get: { due },
                                        set: { dataManager.updateTaskDueDate(task.id, newDate: $0) }
                                    ), displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.cassetteTeal)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Menu {
                                    Button("High") { if let idx = dataManager.tasks.firstIndex(where: { $0.id == task.id }) { dataManager.tasks[idx].priority = .high; dataManager.save() } }
                                    Button("Normal") { if let idx = dataManager.tasks.firstIndex(where: { $0.id == task.id }) { dataManager.tasks[idx].priority = .normal; dataManager.save() } }
                                    Button("Low") { if let idx = dataManager.tasks.firstIndex(where: { $0.id == task.id }) { dataManager.tasks[idx].priority = .low; dataManager.save() } }
                                } label: {
                                    Label("Priority", systemImage: "flag")
                                }
                            }

                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
        }
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

