import Testing
@testable import OnDeviceSummary

struct LogEntryRecordDecoderTests {
    @Test func decodesRequiredAndOptionalFields() throws {
        let record = [
            "id": "018f84a4-8f9a-7a31-b28a-57a60f33a711",
            "title": "朝食",
            "body": "家族で朝食をとった。",
            "tags": #"["食事","家族"]"#,
            "latitude": "",
            "longitude": "",
            "placeName": "自宅（架空）",
            "createdAt": "2026-05-01T07:30:00+09:00",
            "updatedAt": "2026-05-01T07:30:00+09:00"
        ]

        let entry = try LogEntryRecordDecoder().decode(record)

        #expect(entry.title == "朝食")
        #expect(entry.tags == ["食事", "家族"])
        #expect(entry.latitude == nil)
        #expect(entry.longitude == nil)
        #expect(entry.placeName == "自宅（架空）")
    }

    @Test func rejectsMissingRequiredFields() {
        #expect(throws: LogEntrySeederError.missingField("id")) {
            try LogEntryRecordDecoder().decode([:])
        }
    }

    @Test func rejectsInvalidDates() {
        let record = [
            "id": "018f84a4-8f9a-7a31-b28a-57a60f33a711",
            "createdAt": "not-a-date",
            "updatedAt": "2026-05-01T07:30:00+09:00"
        ]

        #expect(throws: LogEntrySeederError.invalidDate("not-a-date")) {
            try LogEntryRecordDecoder().decode(record)
        }
    }
}
