import SwiftData
import SwiftUI

/// 公開用の架空ライフログを日付ごとに表示するタブ。
struct SampleDataTab: View {
    /// サンプルデータを読み込めなかった場合の説明。
    let seedError: String?

    @Query(sort: \LogEntry.createdAt) private var entries: [LogEntry]
    @State private var selectedEntry: LogEntry?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty, seedError == nil {
                    ContentUnavailableView(
                        "サンプルデータがありません",
                        systemImage: "list.bullet.rectangle",
                        description: Text("データの読み込みが完了するまでお待ちください。")
                    )
                } else {
                    entryList
                }
            }
            .navigationTitle(navigationTitle)
            .sheet(item: $selectedEntry, content: LogEntryDetailView.init)
        }
    }

    /// 読み込みエラーと日付ごとのライフログを表示する一覧。
    private var entryList: some View {
        List {
            if let seedError {
                Section {
                    Label(seedError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            ForEach(groupedEntries) { group in
                Section(group.title) {
                    ForEach(group.entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            LogEntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// 日付ごとにまとめたライフログ。
    private struct EntryDateGroup: Identifiable {
        let date: Date
        let entries: [LogEntry]

        var id: Date { date }

        var title: String {
            DateDisplay.sectionTitle(for: date)
        }
    }

    /// ライフログを日付ごとに時刻順でまとめた配列。
    ///
    /// - Complexity: O(*n* log *n*)。*n*はライフログの件数。
    private var groupedEntries: [EntryDateGroup] {
        Dictionary(grouping: entries) { entry in
            Calendar.japan.startOfDay(for: entry.createdAt)
        }
        .map { date, entries in
            EntryDateGroup(date: date, entries: entries.sorted { $0.createdAt < $1.createdAt })
        }
        .sorted { $0.date < $1.date }
    }

    /// データの対象月と件数を示す画面タイトル。
    private var navigationTitle: String {
        guard let firstDate = entries.first?.createdAt else {
            return "サンプルデータ"
        }

        return "\(DateDisplay.monthTitle(for: firstDate))・\(entries.count)件"
    }
}
