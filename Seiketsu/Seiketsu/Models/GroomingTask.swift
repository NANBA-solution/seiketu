import Foundation

struct GroomingTask: Codable, Identifiable, Equatable {
    var id: String { category.rawValue }
    let category: GroomingCategory
    var lastCompletedAt: Date?
    var averageIntervalDays: Double
    var nextDueAt: Date
    var completionHistory: [Date]
    var ignoredNotificationCount: Int

    init(category: GroomingCategory, now: Date = .now) {
        self.category = category
        self.lastCompletedAt = nil
        self.averageIntervalDays = category.defaultIntervalDays
        self.nextDueAt = Calendar.current.date(
            byAdding: .day,
            value: Int(category.defaultIntervalDays.rounded()),
            to: now
        ) ?? now
        self.completionHistory = []
        self.ignoredNotificationCount = 0
    }

    var daysUntilDue: Int {
        let start = Calendar.current.startOfDay(for: .now)
        let due = Calendar.current.startOfDay(for: nextDueAt)
        return Calendar.current.dateComponents([.day], from: start, to: due).day ?? 0
    }

    var statusMessage: String {
        let days = daysUntilDue
        if days < 0 { return "ケアしよう" }
        if days == 0 { return "今日ケアしよう" }
        if days <= 2 { return "そろそろケアの時期" }
        return "まだ余裕あり"
    }

    var daysLeftLabel: String {
        let days = daysUntilDue
        if days < 0 { return "期限超過" }
        if days == 0 { return "今日" }
        return "あと\(days)日"
    }

    var isDueOrOverdue: Bool {
        daysUntilDue <= 0
    }

    mutating func markDone(at date: Date = .now) {
        if let last = lastCompletedAt {
            let interval = date.timeIntervalSince(last) / 86_400
            if interval >= 1 {
                let samples = completionHistory.count + 1
                averageIntervalDays = ((averageIntervalDays * Double(samples - 1)) + interval) / Double(samples)
            }
        }
        lastCompletedAt = date
        completionHistory.append(date)
        if completionHistory.count > 24 {
            completionHistory.removeFirst(completionHistory.count - 24)
        }
        ignoredNotificationCount = 0
        let days = max(1, Int(averageIntervalDays.rounded()))
        nextDueAt = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    mutating func applyIgnoredPenalty() {
        ignoredNotificationCount += 1
        guard ignoredNotificationCount >= 2 else { return }
        averageIntervalDays = min(averageIntervalDays * 1.15, 60)
        ignoredNotificationCount = 0
        let days = max(1, Int(averageIntervalDays.rounded()))
        if let base = lastCompletedAt ?? Calendar.current.date(byAdding: .day, value: -days, to: nextDueAt) {
            nextDueAt = Calendar.current.date(byAdding: .day, value: days, to: base) ?? nextDueAt
        }
    }
}

struct GroomingRecord: Identifiable {
    let id = UUID()
    let category: GroomingCategory
    let completedAt: Date
}
