import Foundation
import SwiftData

/// ある時点の出来事を記録したライフログ。
@Model
final class LogEntry {
    /// エントリーを一意に識別する値。
    @Attribute(.unique) var id: UUID

    /// 出来事を端的に表す見出し。
    var title: String

    /// 出来事の詳細。
    var body: String

    /// 出来事を分類するタグ。
    var tags: [String]

    /// 出来事を記録した場所の緯度。
    var latitude: Double?

    /// 出来事を記録した場所の経度。
    var longitude: Double?

    /// 出来事を記録した場所の表示名。
    var placeName: String?

    /// 出来事が発生した日時。
    var createdAt: Date

    /// エントリーを最後に更新した日時。
    var updatedAt: Date

    /// ライフログのエントリーを作成する。
    init(
        id: UUID,
        title: String,
        body: String,
        tags: [String],
        latitude: Double?,
        longitude: Double?,
        placeName: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.tags = tags
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
