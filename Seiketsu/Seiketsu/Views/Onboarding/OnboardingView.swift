import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var store: GroomingStore
    @State private var page = 0
    @State private var permissionDenied = false

    private let totalPages = 6
    private var isIntroPage: Bool { page == 0 }

    var body: some View {
        ZStack {
            // STEP1 のみダーク背景、他はライト
            Group {
                if isIntroPage {
                    AppTheme.headerGradient
                } else {
                    AppTheme.background
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.35), value: isIntroPage)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    introPage.tag(0)
                    concernPage.tag(1)
                    notifyOnlyPage.tag(2)
                    requestPermissionPage.tag(3)
                    setupDonePage.tag(4)
                    motivationPage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: page)

                adaptivePageIndicator
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
            }
        }
        .alert("通知がオフです", isPresented: $permissionDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("あとで", role: .cancel) { finishOnboarding() }
        } message: {
            Text("通知を許可すると、最適なタイミングでリマインドを受け取れます。")
        }
    }

    // MARK: - Adaptive Page Indicator

    private var adaptivePageIndicator: some View {
        HStack(spacing: 5) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(indicatorColor(for: index))
                    .frame(width: index == page ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page)
            }
        }
    }

    private func indicatorColor(for index: Int) -> Color {
        let isActive = index == page
        if isIntroPage {
            return isActive ? .white : .white.opacity(0.3)
        } else {
            return isActive ? AppTheme.accent : AppTheme.separator
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        switch page {
        case 0, 1:
            PrimaryButton(title: "次へ") { page += 1 }
        case 2, 3:
            PrimaryButton(title: "通知を許可する") { requestNotificationsAndAdvance() }
        case 4:
            PrimaryButton(title: "はじめる") { page += 1 }
        case 5:
            PrimaryButton(title: "スタート！") { finishOnboarding() }
        default:
            EmptyView()
        }
    }

    // MARK: - STEP 1: Intro（ダーク背景 + 白テキスト）

    private var introPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // ロゴ（ダーク背景向けグラデーションマーク + 白テキスト）
                VStack(spacing: 8) {
                    LogoMarkView(size: 64)
                    Text("セイケツ")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("SEIKETSU")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                        .tracking(4.5)
                }
                .padding(.top, 36)

                VStack(spacing: 10) {
                    Text("ほっとくと、\nおっさんになる。")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Text("だらしない男のための\n全自動・身だしなみアラートアプリ")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                // ダーク背景対応のSwiftUIイラスト（カテゴリーアイコン軌道）
                IntroIllustration()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    // MARK: - STEP 2: Concern

    private var concernPage: some View {
        OnboardingPage(title: "気づいたら伸びてた…\nなんてこと、ありませんか？",
                       subtitle: "見落としやすい6項目を自動で見守ります") {
            LazyVGrid(
                columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())],
                spacing: 20
            ) {
                ForEach(GroomingCategory.allCases) { category in
                    VStack(spacing: 10) {
                        GroomingIconView(category: category, size: 26)
                        Text(category.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - STEP 3: Notify（元のPNG）

    private var notifyOnlyPage: some View {
        OnboardingPage(title: "やることは\n通知を許可するだけ。", subtitle: nil) {
            OnboardingIllustration(name: "OnboardingNotification", height: 220)
            VStack(alignment: .leading, spacing: 14) {
                checklistRow("最適なタイミングで通知")
                checklistRow("設定や入力は一切不要")
                checklistRow("すべて自動でスタート")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - STEP 4: Permission Dialog

    private var requestPermissionPage: some View {
        OnboardingPage(title: "通知の許可",
                       subtitle: "標準のiOSダイアログで安心して許可できます") {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("「セイケツ」は通知を送信します。")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                    Text("よろしいですか？")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                }
                .padding(.vertical, 18)
                Divider()
                HStack(spacing: 0) {
                    Button("許可しない") { permissionDenied = true }
                        .font(.body)
                        .foregroundStyle(AppTheme.secondary)
                        .frame(maxWidth: .infinity)
                    Divider().frame(height: 44)
                    Button("許可") { requestNotificationsAndAdvance() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 44)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: 12, y: 4)
            .padding(.top, 10)
        }
    }

    // MARK: - STEP 5: Setup Done

    private var setupDonePage: some View {
        OnboardingPage(title: "完了！\nすべて自動でセットされました", subtitle: nil) {
            VStack(spacing: 0) {
                ForEach(Array(GroomingCategory.allCases.enumerated()), id: \.element.id) { index, category in
                    let task = store.task(for: category) ?? GroomingTask(category: category)
                    HStack(spacing: 12) {
                        GroomingIconView(category: category, size: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                            Text(task.statusMessage)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondary)
                        }
                        Spacer()
                        Text(category.presetLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    if index < GroomingCategory.allCases.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: 12, y: 4)
            .onAppear {
                if store.tasks.isEmpty { store.initializeDefaults() }
            }
        }
    }

    // MARK: - STEP 6: Motivation（元のPNG）

    private var motivationPage: some View {
        OnboardingPage(title: "さあ、清潔感のある\n自分へ。",
                       subtitle: "セイケツがあなたの身だしなみを見守ります") {
            OnboardingIllustration(name: "OnboardingMotivation", height: 260)
            Text("一緒に自分をアップデートしよう！")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
        }
    }

    // MARK: - Helpers

    private func checklistRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primary)
        }
    }

    private func requestNotificationsAndAdvance() {
        Task {
            store.initializeDefaults()
            let granted = await NotificationScheduler().requestAuthorization()
            await MainActor.run {
                if granted {
                    Task { await store.rescheduleAllNotifications() }
                    page = 4
                } else {
                    permissionDenied = true
                }
            }
        }
    }

    private func finishOnboarding() {
        if store.tasks.isEmpty { store.initializeDefaults() }
        store.completeOnboarding()
    }
}

// MARK: - STEP 1 イラスト（ダーク背景専用）

private struct IntroIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 230, height: 230)

            ForEach(Array(GroomingCategory.allCases.enumerated()), id: \.element.id) { index, category in
                let angle = Double(index) / Double(GroomingCategory.allCases.count) * 360.0 - 90.0
                let radius: CGFloat = 92
                // ダーク背景なので白ベースの円にする
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(category.assetIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .colorInvert()
                        .opacity(0.9)
                }
                .offset(
                    x: cos(angle * .pi / 180) * radius,
                    y: sin(angle * .pi / 180) * radius
                )
            }

            LogoMarkView(size: 68)
        }
        .frame(width: 230, height: 230)
    }
}

// MARK: - Page Layout

private struct OnboardingPage<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 32)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .multilineTextAlignment(.center)
                }
                content
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}
