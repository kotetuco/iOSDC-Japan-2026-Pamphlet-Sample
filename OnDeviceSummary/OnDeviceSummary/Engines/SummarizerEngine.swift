import Foundation

/// 要約エンジンを現在の実行環境で利用できるかを表す状態。
nonisolated enum EngineAvailability: Equatable, Sendable {
    case available
    case unavailable(reason: String)
}

/// 要約結果と、エンジン間の比較に使う計測値。
nonisolated struct SummaryOutput: Equatable, Sendable {
    /// 整形済みの要約本文。
    let text: String

    /// モデルロードを除き、リトライを含む要約生成全体にかかった時間。
    let totalDuration: Duration

    /// ストリーミング開始から最初のトークンを受け取るまでの時間。
    let firstTokenDuration: Duration?

    /// モデルのロードにかかった時間。
    let loadDuration: Duration?

    /// 構造化出力の生成または解析に成功した試行回数。
    let attemptCount: Int?

    /// 全試行に失敗し、未解析の出力を返したかどうか。
    let usedRawFallback: Bool

    /// 要約結果と計測値を作成する。
    init(
        text: String,
        totalDuration: Duration,
        firstTokenDuration: Duration?,
        loadDuration: Duration?,
        attemptCount: Int? = nil,
        usedRawFallback: Bool = false
    ) {
        self.text = text
        self.totalDuration = totalDuration
        self.firstTokenDuration = firstTokenDuration
        self.loadDuration = loadDuration
        self.attemptCount = attemptCount
        self.usedRawFallback = usedRawFallback
    }
}

/// 入力テキストから要約を生成するエンジン。
protocol SummarizerEngine: Sendable {
    /// 結果表示やログで使うエンジン名。
    var name: String { get }

    /// 現在の実行環境における利用可否。
    var availability: EngineAvailability { get async }

    /// 入力テキストを要約し、整形済みの結果と計測値を返す。
    func summarize(_ input: String) async throws -> SummaryOutput
}

/// 要約エンジンから利用者へ提示するエラー。
nonisolated struct SummaryEngineError: Error, LocalizedError, Sendable {
    /// 利用者が原因と対処を判断できるメッセージ。
    let message: String

    /// ローカライズ済みのエラー説明。
    var errorDescription: String? {
        message
    }
}

nonisolated extension Duration {
    /// 秒単位に丸めた日本語の表示文字列。
    var secondsText: String {
        let components = components
        let seconds = Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
        return String(format: "%.2f秒", seconds)
    }
}
