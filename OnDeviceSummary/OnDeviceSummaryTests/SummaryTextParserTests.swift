import Testing
@testable import OnDeviceSummary

struct SummaryTextParserTests {
    @Test func parsesThreePointsAndIgnoresThinkingText() throws {
        let result = try #require(SummaryTextParser.parse("""
        <think>入力を整理する</think>
        概要：家族と過ごした一日
        ポイント:
        - 朝食
        1. 公園の散歩
        ３．夕食
        """))

        #expect(result.overview == "家族と過ごした一日")
        #expect(result.keyPoints == ["朝食", "公園の散歩", "夕食"])
    }

    @Test func rejectsIncompleteOrExampleOutput() {
        #expect(SummaryTextParser.parse("概要: 一日\n- 朝食\n- 散歩") == nil)
        #expect(SummaryTextParser.parse("""
        概要: \(SummaryTextParser.exampleOverview)
        - \(SummaryTextParser.exampleKeyPoints[0])
        - \(SummaryTextParser.exampleKeyPoints[1])
        - \(SummaryTextParser.exampleKeyPoints[2])
        """) == nil)
    }
}
