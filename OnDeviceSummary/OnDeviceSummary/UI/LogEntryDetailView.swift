import SwiftUI

/// 選択したライフログの全文を表示するシート。
struct LogEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss

    /// 表示するライフログ。
    let entry: LogEntry

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(entry.title)
                        .font(.title2.bold())

                    Text(entry.body)

                    if !entry.tags.isEmpty {
                        TagList(tags: entry.tags)
                    }

                    if let placeName = entry.placeName {
                        Label(placeName, systemImage: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle(DateDisplay.shortDateTime(for: entry.createdAt))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
