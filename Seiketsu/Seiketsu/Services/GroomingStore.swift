import Foundation
import SwiftUI

@MainActor
final class GroomingStore: ObservableObject {
    @Published private(set) var tasks: [GroomingTask] = []
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    private let notificationScheduler: NotificationScheduler
    private static let storageKey = "seiketsu.tasks.v1"

    private enum Keys {
        static let onboarding = "seiketsu.onboarding.completed"
    }

    init(notificationScheduler: NotificationScheduler = NotificationScheduler()) {
        self.notificationScheduler = notificationScheduler
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.onboarding)
        loadTasks()
    }

    var headerTitle: String {
        let overdue = tasks.filter { $0.daysUntilDue < 0 }.count
        let dueToday = tasks.filter { $0.daysUntilDue == 0 }.count
        if overdue > 0 { return "ケアが必要な項目があります" }
        if dueToday > 0 { return "今日ケアしよう" }
        if tasks.contains(where: { $0.daysUntilDue <= 2 }) {
            return "そろそろケアの時期です"
        }
        return "すべて順調だよ 👍"
    }

    var headerSubtitle: String {
        let overdue = tasks.filter { $0.daysUntilDue < 0 }.count
        if overdue > 0 { return "清潔感をキープしよう" }
        return "清潔感キープ中！"
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

    func initializeDefaults() {
        tasks = GroomingCategory.allCases.map { GroomingTask(category: $0) }
        persist()
    }

    func completeOnboarding() {
        if tasks.isEmpty { initializeDefaults() }
        hasCompletedOnboarding = true
        Task { await rescheduleAllNotifications() }
    }

    func markDone(category: GroomingCategory) {
        guard let index = tasks.firstIndex(where: { $0.category == category }) else { return }
        tasks[index].markDone()
        persist()
        Task {
            await notificationScheduler.schedule(task: tasks[index])
        }
    }

    func rescheduleAllNotifications() async {
        _ = await notificationScheduler.requestAuthorization()
        for task in tasks {
            await notificationScheduler.schedule(task: task)
        }
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
