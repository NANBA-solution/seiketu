import SwiftUI
import UIKit

struct GroomingRowView: View {
    let task: GroomingTask
    let onDone: () -> Void

    private var progressValue: Double {
        let total = task.averageIntervalDays
        let elapsed = total - Double(task.daysUntilDue)
        return min(max(elapsed / total, 0), 1.0)
    }

    private var urgencyColor: Color {
        if task.daysUntilDue < 0  { return AppTheme.danger }
        if task.daysUntilDue <= 2 { return AppTheme.warning }
        return AppTheme.secondary
    }

    private var progressColor: Color {
        progressValue >= 1 ? AppTheme.danger : task.category.themeColor
    }

    var body: some View {
        HStack(spacing: 14) {
            GroomingIconView(category: task.category, size: 22)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(task.category.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                    Spacer()
                    Text(task.daysLeftLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(urgencyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(urgencyColor.opacity(0.1))
                        .clipShape(Capsule())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.separator)
                            .frame(height: 4)
                        Capsule()
                            .fill(progressColor)
                            .frame(width: max(geo.size.width * progressValue, 0), height: 4)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressValue)
                    }
                }
                .frame(height: 4)
            }

            DoneButton(isDueOrOverdue: task.isDueOrOverdue, onDone: onDone)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct DoneButton: View {
    let isDueOrOverdue: Bool
    let onDone: () -> Void

    var iconName: String {
        isDueOrOverdue ? "checkmark.circle.fill" : "checkmark.circle"
    }

    var tint: Color {
        isDueOrOverdue ? AppTheme.done : AppTheme.secondary.opacity(0.3)
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onDone()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(tint)
                Text("やった！")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
        .buttonStyle(SpringButtonStyle())
    }
}

private struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.22 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
