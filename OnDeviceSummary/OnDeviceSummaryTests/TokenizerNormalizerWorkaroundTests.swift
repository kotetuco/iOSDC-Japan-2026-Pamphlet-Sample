import Foundation
import Testing
@testable import OnDeviceSummary

struct TokenizerNormalizerWorkaroundTests {
    @Test func removesNFCNormalizerAndUnsupportedLookahead() throws {
        let source = FileManager.default.temporaryDirectory
            .appendingPathComponent("tokenizer-\(UUID().uuidString).json")
        let json = #"{"normalizer":{"type":"NFC"},"pre_tokenizer":{"type":"Sequence","pretokenizers":["#
            + #"{"type":"Split","pattern":{"Regex":"\\s+(?!\\S)|\\s+"}}]}}"#
        try json.write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: source) }

        let prepared = TokenizerNormalizerWorkaround.preparedTokenizerURL(from: source)
        defer { try? FileManager.default.removeItem(at: prepared.deletingLastPathComponent()) }

        let result = try #require(
            try JSONSerialization.jsonObject(with: Data(contentsOf: prepared)) as? [String: Any]
        )
        #expect(result["normalizer"] is NSNull)
        let preTokenizer = try #require(result["pre_tokenizer"] as? [String: Any])
        let preTokenizers = try #require(preTokenizer["pretokenizers"] as? [[String: Any]])
        let split = try #require(preTokenizers.first)
        let pattern = try #require(split["pattern"] as? [String: Any])
        let regex = try #require(pattern["Regex"] as? String)
        #expect(!regex.contains("(?!"))
    }
}
