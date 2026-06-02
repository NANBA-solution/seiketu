import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: GroomingStore
    @Environment(\.dismiss) private var dismiss
    var showsCloseButton: Bool = true

    private var records: [GroomingRecord] { store.allRecords }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "まだ記録がありません",
                        systemImage: "chart.bar",
                        description: Text("「やった！」を押すと、ここにケアの記録が表示されます")
                    )
                    .foregroundStyle(AppTheme.secondary)
                } else {
                    List {
                        ForEach(dayGroups) { group in
                            Section(group.label) {
                                ForEach(group.records) { record in
                                    HStack(spacing: 14) {
                                        GroomingIconView(category: record.category, size: 28)
                                        Text(record.category.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.primary)
                                        Spacer()
                                        Text(record.completedAt, format: .dateTime.hour().minute())
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                    }
                                    .listRowBackground(Color.white)
                                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .appScreen()
            .navigationTitle("身だしなみ記録")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") { dismiss() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .sectionReloadable {
                await store.reloadAll()
            }
        }
    }

    private var dayGroups: [DayGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium

        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.completedAt)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map {
                DayGroup(
                    id: $0.key,
                    label: formatter.string(from: $0.key),
                    records: $0.value.sorted { $0.completedAt > $1.completedAt }
                )
            }
    }
}

private struct DayGroup: Identifiable {
    let id: Date
    let label: String
    let records: [GroomingRecord]
}
