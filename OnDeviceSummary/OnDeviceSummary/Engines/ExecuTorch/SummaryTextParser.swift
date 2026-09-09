import Foundation

/// ExecuTorchのテキスト出力を要約の構造へ変換する処理。
nonisolated enum SummaryTextParser {
    static let exampleOverview = "散歩と家族での外食を楽しんだ穏やかな一日"
    static let exampleKeyPoints = [
        "朝の公園散歩で気分転換",
        "家族でラーメン店を訪問",
        "子供がラーメンを完食"
    ]

    /// 小型モデルが従う要約フォーマットの指示。
    static let formatInstruction = """
    出力は必ず次の形式に従うこと。前置き・後書き・説明は書かない。入力の行をそのまま書き写さず、要約のみを出力する。
    概要: <その日の概要を1文・60字以内>
    ポイント:
    - <重要な出来事（体言止め・40字以内・句読点と「」を使わない）>
    - <重要な出来事（同上）>
    - <重要な出来事（同上）>
    ポイントは必ず3行。各行は「- 」で始めること。

    出力例（内容は写さず、形式だけ従うこと）:
    概要: \(exampleOverview)
    ポイント:
    - \(exampleKeyPoints[0])
    - \(exampleKeyPoints[1])
    - \(exampleKeyPoints[2])
    """

    /// 要約フォーマットを解釈できた場合に概要と要点3件を返す。
    static func parse(_ text: String) -> (overview: String, keyPoints: [String])? {
        let cleanedText = removeThinkingText(from: text).trimmingCharacters(in: .whitespacesAndNewlines)
        var overview: String?
        var keyPoints: [String] = []

        for rawLine in cleanedText.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            if overview == nil, let parsedOverview = parseOverview(from: line) {
                overview = parsedOverview
            } else if let keyPoint = parseKeyPoint(from: line) {
                keyPoints.append(keyPoint)
            }
        }

        guard let overview, !overview.isEmpty, keyPoints.count >= 3 else { return nil }
        let selectedKeyPoints = Array(keyPoints.prefix(3))
        guard overview != exampleOverview,
              !selectedKeyPoints.contains(where: { exampleKeyPoints.contains($0) }) else { return nil }
        return (overview, selectedKeyPoints)
    }

    private static func removeThinkingText(from text: String) -> String {
        var result = text
        while let start = result.range(of: "<think>") {
            guard let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) else {
                result.removeSubrange(start)
                continue
            }
            result.removeSubrange(start.lowerBound..<end.upperBound)
        }
        return result.replacingOccurrences(of: "</think>", with: "")
    }

    private static func parseOverview(from line: String) -> String? {
        for prefix in ["概要:", "概要："] where line.hasPrefix(prefix) {
            return validParsedText(String(line.dropFirst(prefix.count)))
        }
        return nil
    }

    private static func parseKeyPoint(from line: String) -> String? {
        if let firstCharacter = line.first, ["-", "・", "*"].contains(firstCharacter) {
            return validParsedText(String(line.dropFirst()))
        }
        let numberEnd = line.prefix { $0.isASCIIDigit || $0.isFullWidthDigit }.endIndex
        guard numberEnd > line.startIndex, numberEnd < line.endIndex else { return nil }
        guard [".", ")", "．"].contains(line[numberEnd]) else { return nil }
        return validParsedText(String(line[line.index(after: numberEnd)...]))
    }

    private static func validParsedText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("<"),
              trimmed.unicodeScalars.contains(where: { !ignoredScalarCharacters.contains($0) }) else {
            return nil
        }
        return trimmed
    }

    private static let ignoredScalarCharacters = CharacterSet.whitespacesAndNewlines
        .union(.punctuationCharacters)
        .union(.symbols)
}

private nonisolated extension Character {
    var isASCIIDigit: Bool { "0"..."9" ~= self }
    var isFullWidthDigit: Bool { "０"..."９" ~= self }
}
