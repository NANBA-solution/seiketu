import Foundation
import UserNotifications

actor NotificationScheduler {
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func schedule(task: GroomingTask) async {
        let center = UNUserNotificationCenter.current()
        let identifier = "seiketsu.\(task.category.rawValue)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = task.category.notificationTitle
        content.body = task.category.notificationBody
        content.sound = .default
        content.categoryIdentifier = "GROOMING"
        content.userInfo = ["category": task.category.rawValue]

        let triggerDate = max(task.nextDueAt, Date().addingTimeInterval(3600))
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        await withCheckedContinuation { continuation in
            center.add(request) { _ in continuation.resume() }
        }
    }

    func scheduleAll(tasks: [GroomingTask]) async {
        for task in tasks {
            await schedule(task: task)
        }
    }
}
