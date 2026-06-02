import Foundation
import UserNotifications

/// 通知は毎日 9:00 / 19:00 の2回。期限日・追い通知日とも同じ枠。
enum NotificationSchedulePolicy {
    static let morningHour = 9
    static let morningMinute = 0
    static let eveningHour = 19
    static let eveningMinute = 0
    static let calendar = Calendar.current

    /// 識別子掃除用の最大追い通知日数
    static let maxFollowUpDaysForCleanup = 7

    /// 期限日（0日目）と追い通知日（1…`followUpDays`）の 9:00 / 19:00 を時系列で返す（過去枠は除外）
    static func upcomingSlots(
        dueDay: Date,
        followUpDays: Int,
        now: Date = .now
    ) -> [(date: Date, followUpDayIndex: Int)] {
        let start = calendar.startOfDay(for: dueDay)
        var slots: [(Date, Int)] = []

        for dayOffset in 0...max(0, followUpDays) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            for time in [(morningHour, morningMinute), (eveningHour, eveningMinute)] {
                var comps = calendar.dateComponents([.year, .month, .day], from: day)
                comps.hour = time.0
                comps.minute = time.1
                comps.second = 0
                guard let fireDate = calendar.date(from: comps), fireDate > now else { continue }
                slots.append((fireDate, dayOffset))
            }
        }
        return slots
    }
}

actor NotificationScheduler {
    private func identifiers(for category: GroomingCategory, followUpDays: Int) -> [String] {
        var ids = [
            "seiketsu.\(category.rawValue).due.am",
            "seiketsu.\(category.rawValue).due.pm",
        ]
        for day in 1...followUpDays {
            ids.append("seiketsu.\(category.rawValue).followup.\(day).am")
            ids.append("seiketsu.\(category.rawValue).followup.\(day).pm")
        }
        return ids
    }

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
        let followUpDays = task.maxFollowUps
        let ids = identifiers(for: task.category, followUpDays: followUpDays)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)

        guard task.notificationsEnabled else { return }

        let slots = NotificationSchedulePolicy.upcomingSlots(
            dueDay: task.nextDueAt,
            followUpDays: followUpDays
        )

        func makeContent(title: String, body: String, followUpDayIndex: Int) -> UNMutableNotificationContent {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "GROOMING"
            content.userInfo = [
                "category": task.category.rawValue,
                "followUpStep": followUpDayIndex,
            ]
            return content
        }

        for slot in slots {
            let isFollowUp = slot.followUpDayIndex > 0
            let body = isFollowUp
                ? "まだ未完了です。\(task.category.notificationBody)"
                : task.category.notificationBody
            let identifier: String
            let isMorning = NotificationSchedulePolicy.calendar.component(
                .hour,
                from: slot.date
            ) == NotificationSchedulePolicy.morningHour
            if slot.followUpDayIndex == 0 {
                identifier = isMorning
                    ? "seiketsu.\(task.category.rawValue).due.am"
                    : "seiketsu.\(task.category.rawValue).due.pm"
            } else {
                identifier = isMorning
                    ? "seiketsu.\(task.category.rawValue).followup.\(slot.followUpDayIndex).am"
                    : "seiketsu.\(task.category.rawValue).followup.\(slot.followUpDayIndex).pm"
            }

            let components = NotificationSchedulePolicy.calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: slot.date
            )
            let request = UNNotificationRequest(
                identifier: identifier,
                content: makeContent(
                    title: task.category.notificationTitle,
                    body: body,
                    followUpDayIndex: slot.followUpDayIndex
                ),
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            await withCheckedContinuation { continuation in
                center.add(request) { _ in continuation.resume() }
            }
        }
    }

    func scheduleAll(tasks: [GroomingTask]) async {
        for task in tasks {
            await schedule(task: task)
        }
    }

    func deliveredPendingCategories() async -> Set<GroomingCategory> {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                let categories = notifications.compactMap { notification -> GroomingCategory? in
                    guard let raw = notification.request.content.userInfo["category"] as? String else { return nil }
                    return GroomingCategory(rawValue: raw)
                }
                continuation.resume(returning: Set(categories))
            }
        }
    }

    func clearDelivered(category: GroomingCategory) async {
        let ids = identifiers(for: category, followUpDays: NotificationSchedulePolicy.maxFollowUpDaysForCleanup)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// テスト用: 数秒後に1通だけ通知（本番スケジュールは消さない）
    @discardableResult
    func scheduleTestNotification(
        category: GroomingCategory,
        delaySeconds: TimeInterval = 5
    ) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "[テスト] \(category.notificationTitle)"
        content.body = category.notificationBody
        content.sound = .default
        content.categoryIdentifier = "GROOMING"
        content.userInfo = ["category": category.rawValue, "followUpStep": 0, "isTest": true]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, delaySeconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "seiketsu.\(category.rawValue).test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        return await withCheckedContinuation { continuation in
            center.add(request) { error in
                continuation.resume(returning: error == nil)
            }
        }
    }
}
