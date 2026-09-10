//
//  ExecuTorchSummarizer.swift
//  OnDeviceSummary
//

import Foundation

#if canImport(ExecuTorchLLM)
import ExecuTorchLLM
#endif

struct ExecuTorchSummarizer: SummarizerEngine {
    let name = "ExecuTorch"

    /// 先頭から順に探し、最初に見つかったモデルを使う（第一候補 1.7B、フォールバック 0.6B）。
    /// トークナイザは Qwen3 全サイズ共通のため 1 ファイルを共用する。
    private static let modelFileNameCandidates = ["qwen3_1_7b", "qwen3_0_6b"]
    private static let modelFileExtension = "pte"
    private static let tokenizerFileName = "tokenizer"
    private static let tokenizerFileExtension = "json"
    // 行末の \ は改行を含めない行継続。文字列の値は 1 行のまま変わらない。
    private static let missingModelMessage = """
    ExecuTorch のモデルファイル（qwen3_1_7b.pte または qwen3_0_6b.pte / tokenizer.json）が見つかりません。\
    OnDeviceSummary/models/README.md の手順で書き出し、\
    OnDeviceSummary/OnDeviceSummary/Resources/Models/ に配置して再ビルドしてください。
    """
    private static let missingDependencyMessage = """
    ExecuTorch SwiftPM 依存がまだ追加されていません。Xcode で \
    https://github.com/pytorch/executorch.git の swiftpm-1.3.1 ブランチを app ターゲットへ追加してください。
    """
    private static let missingHeadersMessage = """
    ExecuTorch の C++ ヘッダが見つかりません。OnDeviceSummary/scripts/fetch_executorch_headers.sh を実行して、\
    再ビルドしてください。
    """

    /// Matches FoundationModelsSummarizer so the retry strategy is shared and
    /// only the structure-guarantee mechanism differs between the engines.
    nonisolated private static let attemptTemperatures: [Double] = [0.3, 0.7, 1.0]

    /// 書式指示は入力の後ろに置く。小型モデルは直近の指示に従いやすく、
    /// system 先頭の指示だけでは長いリスト入力に負けて入力の復唱が起きた
    /// （2026-07-05 実測）。system側は共有のSummaryPrompt.instructionのみ。
    nonisolated static func makeUserContent(from input: String) -> String {
        input + "\n\n" + SummaryTextParser.formatInstruction
    }

    private let locateResource: @Sendable (String, String) -> URL?
    private let isRuntimeAvailable: @Sendable () -> Bool

    nonisolated init(
        locateResource: @escaping @Sendable (String, String) -> URL? = Self.defaultLocateResource,
        isRuntimeAvailable: @escaping @Sendable () -> Bool = { UTF8SafeTextRunner.isRuntimeAvailable() }
    ) {
        self.locateResource = locateResource
        self.isRuntimeAvailable = isRuntimeAvailable
    }

    var availability: EngineAvailability {
        get async {
            guard locateModelResources() != nil else {
                return .unavailable(reason: Self.missingModelMessage)
            }

            #if canImport(ExecuTorchLLM)
            guard isRuntimeAvailable() else {
                return .unavailable(reason: Self.missingHeadersMessage)
            }
            return .available
            #else
            return .unavailable(reason: Self.missingDependencyMessage)
            #endif
        }
    }

    func summarize(_ input: String) async throws -> SummaryOutput {
        guard let resources = locateModelResources() else {
            throw SummaryEngineError(message: Self.missingModelMessage)
        }

        #if canImport(ExecuTorchLLM)
        let prompt = QwenPromptFormatter.prompt(
            instruction: SummaryPrompt.instruction,
            input: Self.makeUserContent(from: input)
        )
        let tokenizerURL = TokenizerNormalizerWorkaround.preparedTokenizerURL(from: resources.tokenizer)
        // UTF8SafeTextRunner は非 Sendable。生成処理は generate(with:prompt:) の
        // 実行スレッドに閉じ、キャンセル時に別スレッドから触るのは stop()
        // （トークンごとに参照されるフラグを立てるだけの操作）のみ、という
        // 運用で安全を保証しているため nonisolated(unsafe) で受け渡す。
        nonisolated(unsafe) let runner = UTF8SafeTextRunner(
            modelPath: resources.model.path,
            tokenizerPath: tokenizerURL.path,
            specialTokens: []
        )

        return try await withTaskCancellationHandler {
            try await Self.generate(with: runner, prompt: prompt)
        } onCancel: {
            runner.stop()
        }
        #else
        _ = resources
        throw SummaryEngineError(message: Self.missingDependencyMessage)
        #endif
    }

    #if canImport(ExecuTorchLLM)
    /// 1 回の生成試行の結果（整形済みの生テキストと計測値）。
    private struct GenerationAttempt {
        let rawText: String
        let firstTokenDuration: Duration?
        let generationDuration: Duration
    }

    /// モデルのロードと生成（CPU バウンドの同期 API）をメインアクター外で実行する。
    @concurrent
    private static func generate(
        with runner: UTF8SafeTextRunner,
        prompt: String
    ) async throws -> SummaryOutput {
        do {
            let clock = ContinuousClock()
            let loadStart = clock.now
            try runner.load()
            let loadDuration = loadStart.duration(to: clock.now)

            var lastAttempt = GenerationAttempt(rawText: "", firstTokenDuration: nil, generationDuration: .zero)

            for (attemptIndex, temperature) in attemptTemperatures.enumerated() {
                if attemptIndex > 0 {
                    runner.reset()
                }

                let attempt = try runAttempt(runner: runner, prompt: prompt, temperature: temperature, clock: clock)
                try Task.checkCancellation()
                lastAttempt = attempt

                if let parsed = SummaryTextParser.parse(attempt.rawText) {
                    return SummaryOutput(
                        text: SummaryFormatter.string(
                            overview: parsed.overview,
                            keyPoints: parsed.keyPoints
                        ),
                        totalDuration: attempt.generationDuration,
                        firstTokenDuration: attempt.firstTokenDuration,
                        loadDuration: loadDuration,
                        attemptCount: attemptIndex + 1
                    )
                }

                if attemptIndex + 1 < attemptTemperatures.count {
                    logRetry(afterAttempt: attemptIndex, generationDuration: attempt.generationDuration)
                }
            }

            logRawFallback(generationDuration: lastAttempt.generationDuration)
            return SummaryOutput(
                text: lastAttempt.rawText,
                totalDuration: lastAttempt.generationDuration,
                firstTokenDuration: lastAttempt.firstTokenDuration,
                loadDuration: loadDuration,
                attemptCount: attemptTemperatures.count,
                usedRawFallback: true
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // キャンセルにより runner が実行途中で停止してエラーになった場合は
            // 実行エラーではなくキャンセルとして扱う。
            try Task.checkCancellation()
            throw SummaryEngineError(message: executionFailureMessage(for: error))
        }
    }

    /// 失敗試行の生成時間も記事の計測対象（512トークン走り切りの検出）のためログに残す。
    nonisolated private static func logRetry(afterAttempt attemptIndex: Int, generationDuration: Duration) {
        print(
            "[検証] ExecuTorch attempt \(attemptIndex + 1) "
                + "パース失敗（生成 \(generationDuration.secondsText)）"
                + "→ temperature \(attemptTemperatures[attemptIndex + 1]) で再試行"
        )
    }

    nonisolated private static func logRawFallback(generationDuration: Duration) {
        print(
            "[検証] ExecuTorch 全\(attemptTemperatures.count)試行パース失敗"
                + "（最終試行の生成 \(generationDuration.secondsText)）→ 生出力へフォールバック"
        )
    }

    /// 指定 temperature で 1 回だけ生成し、終端マーカー以降を除いたテキストを返す。
    nonisolated private static func runAttempt(
        runner: UTF8SafeTextRunner,
        prompt: String,
        temperature: Double,
        clock: ContinuousClock
    ) throws -> GenerationAttempt {
        var text = ""
        var firstTokenDuration: Duration?
        let generateStart = clock.now
        try runner.generate(
            prompt,
            sequenceLength: 4096,
            maximumNewTokens: 512,
            temperature: temperature,
            echoEnabled: false
        ) { token in
            if firstTokenDuration == nil {
                firstTokenDuration = generateStart.duration(to: clock.now)
            }
            text += token
            // v1.3.1 では .pte の停止トークンが読まれない
            // （メタデータのキー名不一致、2026-07-14 調査）ため、
            // 終端マーカーを検出したら手動で生成を打ち切る。
            // stop() はトークンごとに見るフラグを立てるだけなので
            // コールバック内から呼んでも安全。
            if containsEndMarker(text) {
                runner.stop()
            }
        }
        return GenerationAttempt(
            rawText: cleanedOutput(from: text, prompt: prompt),
            firstTokenDuration: firstTokenDuration,
            generationDuration: generateStart.duration(to: clock.now)
        )
    }
    #endif

    private func locateModelResources() -> (model: URL, tokenizer: URL)? {
        guard let tokenizer = locateResource(Self.tokenizerFileName, Self.tokenizerFileExtension) else {
            return nil
        }
        for candidate in Self.modelFileNameCandidates {
            if let model = locateResource(candidate, Self.modelFileExtension) {
                return (model, tokenizer)
            }
        }
        return nil
    }

    nonisolated private static func defaultLocateResource(name: String, extension fileExtension: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: fileExtension)
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Models")
    }

    /// 終端トークン以降を切り捨てる。0.6B はチャット書式から脱線して
    /// `<|endoftext|>` を文中に出した後も生成を続けることがある
    /// （2026-07-06 実測: 以降はハッシュタグ連呼などの無関係な暴走出力）。
    nonisolated private static let endMarkers = ["<|im_end|>", "<|endoftext|>"]

    /// 生成打ち切り用。tokenizer_config.json 同梱で `<|im_end|>` は eos として
    /// 止まるようになるが、eos は単一値のため脱線時の `<|endoftext|>` は
    /// 登録できない。両マーカーを文字列で検知して止める保険。
    nonisolated static func containsEndMarker(_ text: String) -> Bool {
        endMarkers.contains { text.contains($0) }
    }

    nonisolated static func cleanedOutput(from text: String, prompt: String) -> String {
        var output = text.removingPrefix(prompt)
        for marker in Self.endMarkers {
            if let range = output.range(of: marker) {
                output = String(output[..<range.lowerBound])
            }
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func executionFailureMessage(for error: Error) -> String {
        let nsError = error as NSError
        var message = "ExecuTorch の実行に失敗しました: \(nsError.localizedDescription)"
        message += "\nDomain: \(nsError.domain), code: \(nsError.code)"

        if !nsError.userInfo.isEmpty {
            message += "\nUserInfo: \(nsError.userInfo)"
        }

        return message
    }
}

private nonisolated extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else {
            return self
        }
        return String(dropFirst(prefix.count))
    }
}
