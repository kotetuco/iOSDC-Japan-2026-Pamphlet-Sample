import Testing
@testable import OnDeviceSummary

struct SummaryFormatterTests {
    @Test func usesStableTemplate() {
        let text = SummaryFormatter.string(
            overview: "家族と過ごした穏やかな一日でした。",
            keyPoints: [
                "朝は家族で食事をした",
                "夕方に公園を散歩した",
                "夜は落ち着いて過ごした"
            ]
        )

        let expected = """
        概要: 家族と過ごした穏やかな一日でした。
        ポイント:
        - 朝は家族で食事をした
        - 夕方に公園を散歩した
        - 夜は落ち着いて過ごした
        """
        #expect(text == expected)
    }
}
