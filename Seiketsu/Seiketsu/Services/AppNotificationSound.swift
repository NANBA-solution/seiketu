import Foundation
import UserNotifications

/// バンドル同梱のカスタム通知音（さわやかな3音スパークル）
enum AppNotificationSound {
    private static let fileName = "seiketsu_notify.caf"

    static var notificationSound: UNNotificationSound {
        UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
    }

    static func apply(to content: UNMutableNotificationContent) {
        content.sound = notificationSound
    }
}
