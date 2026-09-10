import Foundation

/// ライフログの日時を日本語で表示する処理。
enum DateDisplay {
    private static let monthTitleFormatter = makeFormatter(format: "yyyy年M月")
    private static let sectionTitleFormatter = makeFormatter(format: "M月d日 EEEE")
    private static let pickerTitleFormatter = makeFormatter(format: "M月d日 E")
    private static let timeFormatter = makeFormatter(format: "HH:mm")
    private static let shortDateTimeFormatter = makeFormatter(format: "yyyy/M/d HH:mm")

    /// 月単位の画面タイトルを返す。
    static func monthTitle(for date: Date) -> String {
        monthTitleFormatter.string(from: date)
    }

    /// 日付単位のセクションタイトルを返す。
    static func sectionTitle(for date: Date) -> String {
        sectionTitleFormatter.string(from: date)
    }

    /// 日付選択用の短いタイトルを返す。
    static func pickerTitle(for date: Date) -> String {
        pickerTitleFormatter.string(from: date)
    }

    /// 時刻だけを表す文字列を返す。
    static func time(for date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// 詳細画面用の短い日時を返す。
    static func shortDateTime(for date: Date) -> String {
        shortDateTimeFormatter.string(from: date)
    }

    /// 指定した書式で日本時間を表示するフォーマッターを作る。
    private static func makeFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        let calendar = Calendar.japan
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = format
        return formatter
    }
}
