import Foundation
import Testing
@testable import OnDeviceSummary

struct SummaryPromptTests {
    @Test func formatsEntriesChronologically() throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let later = LogEntry(
            id: UUID(),
            title: "散歩",
            body: "公園を歩いた。",
            tags: ["日常"],
            latitude: nil,
            longitude: nil,
            placeName: "善福寺公園",
            createdAt: try #require(formatter.date(from: "2026-05-01T17:00:00+09:00")),
            updatedAt: try #require(formatter.date(from: "2026-05-01T17:00:00+09:00"))
        )
        let earlier = LogEntry(
            id: UUID(),
            title: "朝食",
            body: "家族でパンを食べた。",
            tags: ["日常"],
            latitude: nil,
            longitude: nil,
            placeName: nil,
            createdAt: try #require(formatter.date(from: "2026-05-01T08:00:00+09:00")),
            updatedAt: try #require(formatter.date(from: "2026-05-01T08:00:00+09:00"))
        )

        let input = SummaryPrompt.input(from: [later, earlier])

        let expected = """
        08:00 朝食｜家族でパンを食べた。
        17:00 散歩｜公園を歩いた。（善福寺公園）
        """
        #expect(input == expected)
    }

    @Test func instructionLeavesOutputShapeToEachEngine() {
        #expect(!SummaryPrompt.instruction.contains("within three sentences"))
        #expect(!SummaryPrompt.instruction.contains("箇条書き"))
        #expect(SummaryPrompt.instruction.contains("Write the final answer in Japanese."))
    }
}
