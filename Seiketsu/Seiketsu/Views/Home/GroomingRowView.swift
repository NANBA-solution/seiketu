import SwiftUI
import UIKit

struct GroomingRowView: View {
    let task: GroomingTask
    var onCardTap: (() -> Void)?
    let onDone: () -> Void

    @State private var isPressed = false

    private var progressValue: Double { task.cycleProgress }

    private var urgencyColor: Color {
        if task.daysUntilDue < 0 { return AppTheme.danger }
        if task.daysUntilDue <= 2 { return AppTheme.accent }
        return AppTheme.secondary
    }

    private var showsBadge: Bool {
        task.daysUntilDue <= 2 || task.daysUntilDue < 0
    }

    private var cardBorderColor: Color {
        if task.canComplete { return AppTheme.done.opacity(0.55) }
        if isPressed { return AppTheme.accent.opacity(0.6) }
        return AppTheme.cardBorder
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Group {
                if let onCardTap {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            isPressed = true
                        }
                        onCardTap()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isPressed = false
                            }
                        }
                    } label: {
                        cardMainContent
                    }
                    .buttonStyle(.plain)
                } else {
                    cardMainContent
                }
            }

            DoneButton(canComplete: task.canComplete, onDone: onDone)
                .frame(width: 44)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surface)
                .shadow(
                    color: AppTheme.cardShadow,
                    radius: isPressed ? 4 : 10,
                    y: isPressed ? 2 : 4
                )
        )
        .scaleEffect(isPressed ? 0.985 : 1)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: isPressed ? 2 : 1)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isPressed)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: task.canComplete)
    }

    private var cardMainContent: some View {
        HStack(alignment: .center, spacing: 12) {
            GroomingIconView(category: task.category, size: 30)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(task.category.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                        .lineLimit(1)
                        .layoutPriority(1)

                    if showsBadge {
                        StatusBadge(daysUntilDue: task.daysUntilDue)
                    }

                    Spacer(minLength: 4)

                    Text(task.daysLeftLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(urgencyColor)
                        .lineLimit(1)
                        .fixedSize()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.separator.opacity(0.7))
                        Capsule()
                            .fill(progressBarFill)
                            .frame(width: progressBarWidth(in: geo.size.width))
                    }
                }
                .frame(height: 4)

                if let cardHint {
                    Text(cardHint)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var cardHint: String? {
        if task.canComplete { return "タップまたは右の ✓ でケアを記録" }
        if !task.notificationsEnabled, task.isDueOrOverdue {
            return "通知オフ · 期限後は右の ✓ で記録"
        }
        if task.isDueOrOverdue {
            return "通知が届くと ✓ で記録できます"
        }
        if task.completionHistory.isEmpty {
            return "初回ケア前 · ゲージは記録後に表示"
        }
        return nil
    }

    private var progressBarFill: Color {
        if task.completionHistory.isEmpty { return AppTheme.separator.opacity(0.35) }
        if task.canComplete { return AppTheme.done }
        if task.daysUntilDue <= 2 { return AppTheme.accent }
        return AppTheme.primary
    }

    private func progressBarWidth(in totalWidth: CGFloat) -> CGFloat {
        guard progressValue > 0 else { return 0 }
        return max(totalWidth * progressValue, 4)
    }
}

private struct DoneButton: View {
    let canComplete: Bool
    let onDone: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onDone()
        } label: {
            Image(systemName: canComplete ? "checkmark.circle.fill" : "checkmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(canComplete ? AppTheme.done : AppTheme.separator)
                .accessibilityLabel("やった！")
        }
        .buttonStyle(ModernPressButtonStyle(scale: 0.92))
        .disabled(!canComplete)
    }
}
