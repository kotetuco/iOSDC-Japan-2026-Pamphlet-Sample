/// 構造化された要約を画面表示用の文字列へ整形する処理。
nonisolated enum SummaryFormatter {
    /// 概要と要点を一定のテンプレートで整形した文字列を返す。
    static func string(overview: String, keyPoints: [String]) -> String {
        (["概要: \(overview)", "ポイント:"] + keyPoints.map { "- \($0)" })
            .joined(separator: "\n")
    }
}
