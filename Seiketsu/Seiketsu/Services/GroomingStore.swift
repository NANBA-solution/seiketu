import Foundation
import SwiftUI
import UserNotifications

enum StartDateMode: String, Codable, CaseIterable, Identifiable {
    case auto
    case manual

    var id: String { rawValue }
    var title: String { self == .auto ? "自動（今日）" : "手動" }
}

@MainActor
final class GroomingStore: ObservableObject {
    @Published private(set) var tasks: [GroomingTask] = []
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }
    @Published var startDateMode: StartDateMode {
        didSet { UserDefaults.standard.set(startDateMode.rawValue, forKey: Keys.startDateMode) }
    }
    @Published var manualStartDate: Date {
        didSet { UserDefaults.standard.set(manualStartDate, forKey: Keys.manualStartDate) }
    }

    private let notificationScheduler: NotificationScheduler
    private static let storageKey = "seiketsu.tasks.v1"
    private var didRefreshScheduleThisSession = false

    /// 初回セット時は全カテゴリともに「あと3日」で通知
    static let initialDueOffsetDays = 3

    private enum Keys {
        static let onboarding = "seiketsu.onboarding.completed"
        static let startDateMode = "seiketsu.startDateMode"
        static let manualStartDate = "seiketsu.manualStartDate"
    }

    init(notificationScheduler: NotificationScheduler = NotificationScheduler()) {
        self.notificationScheduler = notificationScheduler
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.onboarding)
        let savedMode = UserDefaults.standard.string(forKey: Keys.startDateMode)
        self.startDateMode = StartDateMode(rawValue: savedMode ?? "") ?? .auto
        self.manualStartDate = UserDefaults.standard.object(forKey: Keys.manualStartDate) as? Date ?? .now
        loadTasks()
    }

    var hasAnyCompletion: Bool {
        tasks.contains { !$0.completionHistory.isEmpty }
    }

    /// 清潔感スコア（0〜100）。全カテゴリの `healthScore` 平均（未ケアは0寄与）。
    var groomingScorePercent: Int {
        guard !tasks.isEmpty else { return 0 }
        let sum = tasks.reduce(0.0) { $0 + $1.healthScore }
        let average = sum / Double(tasks.count)
        return Int((average * 100).rounded(.toNearestOrAwayFromZero))
    }

    struct StatusSummary {
        let overdue: Int
        let soon: Int
        let onTrack: Int
        let awaitingFirst: Int
    }

    var statusSummary: StatusSummary {
        var overdue = 0, soon = 0, onTrack = 0, awaitingFirst = 0
        for task in tasks {
            if task.completionHistory.isEmpty {
                awaitingFirst += 1
                continue
            }
            if task.daysUntilDue < 0 { overdue += 1 }
            else if task.daysUntilDue <= 2 { soon += 1 }
            else { onTrack += 1 }
        }
        return StatusSummary(overdue: overdue, soon: soon, onTrack: onTrack, awaitingFirst: awaitingFirst)
    }

    var headerTitle: String {
        let s = statusSummary
        if s.overdue > 0 { return "ケアが必要な項目があります" }
        if tasks.contains(where: { $0.daysUntilDue == 0 }) { return "今日ケアしよう" }

        if !hasAnyCompletion {
            let minDays = tasks.map(\.daysUntilDue).min() ?? Self.initialDueOffsetDays
            return "初回ケアまであと\(minDays)日"
        }

        switch groomingScorePercent {
        case 0..<25: return "清潔感スコア \(groomingScorePercent)%"
        case 25..<50: return "清潔感スコア \(groomingScorePercent)%"
        case 50..<75: return "清潔感スコア \(groomingScorePercent)%"
        case 75..<100: return "清潔感スコア \(groomingScorePercent)%"
        default: return "清潔感スコア 100%"
        }
    }

    var headerSubtitle: String {
        let s = statusSummary
        if s.overdue > 0 { return "遅れ\(s.overdue)件 — 早めのケアでスコアを戻そう" }
        if tasks.contains(where: { $0.daysUntilDue == 0 }) {
            return "今日が期限の項目があります"
        }

        if !hasAnyCompletion {
            return "通知から「やった！」で記録が始まります"
        }

        switch groomingScorePercent {
        case 0..<25: return "まずは1つケアしてスコアを上げよう"
        case 25..<50: return "気になる項目をケアして安定させよう"
        case 50..<75: return "いいペース。あと少しでさらに安定"
        case 75..<100: return "かなり順調。清潔感キープ中"
        default: return "完璧に近い状態です"
        }
    }

    func tasks(on day: Date) -> [GroomingTask] {
        let target = Calendar.current.startOfDay(for: day)
        return tasks.filter {
            Calendar.current.isDate(Calendar.current.startOfDay(for: $0.nextDueAt), inSameDayAs: target)
        }
        .sorted { $0.category.title < $1.category.title }
    }

    var allRecords: [GroomingRecord] {
        tasks.flatMap { task in
            task.completionHistory.map { GroomingRecord(category: task.category, completedAt: $0) }
        }
        .sorted { $0.completedAt > $1.completedAt }
    }

    func task(for category: GroomingCategory) -> GroomingTask? {
        tasks.first { $0.category == category }
    }

    var effectiveStartDate: Date {
        switch startDateMode {
        case .auto:
            return Calendar.current.startOfDay(for: .now)
        case .manual:
            return Calendar.current.startOfDay(for: manualStartDate)
        }
    }

    func initializeDefaults(anchorDate: Date? = nil) {
        let base = Calendar.current.startOfDay(for: anchorDate ?? effectiveStartDate)
        tasks = GroomingCategory.allCases.map {
            GroomingTask(category: $0, now: base, firstDueInDays: Self.initialDueOffsetDays)
        }
        persist()
    }

    func completeOnboarding() {
        if tasks.isEmpty { initializeDefaults(anchorDate: effectiveStartDate) }
        hasCompletedOnboarding = true
        Task { await rescheduleAllNotifications() }
    }

    func updateStartDatePreference(mode: StartDateMode, manualDate: Date) {
        startDateMode = mode
        manualStartDate = manualDate

        let anchor = Calendar.current.startOfDay(for: mode == .auto ? .now : manualDate)
        if tasks.isEmpty {
            initializeDefaults(anchorDate: anchor)
            return
        }

        for index in tasks.indices {
            let interval = max(1, Int(tasks[index].averageIntervalDays.rounded()))
            tasks[index].nextDueAt = Calendar.current.date(byAdding: .day, value: interval, to: anchor) ?? anchor
            tasks[index].hasPendingNotification = false
            tasks[index].lastNotifiedAt = nil
            if tasks[index].completionHistory.isEmpty {
                tasks[index].lastCompletedAt = anchor
            }
        }
        persist()
        Task {
            for task in tasks {
                await notificationScheduler.clearDelivered(category: task.category)
            }
            await rescheduleAllNotifications()
        }
    }

    func setNotificationsEnabled(_ enabled: Bool, for category: GroomingCategory) {
        guard let index = tasks.firstIndex(where: { $0.category == category }) else { return }
        tasks[index].notificationsEnabled = enabled
        if !enabled {
            tasks[index].hasPendingNotification = false
            tasks[index].lastNotifiedAt = nil
        }
        persist()
        Task {
            if enabled {
                await notificationScheduler.schedule(task: tasks[index])
            } else {
                await notificationScheduler.clearDelivered(category: category)
            }
        }
    }

    func updateNextDueDate(for category: GroomingCategory, to date: Date) {
        guard let index = tasks.firstIndex(where: { $0.category == category }) else { return }
        let normalized = Calendar.current.startOfDay(for: date)
        tasks[index].nextDueAt = normalized
        tasks[index].hasPendingNotification = false
        tasks[index].lastNotifiedAt = nil
        persist()
        Task {
            await notificationScheduler.clearDelivered(category: tasks[index].category)
            await notificationScheduler.schedule(task: tasks[index])
        }
    }

    func markDone(category: GroomingCategory, fromNotification: Bool = false) {
        guard let index = tasks.firstIndex(where: { $0.category == category }) else { return }
        if fromNotification {
            alignDueForNotification(at: index)
            if !tasks[index].hasPendingNotification {
                tasks[index].markNotified()
            }
        } else {
            guard tasks[index].canComplete else { return }
        }
        tasks[index].markDone()
        persist()
        NotificationCenter.default.post(
            name: .groomingMarkedDone,
            object: nil,
            userInfo: ["category": category.rawValue]
        )
        Task {
            await notificationScheduler.clearDelivered(category: category)
            await notificationScheduler.schedule(task: tasks[index])
        }
    }

    func markNotified(category: GroomingCategory) {
        guard let index = tasks.firstIndex(where: { $0.category == category }) else { return }
        alignDueForNotification(at: index)
        tasks[index].markNotified()
        persist()
    }

    /// 通知タップ／「やった！」アクション → 記録してスコアに反映
    func handleNotificationInteraction(category: GroomingCategory, actionIdentifier: String) {
        let doneAction = actionIdentifier == "MARK_DONE"
        let defaultTap = actionIdentifier == UNNotificationDefaultActionIdentifier
        if doneAction || defaultTap {
            markDone(category: category, fromNotification: true)
        } else {
            markNotified(category: category)
        }
    }

    private func alignDueForNotification(at index: Int) {
        let today = Calendar.current.startOfDay(for: .now)
        let dueDay = Calendar.current.startOfDay(for: tasks[index].nextDueAt)
        if dueDay > today {
            tasks[index].nextDueAt = today
        }
    }

    func syncDeliveredNotificationState() {
        Task {
            let delivered = await notificationScheduler.deliveredPendingCategories()
            await MainActor.run {
                for index in tasks.indices {
                    let category = tasks[index].category
                    if delivered.contains(category) && tasks[index].isDueOrOverdue {
                        tasks[index].markNotified()
                    }
                }
                persist()
            }
        }
    }

    /// 起動時（1セッション1回）: 期限到来タスクを「通知済み」にし、保存済み `nextDueAt` と通知を同期する。
    func refreshAutoScheduleOnLaunch() {
        guard hasCompletedOnboarding, !tasks.isEmpty else { return }

        if !didRefreshScheduleThisSession {
            didRefreshScheduleThisSession = true
            var changed = false
            for index in tasks.indices {
                guard tasks[index].notificationsEnabled else { continue }
                if tasks[index].isDueOrOverdue, !tasks[index].hasPendingNotification {
                    let dueMoment = tasks[index].nextDueAt
                    tasks[index].markNotified(at: max(dueMoment, .now))
                    changed = true
                }
            }
            if changed { persist() }
            Task { await rescheduleAllNotifications() }
        }
        syncDeliveredNotificationState()
    }

    /// 初回のみ3日後。2回目以降は `markDone` が `averageIntervalDays`（学習込み）で自動設定。
    func nextDueDescription(for task: GroomingTask) -> String {
        if task.completionHistory.isEmpty {
            let days = task.daysUntilDue
            if days < 0 { return "初回: 期限超過" }
            if days == 0 { return "初回: 今日" }
            return "初回: あと\(days)日"
        }
        let days = max(1, Int(task.averageIntervalDays.rounded()))
        return "次回: 約\(days)日後（自動）"
    }

    func rescheduleAllNotifications() async {
        _ = await notificationScheduler.requestAuthorization()
        for task in tasks where task.notificationsEnabled {
            await notificationScheduler.schedule(task: task)
        }
    }

    // MARK: - テスト用

    /// 指定秒後にテスト通知（アプリをバックグラウンドにすると表示されやすい）
    @discardableResult
    func fireTestNotification(
        for category: GroomingCategory,
        afterSeconds: TimeInterval = 5
    ) async -> (scheduled: Bool, authorized: Bool) {
        guard task(for: category)?.notificationsEnabled != false else { return (false, true) }
        let authorized = await notificationScheduler.requestAuthorization()
        guard authorized else { return (false, false) }
        let scheduled = await notificationScheduler.scheduleTestNotification(
            category: category,
            delaySeconds: afterSeconds
        )
        return (scheduled, true)
    }

    /// 期限到来＋通知済み状態にして「やった！」を試せるようにする
    func simulateDueToday(for category: GroomingCategory) {
        guard let index = tasks.firstIndex(where: { $0.category == category }) else { return }
        tasks[index].nextDueAt = Date()
        tasks[index].markNotified()
        persist()
        Task {
            _ = await fireTestNotification(for: category, afterSeconds: 5)
        }
    }

    /// 全画面共通の手動リロード
    func reloadAll() async {
        loadTasks()
        checkOverduePenalties()
        var changed = false
        for index in tasks.indices {
            guard tasks[index].notificationsEnabled else { continue }
            if tasks[index].isDueOrOverdue, !tasks[index].hasPendingNotification {
                alignDueForNotification(at: index)
                tasks[index].markNotified(at: max(tasks[index].nextDueAt, .now))
                changed = true
            }
        }
        if changed { persist() }
        syncDeliveredNotificationState()
        await rescheduleAllNotifications()
    }

    func checkOverduePenalties() {
        var changed = false
        for index in tasks.indices {
            if tasks[index].daysUntilDue < -2 {
                tasks[index].applyIgnoredPenalty()
                changed = true
            }
        }
        if changed {
            persist()
            Task { await rescheduleAllNotifications() }
        }
    }

    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([GroomingTask].self, from: data),
              !decoded.isEmpty
        else {
            tasks = []
            return
        }
        tasks = decoded.sorted {
            let order = GroomingCategory.allCases
            let i = order.firstIndex(of: $0.category) ?? 0
            let j = order.firstIndex(of: $1.category) ?? 0
            return i < j
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
