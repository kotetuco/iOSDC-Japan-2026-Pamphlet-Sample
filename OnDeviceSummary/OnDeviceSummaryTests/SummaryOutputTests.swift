import Testing
@testable import OnDeviceSummary

struct SummaryOutputTests {
    @Test func supportsOptionalDurations() {
        let output = SummaryOutput(
            text: "要約",
            totalDuration: .seconds(2),
            firstTokenDuration: .milliseconds(300),
            loadDuration: .seconds(4)
        )

        #expect(output.firstTokenDuration == .milliseconds(300))
        #expect(output.loadDuration == .seconds(4))
    }

    @Test func defaultsToNoParseMetadata() {
        let output = SummaryOutput(
            text: "要約",
            totalDuration: .seconds(1),
            firstTokenDuration: nil,
            loadDuration: nil
        )

        #expect(output.attemptCount == nil)
        #expect(!output.usedRawFallback)
    }

    @Test func carriesParseAttemptMetadata() {
        let retried = SummaryOutput(
            text: "要約",
            totalDuration: .seconds(1),
            firstTokenDuration: nil,
            loadDuration: nil,
            attemptCount: 2
        )
        let fallback = SummaryOutput(
            text: "生テキスト",
            totalDuration: .seconds(1),
            firstTokenDuration: nil,
            loadDuration: nil,
            attemptCount: 3,
            usedRawFallback: true
        )

        #expect(retried.attemptCount == 2)
        #expect(!retried.usedRawFallback)
        #expect(fallback.attemptCount == 3)
        #expect(fallback.usedRawFallback)
    }
}
