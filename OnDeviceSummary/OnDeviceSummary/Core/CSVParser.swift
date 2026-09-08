import Foundation

/// CSV文書を解析できない理由。
nonisolated enum CSVParserError: Error, Equatable, LocalizedError, Sendable {
    case emptyDocument
    case unterminatedQuotedField
    case inconsistentFieldCount(row: Int, expected: Int, actual: Int)
    case duplicateHeaderField(String)

    /// 利用者がCSVの問題を修正するための説明。
    var errorDescription: String? {
        switch self {
        case .emptyDocument:
            "CSVが空です。"
        case .unterminatedQuotedField:
            "CSVのクォートが閉じられていません。"
        case let .inconsistentFieldCount(row, expected, actual):
            "CSVの\(row)行目の列数が不正です。期待値: \(expected)、実際: \(actual)"
        case let .duplicateHeaderField(name):
            "CSVのヘッダー名が重複しています: \(name)"
        }
    }
}

/// RFC 4180形式のCSV文字列を解析する処理。
nonisolated struct CSVParser: Sendable {
    /// CSV文字列を行とフィールドの二次元配列へ変換する。
    func rows(from text: String) throws -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        var iterator = text.makeIterator()

        while let character = iterator.next() {
            if isInsideQuotes {
                if character == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" {
                            field.append("\"")
                        } else {
                            isInsideQuotes = false
                            handleUnquoted(next, field: &field, row: &row, rows: &rows)
                        }
                    } else {
                        isInsideQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else if character == "\"" && field.isEmpty {
                isInsideQuotes = true
            } else {
                handleUnquoted(character, field: &field, row: &row, rows: &rows)
            }
        }

        if isInsideQuotes {
            throw CSVParserError.unterminatedQuotedField
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    /// ヘッダー行をキーとして、CSV文字列をレコードの配列へ変換する。
    func records(from text: String) throws -> [[String: String]] {
        let rows = try rows(from: text)
        guard let header = rows.first else {
            throw CSVParserError.emptyDocument
        }

        var uniqueHeaders = Set<String>()
        for field in header where !uniqueHeaders.insert(field).inserted {
            throw CSVParserError.duplicateHeaderField(field)
        }

        return try rows.dropFirst().enumerated().map { index, row in
            guard row.count == header.count else {
                throw CSVParserError.inconsistentFieldCount(
                    row: index + 2,
                    expected: header.count,
                    actual: row.count
                )
            }

            return Dictionary(uniqueKeysWithValues: zip(header, row))
        }
    }

    /// クォート外の文字を現在のフィールドまたは行へ追加する。
    private func handleUnquoted(
        _ character: Character,
        field: inout String,
        row: inout [String],
        rows: inout [[String]]
    ) {
        switch character {
        case ",":
            row.append(field)
            field = ""
        case "\n":
            row.append(field.trimmingTrailingCarriageReturn())
            rows.append(row)
            row = []
            field = ""
        default:
            field.append(character)
        }
    }
}

private extension String {
    /// 末尾にあるWindows形式の改行コードの一部を取り除いた文字列。
    func trimmingTrailingCarriageReturn() -> String {
        hasSuffix("\r") ? String(dropLast()) : self
    }
}
