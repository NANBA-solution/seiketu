import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: GroomingStore
    @Environment(\.dismiss) private var dismiss

    private var records: [GroomingRecord] { store.allRecords }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "まだ記録がありません",
                        systemImage: "sparkles",
                        description: Text("「やった！」を押すと、ここにケアの記録が表示されます")
                    )
                } else {
                    List {
                        ForEach(dayGroups) { group in
                            Section(group.label) {
                                ForEach(group.records) { record in
                                    HStack(spacing: 14) {
                                        GroomingIconView(category: record.category, size: 18)
                                        Text(record.category.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.primary)
                                        Spacer()
                                        Text(record.completedAt, format: .dateTime.hour().minute())
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                    }
                                    .listRowBackground(AppTheme.surface)
                                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("身だしなみ記録")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
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
            .map { DayGroup(id: $0.key, label: formatter.string(from: $0.key),
                            records: $0.value.sorted { $0.completedAt > $1.completedAt }) }
    }
}

private struct DayGroup: Identifiable {
    let id: Date
    let label: String
    let records: [GroomingRecord]
}
