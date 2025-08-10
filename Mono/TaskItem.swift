import Foundation

enum TaskPriority: String, Codable, CaseIterable { case low, normal, high }

final class TaskItem: Identifiable, ObservableObject, Codable {
    let id: UUID
    @Published var title: String
    @Published var dueDate: Date?
    @Published var isCompleted: Bool
    @Published var priority: TaskPriority

    @Published var createdAt: Date
    @Published var sourceThoughtId: UUID?

    init(id: UUID = UUID(), title: String, dueDate: Date? = nil, isCompleted: Bool = false, priority: TaskPriority = .normal, createdAt: Date = Date(), sourceThoughtId: UUID? = nil) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
        self.sourceThoughtId = sourceThoughtId
    }

    enum CodingKeys: String, CodingKey { case id, title, dueDate, isCompleted, priority, createdAt, sourceThoughtId }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        dueDate = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        priority = (try? c.decode(TaskPriority.self, forKey: .priority)) ?? .normal
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        sourceThoughtId = try c.decodeIfPresent(UUID.self, forKey: .sourceThoughtId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(dueDate, forKey: .dueDate)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encode(priority, forKey: .priority)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(sourceThoughtId, forKey: .sourceThoughtId)
    }
}

