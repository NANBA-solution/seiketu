import SwiftUI

enum OnboardingTheme {
    static let dotCount = 4
}

typealias OnboardingPrimaryButtonStyle = PrimaryButtonStyle

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        PrimaryButton(title: title, action: action)
    }
}

struct OnboardingPageDots: View {
    let activeIndex: Int
    var filledThroughEnd: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<OnboardingTheme.dotCount, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if filledThroughEnd || index == activeIndex { return AppTheme.primary }
        return AppTheme.separator
    }
}

struct OnboardingCheckRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.accent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
