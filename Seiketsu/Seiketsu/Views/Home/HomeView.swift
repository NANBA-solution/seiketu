import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GroomingStore
    @State private var toastCategory: GroomingCategory?

    private var summary: GroomingStore.StatusSummary { store.statusSummary }
    private var scorePercent: Int { store.groomingScorePercent }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroHeader
                    statusStrip
                    taskListSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .appScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SeiketsuLogoView(size: .compact)
                }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .sectionReloadable {
                await store.reloadAll()
            }
            .onAppear {
                store.checkOverduePenalties()
            }
        }
        .overlay(alignment: .bottom) {
            if let category = toastCategory {
                ToastBanner(category: category)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: toastCategory?.rawValue)
        .onReceive(NotificationCenter.default.publisher(for: .groomingMarkedDone)) { note in
            if let raw = note.userInfo?["category"] as? String,
               let category = GroomingCategory(rawValue: raw) {
                toastCategory = category
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    toastCategory = nil
                }
            }
        }
    }

    private func markDone(_ category: GroomingCategory) {
        store.markDone(category: category)
        toastCategory = category
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            toastCategory = nil
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                headerTitleRow
                Text(store.headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            scoreRing
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.lightBlue, Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private var headerTitleRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: headerIconName)
                .font(.title3)
                .foregroundStyle(headerIconColor)
            Text(store.headerTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headerIconName: String {
        if summary.overdue > 0 { return "exclamationmark.triangle.fill" }
        if !store.hasAnyCompletion { return "calendar.badge.clock" }
        if scorePercent >= 75 { return "checkmark.seal.fill" }
        if scorePercent >= 50 { return "face.smiling" }
        return "arrow.up.circle.fill"
    }

    private var headerIconColor: Color {
        if summary.overdue > 0 { return AppTheme.danger }
        if !store.hasAnyCompletion { return AppTheme.accent }
        if scorePercent >= 75 { return AppTheme.done }
        if scorePercent >= 50 { return AppTheme.accent }
        return AppTheme.warning
    }

    private var scoreRing: some View {
        let ratio = Double(scorePercent) / 100
        return ZStack {
            Circle()
                .stroke(AppTheme.lightBlue, lineWidth: 8)
                .frame(width: 76, height: 76)
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(scoreRingColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 76, height: 76)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(scorePercent)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)
                Text("%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.secondary)
            }
        }
    }

    private var scoreRingColor: Color {
        if scorePercent >= 75 { return AppTheme.done }
        if scorePercent >= 50 { return AppTheme.accent }
        if scorePercent >= 25 { return AppTheme.warning }
        return AppTheme.danger.opacity(0.85)
    }

    private var statusStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if summary.awaitingFirst > 0 {
                    StatusSummaryPill(
                        label: "初回待ち",
                        count: summary.awaitingFirst,
                        color: AppTheme.accent
                    )
                }
                if summary.onTrack > 0 {
                    StatusSummaryPill(label: "順調", count: summary.onTrack, color: AppTheme.done)
                }
                if summary.soon > 0 {
                    StatusSummaryPill(label: "まもなく", count: summary.soon, color: AppTheme.warning)
                }
                if summary.overdue > 0 {
                    StatusSummaryPill(label: "遅れ", count: summary.overdue, color: AppTheme.danger)
                }
            }
        }
    }

    // MARK: - List

    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ケアリスト")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            VStack(spacing: 10) {
                ForEach(store.tasks) { task in
                    GroomingRowView(
                        task: task,
                        onCardTap: task.canComplete ? { markDone(task.category) } : nil,
                        onDone: { markDone(task.category) }
                    )
                }
            }
        }
    }
}

private struct ToastBanner: View {
    let category: GroomingCategory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.done)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(category.title)のケアを記録しました")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .lineLimit(1)
                Text("次回のタイミングを自動調整中")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .appCard(padding: 14)
        .shadow(color: AppTheme.cardShadow, radius: 12, y: 4)
    }
}
