import SwiftUI
import UIKit

/// オンボーディング／デザインガイド準拠の共通テーマ
enum AppTheme {
    static let primary   = Color(red: 11 / 255, green: 29 / 255, blue: 58 / 255)   // #0B1D3A
    static let accent    = Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255)  // #1E3A8A
    static let secondary = Color(red: 100 / 255, green: 116 / 255, blue: 139 / 255) // #64748B
    static let separator = Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255) // #E5E7EB

    static let done    = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255)   // #22C55E
    static let warning = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)  // #F59E0B
    static let danger  = Color(red: 244 / 255, green: 114 / 255, blue: 114 / 255) // #F47272

    static let lightBlue = Color(red: 232 / 255, green: 240 / 255, blue: 254 / 255) // #E8F0FE
    static let background = Color.white
    static let surface = Color.white
    static let cardBorder = separator.opacity(0.85)
    static let cardShadow = Color(red: 11 / 255, green: 29 / 255, blue: 58 / 255).opacity(0.06)

    // Legacy aliases
    static var navy: Color { primary }
    static var navyLight: Color { accent }
    static var cardBackground: Color { surface }
    static var secondaryText: Color { secondary }
    static var divider: Color { separator }
    static var accentBlue: Color { accent }
    static var doneGreen: Color { done }
    static var iconCircleFill: Color { lightBlue }
    static var iconCircleStroke: Color { accent.opacity(0.25) }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 互換用（新UIでは未使用）
    static var headerGradient: LinearGradient {
        LinearGradient(colors: [primary, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - ホバー / プレス（Webの :hover / :active 相当）

struct ModernPressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        ModernPressable(configuration: configuration, scale: scale) {
            configuration.label
        }
    }
}

private struct ModernPressable<Label: View>: View {
    let configuration: ButtonStyleConfiguration
    let scale: CGFloat
    @ViewBuilder let label: () -> Label

    @State private var isHovered = false

    private var isActive: Bool { configuration.isPressed || isHovered }

    var body: some View {
        label()
            .scaleEffect(isActive ? scale : 1)
            .brightness(isActive ? -0.02 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isActive)
            .onHover { isHovered = $0 }
    }
}

struct ModernCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var elevated: Bool = true

    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.surface)
                    .shadow(
                        color: AppTheme.cardShadow.opacity(elevated && isHovered ? 1.4 : 1),
                        radius: isHovered ? 16 : 8,
                        y: isHovered ? 8 : 3
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isHovered ? AppTheme.accent.opacity(0.35) : AppTheme.cardBorder,
                        lineWidth: 1
                    )
            }
            .scaleEffect(isHovered ? 1.008 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

// MARK: - 設定ガイド

struct SettingsAutoGuideBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.lightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("基本は自動設定")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                    Text("いまのところ変更は不要です")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                guideRow(
                    icon: "arrow.triangle.2.circlepath",
                    text: "ケアの記録に合わせて、次回日・周期は自動で最適化されます"
                )
                guideRow(
                    icon: "slider.horizontal.3",
                    text: "日付や通知だけ変えたいときは、下のカードから手動で上書きできます"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.lightBlue, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.15), lineWidth: 1)
        }
    }

    private func guideRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 18, alignment: .center)
            Text(text)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 通知オン / オフ

struct NotificationModeControl: View {
    let isEnabled: Bool
    let onSelect: (Bool) -> Void

    @Namespace private var segmentNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("通知")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                Text(isEnabled ? "期限日に通知" : "通知なし · ✓で記録")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.secondary)
            }

            HStack(spacing: 0) {
                segment(
                    title: "ON",
                    icon: "bell.badge.fill",
                    enabled: true,
                    isSelected: isEnabled
                )
                segment(
                    title: "OFF",
                    icon: "bell.slash.fill",
                    enabled: false,
                    isSelected: !isEnabled
                )
            }
            .padding(4)
            .background(AppTheme.separator.opacity(0.45))
            .clipShape(Capsule())
        }
    }

    private func segment(
        title: String,
        icon: String,
        enabled: Bool,
        isSelected: Bool
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                onSelect(enabled)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(0.8)
            }
            .foregroundStyle(isSelected ? Color.white : AppTheme.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background {
                if isSelected {
                    Capsule()
                        .fill(
                            enabled
                                ? LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        AppTheme.secondary.opacity(0.85),
                                        AppTheme.primary.opacity(0.75),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .matchedGeometryEffect(id: "notifySegment", in: segmentNamespace)
                        .shadow(color: AppTheme.primary.opacity(0.22), radius: 6, y: 3)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(ModernPressButtonStyle(scale: 0.97))
        .accessibilityLabel(enabled ? "通知オン" : "通知オフ")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 設定のカテゴリー行

struct CategorySettingsRow: View {
    let task: GroomingTask
    @Binding var draftDate: Date
    let notificationsEnabled: Bool
    let onNotificationChange: (Bool) -> Void

    @State private var isHovered = false

    private var hasDateDraftChange: Bool {
        let saved = Calendar.current.startOfDay(for: task.nextDueAt)
        let draft = Calendar.current.startOfDay(for: draftDate)
        return saved != draft
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                GroomingIconView(category: task.category, size: 22, showsCircleBackground: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.category.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                    Text("自動: \(task.category.presetLabel)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer(minLength: 8)
                if hasDateDraftChange {
                    Text("未反映")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.warning.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("次回ケア日")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                    Text("手動で変更")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppTheme.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
                HStack {
                    DatePicker(
                        "",
                        selection: $draftDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(AppTheme.primary)
                    Spacer(minLength: 0)
                }
            }

            NotificationModeControl(
                isEnabled: notificationsEnabled,
                onSelect: onNotificationChange
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHovered ? AppTheme.lightBlue.opacity(0.35) : Color.white)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isHovered ? AppTheme.accent.opacity(0.3) : AppTheme.cardBorder,
                    lineWidth: 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.2), value: isHovered)
    }
}

// MARK: - カード・画面

extension View {
    func modernCard(padding: CGFloat = 16, elevated: Bool = true) -> some View {
        modifier(ModernCardModifier(padding: padding, elevated: elevated))
    }

    func appCard(padding: CGFloat = 16) -> some View {
        modernCard(padding: padding)
    }

    func appScreen() -> some View {
        background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - ボタン（オンボーディングと同一）

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ModernPrimaryButton(configuration: configuration)
    }
}

private struct ModernPrimaryButton: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovered = false

    private var isActive: Bool { configuration.isPressed || isHovered }

    var body: some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.primary)
                    .shadow(
                        color: AppTheme.primary.opacity(isActive ? 0.35 : 0.2),
                        radius: isActive ? 14 : 8,
                        y: isActive ? 6 : 3
                    )
            )
            .scaleEffect(isActive ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isActive)
            .onHover { isHovered = $0 }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ModernSecondaryButton(configuration: configuration)
    }
}

private struct ModernSecondaryButton: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovered = false

    private var isActive: Bool { configuration.isPressed || isHovered }

    var body: some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? AppTheme.lightBlue : AppTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isActive ? AppTheme.accent.opacity(0.45) : AppTheme.cardBorder,
                                lineWidth: 1
                            )
                    }
            )
            .scaleEffect(isActive ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isActive)
            .onHover { isHovered = $0 }
    }
}

enum AppTabBarAppearance {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor(AppTheme.cardBorder)

        let titleFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor(AppTheme.secondary)
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor(AppTheme.primary)
        ]

        [appearance.stackedLayoutAppearance,
         appearance.inlineLayoutAppearance,
         appearance.compactInlineLayoutAppearance].forEach { item in
            item.normal.titleTextAttributes = normalAttrs
            item.selected.titleTextAttributes = selectedAttrs
            item.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
            item.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(AppTheme.primary)
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppTheme.secondary)
        UITabBar.appearance().itemPositioning = .centered
    }
}

// MARK: - 審査・法務（設定画面）

enum AppLegalDocument: String, Identifiable, CaseIterable {
    case privacy
    case terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: return "プライバシーポリシー"
        case .terms: return "利用規約"
        }
    }

    var bodyText: String {
        switch self {
        case .privacy: return Self.privacyPolicyText
        case .terms: return Self.termsOfUseText
        }
    }

    private static let privacyPolicyText = """
最終更新日: 2026年6月3日

セイケツ（以下「本アプリ」）は、身だしなみケアのリマインドと記録を端末内だけで行うアプリです。

1. 収集する情報
本アプリは、氏名・メールアドレス・アカウント情報を収集しません。ケアの記録、次回予定日、通知設定はお使いの端末内（UserDefaults）にのみ保存されます。

2. 第三者への提供
本アプリは、取得したデータを第三者に販売・共有しません。広告配信や行動トラッキングは行いません。

3. 通知
リマインドのため、お使いの端末の通知機能を利用します。通知の許可はiOSの設定または本アプリ内の案内からいつでも変更できます。

4. データの削除
設定画面の「データをすべて削除」から、端末内の記録と設定を消去できます。アプリを削除しても端末内のデータはiOSの仕様に従って削除されます。

5. お問い合わせ
ご不明点は下記までご連絡ください。
メール: nanbacoltd.95@gmail.com
"""

    private static let termsOfUseText = """
最終更新日: 2026年6月3日

本利用規約は、セイケツ（以下「本アプリ」）の利用条件を定めるものです。

1. 本アプリの内容
本アプリは、身だしなみケアのタイミングを支援するリマインダーです。医療・美容の診断や治療を提供するものではありません。

2. 利用上の注意
通知時刻や周期は目安です。体調や生活に合わせてご自身の判断でケアしてください。

3. 免責
本アプリの利用により生じた損害について、開発者は法令で認められる範囲を超えて責任を負いません。

4. 変更
本規約は必要に応じて改定されることがあります。重要な変更はアプリ内でお知らせします。

5. お問い合わせ
nanbacoltd.95@gmail.com
"""
}

struct LegalDocumentView: View {
    let document: AppLegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(document.bodyText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .appScreen()
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}

struct SettingsComplianceSection: View {
    @EnvironmentObject private var store: GroomingStore
    @State private var presentedDocument: AppLegalDocument?
    @State private var showResetConfirm = false
    @State private var resetDoneMessage = ""

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アプリ情報")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primary)

            complianceRow(title: "バージョン", value: appVersion, showsChevron: false)

            ForEach(AppLegalDocument.allCases) { doc in
                Button {
                    presentedDocument = doc
                } label: {
                    complianceRow(title: doc.title, value: nil, showsChevron: true)
                }
                .buttonStyle(ModernPressButtonStyle(scale: 0.99))
            }

            Link(destination: URL(string: "mailto:nanbacoltd.95@gmail.com")!) {
                complianceRow(title: "お問い合わせ", value: "nanbacoltd.95@gmail.com", showsChevron: true)
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Text("データをすべて削除")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(SecondaryButtonStyle())

            if !resetDoneMessage.isEmpty {
                Text(resetDoneMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
        }
        .modernCard(padding: 16)
        .sheet(item: $presentedDocument) { doc in
            LegalDocumentView(document: doc)
        }
        .confirmationDialog(
            "端末内の記録と設定をすべて削除します。元に戻せません。",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                store.resetAllUserData()
                resetDoneMessage = "データを削除しました。オンボーディングから再開します。"
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func complianceRow(title: String, value: String?, showsChevron: Bool) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.primary)
            Spacer()
            if let value {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondary.opacity(0.8))
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.6)
        }
    }
}
