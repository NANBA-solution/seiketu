import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var store: GroomingStore
    @State private var page = 0
    @State private var permissionDenied = false

    /// 仕様: 4ドット（STEP1〜3, STEP5。STEP4はSTEP3上のダイアログ）
    private var activeDotIndex: Int {
        switch page {
        case 0: return 0
        case 1: return 1
        case 2, 3: return 2
        case 4: return 3
        default: return 3
        }
    }

    private var dotsFilledThroughEnd: Bool { page == 5 }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

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
                .animation(.easeInOut(duration: 0.28), value: page)

                OnboardingPageDots(
                    activeIndex: activeDotIndex,
                    filledThroughEnd: dotsFilledThroughEnd
                )
                .padding(.top, 12)
                .padding(.bottom, 12)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
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

    // MARK: - Footer Button

    @ViewBuilder
    private var actionButton: some View {
        switch page {
        case 0, 1:
            OnboardingPrimaryButton(title: "次へ") { page += 1 }
        case 2:
            OnboardingPrimaryButton(title: "通知を許可する") { page += 1 }
        case 3:
            Color.clear.frame(height: 52)
        case 4:
            OnboardingPrimaryButton(title: "はじめる") { page += 1 }
        case 5:
            OnboardingPrimaryButton(title: "スタート！") { finishOnboarding() }
        default:
            EmptyView()
        }
    }

    // MARK: - STEP 1（白背景・キャッチ→ロゴ→タグライン→円形イラスト）

    private var introPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("ほっとくと、\nおっさんになる。")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 36)

                SeiketsuLogoView(size: .large)

                Text("だらしない男のための\n全自動・身だしなみアラートアプリ")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Image("OnboardingIntro")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color(red: 232 / 255, green: 240 / 255, blue: 254 / 255), lineWidth: 3)
                    }
                    .padding(.top, 8)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
    }

    // MARK: - STEP 2（6アイコングリッド）

    private var concernPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Text("気づいたら伸びてた…\nなんてこと、ありませんか？")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 32)

                LazyVGrid(
                    columns: [.init(.flexible(), spacing: 12), .init(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(GroomingCategory.allCases) { category in
                        CategoryOnboardingIconCell(category: category)
                    }
                }

                Text("セイケツが、あなたの身だしなみを\n全自動でサポート！")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    // MARK: - STEP 3（通知許可・チェックリスト）

    private var notifyOnlyPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Text("やることは\n通知を許可するだけ。")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 32)

                Image("OnboardingNotification")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 200)

                VStack(alignment: .leading, spacing: 14) {
                    OnboardingCheckRow(text: "最適なタイミングでお知らせ")
                    OnboardingCheckRow(text: "設定や入力は一切不要")
                    OnboardingCheckRow(text: "すべて自動で始まります")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    // MARK: - STEP 4（STEP3を薄く表示＋iOSダイアログ）

    private var requestPermissionPage: some View {
        ZStack {
            notifyOnlyPage
                .blur(radius: 2)
                .overlay { Color.black.opacity(0.25).ignoresSafeArea() }
                .allowsHitTesting(false)

            iosPermissionDialog
                .padding(.horizontal, 40)
        }
    }

    private var iosPermissionDialog: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("「セイケツ」は通知を送信します。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
                Text("よろしいですか？")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)

            Divider()

            HStack(spacing: 0) {
                Button("許可しない") {
                    permissionDenied = true
                }
                .font(.body)
                .foregroundStyle(AppTheme.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)

                Divider().frame(width: 1, height: 44)

                Button("許可") {
                    requestNotificationsAndAdvance()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 24, y: 8)
    }

    // MARK: - STEP 5（自動セット完了）

    private var setupDonePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.done)
                    Text("完了！")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                    Text("すべて自動でセットされました")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)

                VStack(spacing: 0) {
                    ForEach(Array(GroomingCategory.allCases.enumerated()), id: \.element.id) { index, category in
                        HStack(spacing: 12) {
                            GroomingIconView(category: category, size: 22)
                            Text(category.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                            Spacer()
                            Text("あと\(GroomingStore.initialDueOffsetDays)日")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.secondary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)

                        if index < GroomingCategory.allCases.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.separator.opacity(0.6), lineWidth: 1)
                }

                Text("あなたの周期に合わせてアラートが届きます")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .onAppear {
                if store.tasks.isEmpty { store.initializeDefaults() }
            }
        }
    }

    // MARK: - STEP 6（モチベーション）

    private var motivationPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Text("さあ、清潔感のある\n自分へ。")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 36)

                Image("OnboardingMotivation")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 260)

                Text("セイケツが、あなたの身だしなみを見守ります。\n一緒に、自分をアップデートしていこう！")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Actions

    private func requestNotificationsAndAdvance() {
        Task {
            if store.tasks.isEmpty {
                store.initializeDefaults(anchorDate: store.effectiveStartDate)
            }
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
        if store.tasks.isEmpty {
            store.initializeDefaults(anchorDate: store.effectiveStartDate)
        }
        store.completeOnboarding()
    }
}

// MARK: - STEP2 セル（シンプル線画アイコン）

struct CategoryOnboardingIconCell: View {
    let category: GroomingCategory

    var body: some View {
        VStack(spacing: 10) {
            Image(category.assetIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            Text(category.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.separator.opacity(0.55), lineWidth: 1)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(GroomingStore())
}
