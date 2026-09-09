import SwiftUI

/// 時刻・内容・タグ・場所をまとめたライフログ一覧の行。
struct LogEntryRow: View {
    /// 表示するライフログ。
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(DateDisplay.time(for: entry.createdAt))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 54, alignment: .leading)

                Text(entry.title)
                    .font(.headline)
            }

            Text(entry.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                TagList(tags: entry.tags)
                Spacer(minLength: 8)

                if let placeName = entry.placeName {
                    Label(placeName, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }
}
