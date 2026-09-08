import Foundation

/// ライフログの日時を日本語で表示する処理。
enum DateDisplay {
    /// 月単位の画面タイトルを返す。
    static func monthTitle(for date: Date) -> String {
        string(from: date, format: "yyyy年M月")
    }

    /// 日付単位のセクションタイトルを返す。
    static func sectionTitle(for date: Date) -> String {
        string(from: date, format: "M月d日 EEEE")
    }

    /// 日付選択用の短いタイトルを返す。
    static func pickerTitle(for date: Date) -> String {
        string(from: date, format: "M月d日 E")
    }

    /// 時刻だけを表す文字列を返す。
    static func time(for date: Date) -> String {
        string(from: date, format: "HH:mm")
    }

    /// 詳細画面用の短い日時を返す。
    static func shortDateTime(for date: Date) -> String {
        string(from: date, format: "yyyy/M/d HH:mm")
    }

    /// 指定した書式で日本時間の日時を返す。
    private static func string(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .japan
        formatter.timeZone = Calendar.japan.timeZone
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
