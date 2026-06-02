import Foundation

struct GroomingTask: Identifiable, Equatable {
    var id: String { category.rawValue }
    let category: GroomingCategory
    var lastCompletedAt: Date?
    var averageIntervalDays: Double
    var nextDueAt: Date
    var completionHistory: [Date]
    var ignoredNotificationCount: Int
    var hasPendingNotification: Bool
    var lastNotifiedAt: Date?
    var learnedFollowUpHours: Double
    var maxFollowUps: Int
    /// OFF のときは通知を予約しない（期限到来後は ✓ のみで記録可）
    var notificationsEnabled: Bool

    /// `firstDueInDays` … 初回セット時の通知までの日数（省略時はカテゴリ既定周期）
    init(category: GroomingCategory, now: Date = .now, firstDueInDays: Int? = nil) {
        self.category = category
        self.lastCompletedAt = nil
        self.averageIntervalDays = category.defaultIntervalDays
        let dueOffset = firstDueInDays ?? Int(category.defaultIntervalDays.rounded())
        self.nextDueAt = Calendar.current.date(
            byAdding: .day,
            value: max(1, dueOffset),
            to: now
        ) ?? now
        self.completionHistory = []
        self.ignoredNotificationCount = 0
        self.hasPendingNotification = false
        self.lastNotifiedAt = nil
        self.learnedFollowUpHours = 8
        self.maxFollowUps = 3
        self.notificationsEnabled = true
    }

    var daysUntilDue: Int {
        let start = Calendar.current.startOfDay(for: .now)
        let due = Calendar.current.startOfDay(for: nextDueAt)
        return Calendar.current.dateComponents([.day], from: start, to: due).day ?? 0
    }

    /// スコア・行バー共通: 次回までの余裕率（0=期限当日以下, 1=周期の始まり）。
    /// 未ケアカテゴリは常に 0（%リングと同じ。初回3日でも満タンにしない）。
    var cycleProgress: Double {
        guard !completionHistory.isEmpty else { return 0 }
        let interval = max(averageIntervalDays, 1)
        let remaining = Double(max(daysUntilDue, 0))
        return min(1, remaining / interval)
    }

    /// 清潔感スコア（%）への寄与。`cycleProgress` と同一。
    var healthScore: Double { cycleProgress }

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

    var canComplete: Bool {
        guard isDueOrOverdue else { return false }
        if !notificationsEnabled { return true }
        return hasPendingNotification
    }

    /// 通知間隔の学習用（表示スケジュールは 9:00 / 19:00 固定）
    var followUpScheduleHours: [Double] {
        let base = min(max(learnedFollowUpHours, 2), 24)
        return (1...maxFollowUps).map { step in
            min(base * pow(1.8, Double(step - 1)), 72)
        }
    }

    mutating func markDone(at date: Date = .now) {
        if let notifiedAt = lastNotifiedAt {
            let responseHours = max(0.5, date.timeIntervalSince(notifiedAt) / 3600)
            let alpha = 0.22
            learnedFollowUpHours = min(max((1 - alpha) * learnedFollowUpHours + alpha * responseHours, 2), 24)
        }
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
        hasPendingNotification = false
        lastNotifiedAt = nil
        let days = max(1, Int(averageIntervalDays.rounded()))
        nextDueAt = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    mutating func markNotified(at date: Date = .now) {
        hasPendingNotification = true
        lastNotifiedAt = date
    }

    mutating func applyIgnoredPenalty() {
        ignoredNotificationCount += 1
        guard ignoredNotificationCount >= 2 else { return }
        averageIntervalDays = min(averageIntervalDays * 1.15, 60)
        learnedFollowUpHours = min(learnedFollowUpHours * 1.12, 36)
        ignoredNotificationCount = 0
        let days = max(1, Int(averageIntervalDays.rounded()))
        if let base = lastCompletedAt ?? Calendar.current.date(byAdding: .day, value: -days, to: nextDueAt) {
            nextDueAt = Calendar.current.date(byAdding: .day, value: days, to: base) ?? nextDueAt
        }
    }
}

extension GroomingTask: Codable {
    private enum CodingKeys: String, CodingKey {
        case category, lastCompletedAt, averageIntervalDays, nextDueAt
        case completionHistory, ignoredNotificationCount, hasPendingNotification
        case lastNotifiedAt, learnedFollowUpHours, maxFollowUps, notificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        category = try c.decode(GroomingCategory.self, forKey: .category)
        lastCompletedAt = try c.decodeIfPresent(Date.self, forKey: .lastCompletedAt)
        averageIntervalDays = try c.decode(Double.self, forKey: .averageIntervalDays)
        nextDueAt = try c.decode(Date.self, forKey: .nextDueAt)
        completionHistory = try c.decode([Date].self, forKey: .completionHistory)
        ignoredNotificationCount = try c.decode(Int.self, forKey: .ignoredNotificationCount)
        hasPendingNotification = try c.decode(Bool.self, forKey: .hasPendingNotification)
        lastNotifiedAt = try c.decodeIfPresent(Date.self, forKey: .lastNotifiedAt)
        learnedFollowUpHours = try c.decode(Double.self, forKey: .learnedFollowUpHours)
        maxFollowUps = try c.decode(Int.self, forKey: .maxFollowUps)
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(category, forKey: .category)
        try c.encodeIfPresent(lastCompletedAt, forKey: .lastCompletedAt)
        try c.encode(averageIntervalDays, forKey: .averageIntervalDays)
        try c.encode(nextDueAt, forKey: .nextDueAt)
        try c.encode(completionHistory, forKey: .completionHistory)
        try c.encode(ignoredNotificationCount, forKey: .ignoredNotificationCount)
        try c.encode(hasPendingNotification, forKey: .hasPendingNotification)
        try c.encodeIfPresent(lastNotifiedAt, forKey: .lastNotifiedAt)
        try c.encode(learnedFollowUpHours, forKey: .learnedFollowUpHours)
        try c.encode(maxFollowUps, forKey: .maxFollowUps)
        try c.encode(notificationsEnabled, forKey: .notificationsEnabled)
    }
}

struct GroomingRecord: Identifiable {
    let id = UUID()
    let category: GroomingCategory
    let completedAt: Date
}
