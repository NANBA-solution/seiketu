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
        if let raw = notification.request.content.userInfo["category"] as? String,
           let category = GroomingCategory(rawValue: raw) {
            await MainActor.run {
                store?.markNotified(category: category)
            }
        }
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let raw = response.notification.request.content.userInfo["category"] as? String,
              let category = GroomingCategory(rawValue: raw)
        else { return }
        await MainActor.run {
            store?.handleNotificationInteraction(
                category: category,
                actionIdentifier: response.actionIdentifier
            )
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
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(AppTheme.primary)
        .onAppear {
            AppTabBarAppearance.apply()
            store.refreshAutoScheduleOnLaunch()
        }
    }
}

private enum AppTab: Hashable {
    case home
    case calendar
    case settings
}

private struct MainTabView: View {
    @State private var tab: AppTab = .home

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tag(AppTab.home)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            CalendarCheckView()
                .tag(AppTab.calendar)
                .tabItem {
                    Label("予定", systemImage: "calendar")
                }

            ScheduleSettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .tint(AppTheme.primary)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.white, for: .tabBar)
    }
}

private struct CalendarSheetDay: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}

private struct CalendarCheckView: View {
    @EnvironmentObject private var store: GroomingStore
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var monthCursor = Calendar.current.startOfDay(for: .now)
    @State private var sheetDay: CalendarSheetDay?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    private struct DayCell: Identifiable {
        let id = UUID()
        let date: Date?
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: monthCursor)
    }

    private var monthDays: [DayCell] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthCursor) else { return [] }
        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1=日
        let lead = firstWeekday - 1

        let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30
        var result: [DayCell] = Array(repeating: DayCell(date: nil), count: lead)
        for offset in 0..<dayCount {
            if let date = calendar.date(byAdding: .day, value: offset, to: firstDay) {
                result.append(DayCell(date: calendar.startOfDay(for: date)))
            }
        }
        while result.count % 7 != 0 {
            result.append(DayCell(date: nil))
        }
        return result
    }

    private var tasksCountByDay: [Date: Int] {
        Dictionary(grouping: store.tasks) { Calendar.current.startOfDay(for: $0.nextDueAt) }
            .mapValues { $0.count }
    }

    private var selectedDayTasks: [GroomingTask] {
        store.tasks(on: selectedDate)
    }

    private var groupedSchedule: [(date: Date, tasks: [GroomingTask])] {
        let grouped = Dictionary(grouping: store.tasks) { task in
            Calendar.current.startOfDay(for: task.nextDueAt)
        }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.category.title < $1.category.title }) }
            .sorted { $0.0 < $1.0 }
    }

    private func selectDay(_ date: Date, showSheet: Bool) {
        selectedDate = date
        if showSheet, !store.tasks(on: date).isEmpty {
            sheetDay = CalendarSheetDay(date: date)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("予定を日付ごとに確認")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.secondary)
                        Spacer()
                        Button("今日") {
                            selectedDate = Calendar.current.startOfDay(for: .now)
                            monthCursor = selectedDate
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                    }

                    VStack(spacing: 10) {
                        HStack {
                            Button {
                                if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: monthCursor) {
                                    monthCursor = previousMonth
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.lightBlue)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ModernPressButtonStyle())
                            Spacer()
                            Text(monthTitle)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.primary)
                            Spacer()
                            Button {
                                if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: monthCursor) {
                                    monthCursor = nextMonth
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.lightBlue)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ModernPressButtonStyle())
                        }

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(weekdaySymbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 20)
                            }

                            ForEach(monthDays) { day in
                                if let date = day.date {
                                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                    let isToday = Calendar.current.isDateInToday(date)
                                    let count = tasksCountByDay[date] ?? 0
                                    let hasTasks = count > 0
                                    Button {
                                        selectDay(date, showSheet: hasTasks)
                                        withAnimation {
                                            proxy.scrollTo("dayDetail", anchor: .top)
                                        }
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text("\(Calendar.current.component(.day, from: date))")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(isSelected ? Color.white : AppTheme.primary)
                                            if hasTasks {
                                                Circle()
                                                    .fill(isSelected ? Color.white : AppTheme.accent)
                                                    .frame(width: 5, height: 5)
                                            } else {
                                                Circle()
                                                    .fill(.clear)
                                                    .frame(width: 5, height: 5)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(
                                                    isSelected
                                                    ? AppTheme.primary
                                                    : (isToday ? AppTheme.lightBlue : Color.clear)
                                                )
                                        )
                                    }
                                    .buttonStyle(ModernPressButtonStyle(scale: 0.94))
                                } else {
                                    Color.clear
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                }
                            }
                        }
                    }
                    .modernCard(padding: 12)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("選択日のケア項目")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                            Spacer()
                            if !selectedDayTasks.isEmpty {
                                Button("詳細") {
                                    sheetDay = CalendarSheetDay(date: selectedDate)
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .buttonStyle(ModernPressButtonStyle(scale: 0.96))
                            }
                        }

                        Text(selectedDate, format: .dateTime.year().month().day().weekday(.abbreviated))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondary)

                        if selectedDayTasks.isEmpty {
                            Text("この日に予定されているケアはありません")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondary)
                                .padding(.vertical, 6)
                        } else {
                            ForEach(selectedDayTasks) { task in
                                CalendarTaskDetailRow(task: task)
                                if task.id != selectedDayTasks.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .appCard(padding: 14)
                    .id("dayDetail")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("日付別スケジュール")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                        if groupedSchedule.isEmpty {
                            Text("スケジュールはまだありません")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondary)
                        } else {
                            ForEach(groupedSchedule, id: \.date) { group in
                                Button {
                                    monthCursor = Calendar.current.date(
                                        from: Calendar.current.dateComponents([.year, .month], from: group.date)
                                    ) ?? group.date
                                    selectDay(group.date, showSheet: true)
                                    withAnimation {
                                        proxy.scrollTo("dayDetail", anchor: .top)
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(group.date, format: .dateTime.month().day().weekday())
                                                .font(.subheadline.weight(.bold))
                                                .foregroundStyle(AppTheme.primary)
                                            Spacer()
                                            Text("\(group.tasks.count)件")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(AppTheme.secondary)
                                            Image(systemName: "chevron.right")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(AppTheme.secondary)
                                        }
                                        ForEach(group.tasks) { task in
                                            HStack(spacing: 8) {
                                                GroomingIconView(category: task.category, size: 16)
                                                Text(task.category.title)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(AppTheme.primary)
                                                Spacer()
                                                Text(task.daysLeftLabel)
                                                    .font(.caption2.weight(.medium))
                                                    .foregroundStyle(AppTheme.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .appCard(padding: 14)

                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            }
            .appScreen()
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .sectionReloadable {
                await store.reloadAll()
            }
            .sheet(item: $sheetDay) { day in
                CalendarDayDetailSheet(date: day.date)
            }
            .onAppear {
                monthCursor = Calendar.current.date(
                    from: Calendar.current.dateComponents([.year, .month], from: selectedDate)
                ) ?? selectedDate
            }
        }
    }
}

private struct CalendarTaskDetailRow: View {
    @EnvironmentObject private var store: GroomingStore
    let task: GroomingTask

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GroomingIconView(category: task.category, size: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(task.category.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                    StatusBadge(daysUntilDue: task.daysUntilDue)
                }
                Text(task.statusMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                Text(store.nextDueDescription(for: task))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondary.opacity(0.9))
            }
            Spacer(minLength: 0)
            Text(task.daysLeftLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(task.isDueOrOverdue ? AppTheme.danger : AppTheme.primary)
        }
        .padding(.vertical, 4)
    }
}

private struct CalendarDayDetailSheet: View {
    @EnvironmentObject private var store: GroomingStore
    @Environment(\.dismiss) private var dismiss
    let date: Date

    private var tasks: [GroomingTask] { store.tasks(on: date) }

    private var dayTitle: String {
        date.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day()
                .weekday(.wide)
                .locale(Locale(identifier: "ja_JP"))
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tasks) { task in
                        CalendarTaskDetailRow(task: task)
                            .appCard(padding: 14)
                    }
                }
                .padding(16)
            }
            .appScreen()
            .navigationTitle(dayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct ScheduleSettingsView: View {
    @EnvironmentObject private var store: GroomingStore
    @State private var draftDates: [String: Date] = [:]
    @State private var message = ""
    @State private var testCategory: GroomingCategory = .noseHair
    @State private var isSendingTest = false

    private var orderedTasks: [GroomingTask] {
        store.tasks.sorted { lhs, rhs in
            let order = GroomingCategory.allCases
            return (order.firstIndex(of: lhs.category) ?? 0) < (order.firstIndex(of: rhs.category) ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    SettingsAutoGuideBanner()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("手動で調整する")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)

                        Text("カテゴリーごとに次回ケア日と通知の有無を変えられます。")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 12) {
                            ForEach(orderedTasks) { task in
                                CategorySettingsRow(
                                    task: task,
                                    draftDate: Binding(
                                        get: {
                                            draftDates[task.category.rawValue]
                                                ?? Calendar.current.startOfDay(for: task.nextDueAt)
                                        },
                                        set: { newValue in
                                            draftDates[task.category.rawValue] = Calendar.current.startOfDay(
                                                for: newValue
                                            )
                                        }
                                    ),
                                    notificationsEnabled: store.task(for: task.category)?.notificationsEnabled ?? true,
                                    onNotificationChange: { enabled in
                                        store.setNotificationsEnabled(enabled, for: task.category)
                                    }
                                )
                            }
                        }
                    }
                    .modernCard(padding: 16)

                    Button {
                        for task in orderedTasks {
                            if let date = draftDates[task.category.rawValue] {
                                store.updateNextDueDate(for: task.category, to: date)
                            }
                        }
                        message = "手動設定を反映しました"
                    } label: {
                        Text("手動変更を反映する")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    #if DEBUG
                    notificationTestSection
                    #endif

                    SettingsComplianceSection()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .appScreen()
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .sectionReloadable {
                await store.reloadAll()
                await MainActor.run {
                    syncDraftDatesFromStore()
                }
            }
        }
        .onAppear {
            syncDraftDatesFromStore()
        }
    }

    private func syncDraftDatesFromStore() {
        draftDates = Dictionary(uniqueKeysWithValues: store.tasks.map {
            ($0.category.rawValue, Calendar.current.startOfDay(for: $0.nextDueAt))
        })
    }

    private var notificationTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知テスト")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primary)

            Text("5秒後に通知します。届かないときは通知を許可しているか、一度ホームに戻ってアプリをバックグラウンドにしてください。")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("項目", selection: $testCategory) {
                ForEach(GroomingCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.primary)

            Button {
                isSendingTest = true
                Task {
                    let result = await store.fireTestNotification(for: testCategory, afterSeconds: 5)
                    await MainActor.run {
                        isSendingTest = false
                        if !result.authorized {
                            message = "通知が許可されていません。iOSの設定で許可してください。"
                        } else if !result.scheduled,
                                  store.task(for: testCategory)?.notificationsEnabled == false {
                            message = "「\(testCategory.title)」は通知しない設定です"
                        } else if result.scheduled {
                            message = "5秒後に「\(testCategory.title)」のテスト通知を送ります"
                        } else {
                            message = "テスト通知の登録に失敗しました"
                        }
                    }
                }
            } label: {
                HStack {
                    if isSendingTest {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSendingTest ? "登録中…" : "5秒後にテスト通知")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSendingTest)

            Button {
                store.simulateDueToday(for: testCategory)
                message = "「\(testCategory.title)」を期限到来にしました。5秒後に通知し、ホームで「やった！」を試せます"
            } label: {
                Text("期限到来をシミュレート（やった！テスト）")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .modernCard(padding: 14)
    }
}
