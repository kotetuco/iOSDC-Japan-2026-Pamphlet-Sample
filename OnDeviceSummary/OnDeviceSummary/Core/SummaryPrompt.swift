import Foundation

/// ライフログから要約用のプロンプトを組み立てる処理。
enum SummaryPrompt {
    /// 要約エンジンへ渡す共通の指示。
    static let instruction = """
    You summarize personal lifelog entries. Focus on important events, family moments, places, \
    and mood. Avoid adding facts that are not present in the entries. Keep the summary concise \
    and useful for reviewing the day. Write the final answer in Japanese.
    """

    /// エントリーを時刻順に並べた要約用の入力文字列を返す。
    static func input(from entries: [LogEntry], calendar: Calendar = .japan) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"

        return entries
            .sorted { $0.createdAt < $1.createdAt }
            .map { entry in
                let time = formatter.string(from: entry.createdAt)
                let place = entry.placeName.map { "（\($0)）" } ?? ""
                return "\(time) \(entry.title)｜\(entry.body)\(place)"
            }
            .joined(separator: "\n")
    }
}

extension Calendar {
    /// 日本語表示と日本標準時を使うグレゴリオ暦。
    static var japan: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar
    }
}
