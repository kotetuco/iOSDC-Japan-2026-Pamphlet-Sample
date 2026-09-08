import Foundation
import SwiftData

/// サンプルのライフログを読み込めない理由。
nonisolated enum LogEntrySeederError: Error, Equatable, LocalizedError, Sendable {
    case resourceNotFound
    case missingField(String)
    case invalidUUID(String)
    case invalidDate(String)

    /// 利用者がサンプルデータの問題を判断するための説明。
    var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            "dummy_2026_05.csvがアプリバンドル内に見つかりません。"
        case let .missingField(name):
            "CSVに必須フィールド\(name)がありません。"
        case let .invalidUUID(value):
            "UUIDの形式が不正です: \(value)"
        case let .invalidDate(value):
            "日時の形式が不正です: \(value)"
        }
    }
}

/// CSVレコードからライフログを復元する処理。
struct LogEntryRecordDecoder {
    /// 1件分のCSVレコードをライフログへ変換する。
    func decode(_ record: [String: String]) throws -> LogEntry {
        let idValue = try requiredValue(for: "id", in: record)
        let createdAtValue = try requiredValue(for: "createdAt", in: record)
        let updatedAtValue = try requiredValue(for: "updatedAt", in: record)

        guard let id = UUID(uuidString: idValue) else {
            throw LogEntrySeederError.invalidUUID(idValue)
        }
        guard let createdAt = dateFormatter.date(from: createdAtValue) else {
            throw LogEntrySeederError.invalidDate(createdAtValue)
        }
        guard let updatedAt = dateFormatter.date(from: updatedAtValue) else {
            throw LogEntrySeederError.invalidDate(updatedAtValue)
        }

        let tagsText = try requiredValue(for: "tags", in: record)
        let tags = try JSONDecoder().decode([String].self, from: Data(tagsText.utf8))

        return LogEntry(
            id: id,
            title: try requiredValue(for: "title", in: record),
            body: try requiredValue(for: "body", in: record),
            tags: tags,
            latitude: optionalDouble(record["latitude"]),
            longitude: optionalDouble(record["longitude"]),
            placeName: optionalString(record["placeName"]),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// ISO 8601形式の日時を復元するフォーマッター。
    private var dateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    /// 必須フィールドの値を返す。
    private func requiredValue(for key: String, in record: [String: String]) throws -> String {
        guard let value = record[key] else {
            throw LogEntrySeederError.missingField(key)
        }
        return value
    }

    /// 空文字列を`nil`として扱う任意の文字列を返す。
    private func optionalString(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return value
    }

    /// 空文字列を`nil`として扱う任意の浮動小数点数を返す。
    private func optionalDouble(_ value: String?) -> Double? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return Double(value)
    }
}

/// 初回起動時に公開用の架空ライフログをSwiftDataへ保存する処理。
enum LogEntrySeeder {
    /// 保存済みのライフログがない場合に限り、バンドル内のCSVを読み込む。
    static func seedIfNeeded(into modelContext: ModelContext, bundle: Bundle = .main) throws {
        let descriptor = FetchDescriptor<LogEntry>()
        guard try modelContext.fetchCount(descriptor) == 0 else {
            return
        }

        guard let url = bundle.url(forResource: "dummy_2026_05", withExtension: "csv") else {
            throw LogEntrySeederError.resourceNotFound
        }

        let text = try String(contentsOf: url, encoding: .utf8)
        let records = try CSVParser().records(from: text)
        let decoder = LogEntryRecordDecoder()
        let entries = try records.map(decoder.decode)

        do {
            for entry in entries {
                modelContext.insert(entry)
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
