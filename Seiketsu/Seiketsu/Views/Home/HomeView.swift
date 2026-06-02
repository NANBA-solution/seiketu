import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GroomingStore
    @State private var showHistory = false
    @State private var toastCategory: GroomingCategory?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    statusHeader
                    taskListCard
                    historyButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 36)
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SeiketsuLogoView(size: .compact)
                }
            }
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
            .onAppear {
                store.checkOverduePenalties()
            }
        }
        .overlay(alignment: .bottom) {
            if let category = toastCategory {
                ToastBanner(category: category)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: toastCategory?.rawValue)
    }

    private func markDone(_ category: GroomingCategory) {
        store.markDone(category: category)
        toastCategory = category
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            toastCategory = nil
        }
    }

    // MARK: - Status Header (light card + avatar)

    private var statusHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(store.headerTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(store.headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer(minLength: 8)
            Image("AvatarHappy")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .accessibilityLabel("ステータスキャラクター")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.surface)
                .shadow(color: .black.opacity(0.06), radius: 14, y: 3)
        )
    }

    // MARK: - Task List

    private var taskListCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(store.tasks.enumerated()), id: \.element.id) { index, task in
                GroomingRowView(task: task) {
                    markDone(task.category)
                }
                if index < store.tasks.count - 1 {
                    Divider()
                        .padding(.leading, 66)
                        .overlay(AppTheme.separator)
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 3)
    }

    // MARK: - History Button (full-width dark navy)

    private var historyButton: some View {
        Button {
            showHistory = true
        } label: {
            HStack {
                Text("身だしなみ記録を見る")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.top, 4)
    }
}

// MARK: - Toast

private struct ToastBanner: View {
    let category: GroomingCategory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.done)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(category.title)のケアを記録しました")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                Text("次回のタイミングを自動調整中")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
        )
    }
}
