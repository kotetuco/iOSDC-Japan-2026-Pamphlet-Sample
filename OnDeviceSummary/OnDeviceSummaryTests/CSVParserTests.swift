import Testing
@testable import OnDeviceSummary

struct CSVParserTests {
    @Test func handlesQuotedCommasNewlinesAndEscapedQuotes() throws {
        let text = #"""
        id,title,body,tags
        1,"発表会, 午前","1行目
        2行目 ""引用""","[""育児"", ""学校""]"
        """#

        let records = try CSVParser().records(from: text)

        #expect(records.count == 1)
        #expect(records[0]["title"] == "発表会, 午前")
        #expect(records[0]["body"] == "1行目\n2行目 \"引用\"")
        #expect(records[0]["tags"] == #"["育児", "学校"]"#)
    }

    @Test func rejectsDuplicateHeaders() {
        let text = """
        id,title,title
        1,朝食,散歩
        """

        #expect(throws: CSVParserError.duplicateHeaderField("title")) {
            try CSVParser().records(from: text)
        }
    }

    @Test func rejectsRowsWithUnexpectedFieldCount() {
        let text = """
        id,title
        1,朝食,余分な値
        """

        #expect(throws: CSVParserError.inconsistentFieldCount(row: 2, expected: 2, actual: 3)) {
            try CSVParser().records(from: text)
        }
    }
}
