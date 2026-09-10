import Foundation
import Testing
@testable import OnDeviceSummary

struct ExecuTorchSummarizerTests {
    @Test func appendsOutputFormatAfterInput() {
        let input = "08:00 朝食"
        let content = ExecuTorchSummarizer.makeUserContent(from: input)
        #expect(content.hasPrefix(input))
        #expect(content.hasSuffix(SummaryTextParser.formatInstruction))
    }

    @Test(arguments: [
        ("本文<|im_end|>後続", "本文"),
        ("本文<|endoftext|>#タグ", "本文"),
        ("  本文  ", "本文")
    ])
    func removesEndMarkers(_ text: String, _ expected: String) {
        #expect(ExecuTorchSummarizer.cleanedOutput(from: text, prompt: "P") == expected)
    }

    @Test func reportsMissingResources() async {
        let summarizer = ExecuTorchSummarizer { _, _ in nil }
        let availability = await summarizer.availability
        guard case let .unavailable(reason) = availability else {
            Issue.record("Expected missing model resources to be unavailable")
            return
        }
        #expect(reason.contains("models/README.md"))
    }

    @Test func reportsMissingRuntimeHeaders() async {
        let resourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-resource")
        let summarizer = ExecuTorchSummarizer(
            locateResource: { _, _ in resourceURL },
            isRuntimeAvailable: { false }
        )

        let availability = await summarizer.availability

        guard case let .unavailable(reason) = availability else {
            Issue.record("Expected missing runtime headers to be unavailable")
            return
        }
        #expect(reason.contains("fetch_executorch_headers.sh"))
    }
}
