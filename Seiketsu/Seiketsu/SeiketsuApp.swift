import SwiftUI
import UserNotifications

@main
struct SeiketsuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = GroomingStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onAppear {
                    appDelegate.store = store
                    registerNotificationCategories()
                }
        }
    }

    private func registerNotificationCategories() {
        let done = UNNotificationAction(
            identifier: "MARK_DONE",
            title: "やった！",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "GROOMING",
            actions: [done],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var store: GroomingStore?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == "MARK_DONE"
            || response.actionIdentifier == UNNotificationDefaultActionIdentifier
        else { return }
        guard let raw = response.notification.request.content.userInfo["category"] as? String,
              let category = GroomingCategory(rawValue: raw)
        else { return }
        await MainActor.run {
            store?.markDone(category: category)
        }
    }
}

extension Notification.Name {
    static let groomingMarkedDone = Notification.Name("seiketsu.grooming.markedDone")
}

struct RootView: View {
    @EnvironmentObject private var store: GroomingStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .tint(AppTheme.navy)
    }
}
