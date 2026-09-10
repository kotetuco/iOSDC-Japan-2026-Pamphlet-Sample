import Foundation
import Testing
@testable import OnDeviceSummary

struct DateDisplayTests {
    @Test func usesJapanTimeZone() throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let date = try #require(formatter.date(from: "2026-05-01T00:00:00+09:00"))

        #expect(DateDisplay.sectionTitle(for: date) == "5月1日 金曜日")
        #expect(DateDisplay.pickerTitle(for: date) == "5月1日 金")
        #expect(DateDisplay.time(for: date) == "00:00")
        #expect(DateDisplay.shortDateTime(for: date) == "2026/5/1 00:00")
    }
}
