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

// MARK: - カード・画面

struct AppCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            }
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(AppCardModifier(padding: padding))
    }

    func appScreen() -> some View {
        background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - ボタン（オンボーディングと同一）

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.primary)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    }
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
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
