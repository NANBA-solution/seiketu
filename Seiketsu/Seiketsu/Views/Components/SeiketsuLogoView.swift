import SwiftUI

struct SeiketsuLogoView: View {
    enum Size {
        case large, compact

        var titleFont: Font {
            switch self {
            case .large:   return .system(size: 38, weight: .black, design: .rounded)
            case .compact: return .system(size: 20, weight: .black, design: .rounded)
            }
        }

        var subtitleFont: Font {
            switch self {
            case .large:   return .system(size: 11, weight: .semibold)
            case .compact: return .system(size: 9,  weight: .semibold)
            }
        }

        var logoSize: CGFloat { self == .large ? 56 : 32 }
        var spacing: CGFloat  { self == .large ? 8 : 2 }
        var tracking: CGFloat { self == .large ? 4 : 2.5 }
    }

    var size: Size = .large
    var showsMark: Bool = false

    var body: some View {
        VStack(spacing: size.spacing) {
            if showsMark {
                // 元のアセット（白背景除去済み）
                Image("AppLogoMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.logoSize, height: size.logoSize)
            }
            Text("セイケツ")
                .font(size.titleFont)
                .foregroundStyle(AppTheme.primary)
            Text("SEIKETSU")
                .font(size.subtitleFont)
                .foregroundStyle(AppTheme.secondary)
                .tracking(size.tracking)
        }
    }
}

// ダーク背景用のグラデーションロゴマーク（オンボーディングSTEP1専用）
struct LogoMarkView: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(AppTheme.accentGradient)
                .frame(width: size, height: size)
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 14, y: 5)
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

struct OnboardingIllustration: View {
    let name: String
    var height: CGFloat = 200

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .accessibilityHidden(true)
    }
}
