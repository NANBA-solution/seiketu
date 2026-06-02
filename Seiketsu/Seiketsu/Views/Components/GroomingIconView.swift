import SwiftUI

// MARK: - Category Icon

struct GroomingIconView: View {
    let category: GroomingCategory
    var size: CGFloat = 28
    var showsCircleBackground: Bool = false

    var body: some View {
        if showsCircleBackground {
            ZStack {
                Circle()
                    .fill(AppTheme.lightBlue)
                    .overlay { Circle().stroke(AppTheme.iconCircleStroke, lineWidth: 1) }
                    .frame(width: size + 20, height: size + 20)
                iconImage
            }
        } else {
            iconImage
        }
    }

    private var iconImage: some View {
        Image(category.assetIconName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

// MARK: - Status Badge（デザインガイド: Done / Soon / Recommended / Delayed）

struct StatusBadge: View {
    let daysUntilDue: Int

    private var label: String? {
        if daysUntilDue < 0 { return "遅れ" }
        if daysUntilDue == 0 { return "今日" }
        if daysUntilDue <= 2 { return "まもなく" }
        return nil
    }

    private var color: Color {
        if daysUntilDue < 0 { return AppTheme.danger }
        if daysUntilDue == 0 { return AppTheme.warning }
        return AppTheme.accent
    }

    var body: some View {
        if let label {
            badgeContent(label)
        }
    }

    private func badgeContent(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct StatusSummaryPill: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        Text("\(label) \(count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { Text(title) }
            .buttonStyle(PrimaryButtonStyle())
    }
}

struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? AppTheme.primary : AppTheme.separator)
                    .frame(width: 7, height: 7)
            }
        }
    }
}
