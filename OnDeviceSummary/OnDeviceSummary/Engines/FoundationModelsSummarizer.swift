import Foundation
import FoundationModels

/// Foundation Modelsが生成する構造化された要約。
@Generable(description: "A concise Japanese summary of personal lifelog entries")
struct FoundationModelsSummaryDraft {
    /// その日の内容を60文字以内の日本語一文で表した概要。
    @Guide(description: "One-sentence Japanese overview of the day, within 60 characters")
    var overview: String

    /// 句読点とかぎ括弧を使わない、40文字以内の日本語の要点3件。
    @Guide(
        description: """
        Exactly 3 short Japanese key points, each a noun phrase (体言止め) within 40 characters, \
        with no trailing punctuation and no 「」 quotation marks
        """,
        .count(3)
    )
    var keyPoints: [String]
}

/// Appleのオンデバイスモデルを使ってライフログを要約するエンジン。
struct FoundationModelsSummarizer: SummarizerEngine {
    /// 生成結果の復元に失敗した場合に順番に使用するtemperature。
    private static let attemptTemperatures = [0.3, 0.7, 1.0]

    /// 結果表示やログで使うエンジン名。
    let name = "Foundation Models"

    /// 現在の実行環境におけるFoundation Modelsの利用可否。
    var availability: EngineAvailability {
        get async {
            switch SystemLanguageModel.default.availability {
            case .available:
                .available
            case let .unavailable(reason):
                .unavailable(reason: message(for: reason))
            }
        }
    }

    /// 入力テキストを構造化された日本語の要約へ変換する。
    func summarize(_ input: String) async throws -> SummaryOutput {
        if case let .unavailable(reason) = await availability {
            throw SummaryEngineError(message: reason)
        }

        let clock = ContinuousClock()

        for (index, temperature) in Self.attemptTemperatures.enumerated() {
            let attempt = index + 1
            let session = LanguageModelSession(model: .default, instructions: SummaryPrompt.instruction)
            let options = GenerationOptions(temperature: temperature, maximumResponseTokens: 512)
            let start = clock.now

            do {
                let response = try await session.respond(
                    to: input,
                    generating: FoundationModelsSummaryDraft.self,
                    options: options
                )
                let duration = start.duration(to: clock.now)
                return SummaryOutput(
                    text: SummaryFormatter.string(
                        overview: response.content.overview,
                        keyPoints: response.content.keyPoints
                    ),
                    totalDuration: duration,
                    firstTokenDuration: nil,
                    loadDuration: nil,
                    attemptCount: attempt
                )
            } catch let error as LanguageModelSession.GenerationError {
                let hasNextAttempt = attempt < Self.attemptTemperatures.count
                if case .decodingFailure = error, hasNextAttempt {
                    logRetry(
                        attempt: attempt,
                        duration: start.duration(to: clock.now),
                        nextTemperature: Self.attemptTemperatures[attempt]
                    )
                    continue
                }

                throw SummaryEngineError(message: message(for: error, attempts: attempt))
            }
        }

        throw SummaryEngineError(message: "Foundation Modelsで要約を生成できませんでした。")
    }

    /// Foundation Modelsを利用できない理由を利用者向けの文言へ変換する。
    private func message(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .appleIntelligenceNotEnabled:
            "Apple Intelligenceが有効になっていません。設定で有効にしてから再実行してください。"
        case .deviceNotEligible:
            "この端末はFoundation Modelsの実行要件を満たしていません。Apple Intelligence対応端末で確認してください。"
        case .modelNotReady:
            "Foundation Modelsのモデルを準備しています。ダウンロード完了後に再実行してください。"
        @unknown default:
            "Foundation Modelsを現在利用できません。理由: \(reason)"
        }
    }

    /// 生成エラーを利用者向けの文言へ変換する。
    private func message(for error: LanguageModelSession.GenerationError, attempts: Int) -> String {
        switch error {
        case let .guardrailViolation(context):
            "Foundation Modelsのガードレールにより生成が拒否されました。\n\(context.debugDescription)"
        case let .exceededContextWindowSize(context):
            "入力がFoundation Modelsのコンテキスト上限を超えました。\n\(context.debugDescription)"
        case let .unsupportedLanguageOrLocale(context):
            "この言語またはロケールはFoundation Modelsでサポートされていません。\n\(context.debugDescription)"
        case let .decodingFailure(context):
            "構造化出力（Generable）の復元に\(attempts)回失敗しました。\n\(context.debugDescription)"
        default:
            error.localizedDescription
        }
    }

    /// 構造化出力の復元失敗と次の試行条件をコンソールへ記録する。
    private func logRetry(attempt: Int, duration: Duration, nextTemperature: Double) {
        print(
            "[検証] Foundation Models attempt \(attempt) decodingFailure "
                + "（生成 \(duration.secondsText)）→ temperature \(nextTemperature) で再試行"
        )
    }
}
