import Foundation
import SwiftData
import Testing
@testable import OnDeviceSummary

struct LogEntrySeederTests {
    @Test func seedsOnlyOnce() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LogEntry.self, configurations: configuration)
        let resourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("seed-\(UUID().uuidString).csv")
        try csv.write(to: resourceURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: resourceURL) }

        let seeder = LogEntrySeeder(modelContainer: container)
        try await seeder.seedIfNeeded(from: resourceURL)
        try await seeder.seedIfNeeded(from: resourceURL)

        let modelContext = ModelContext(container)
        #expect(try modelContext.fetchCount(FetchDescriptor<LogEntry>()) == 1)
    }

    private let csv = """
    "id","title","body","tags","latitude","longitude","placeName","createdAt","updatedAt"
    "018f84a4-8f9a-7a31-b28a-57a60f33a711","朝食","家族で朝食をとった。","[""食事"",""家族""]",\
    "","","自宅（架空）","2026-05-01T07:30:00+09:00","2026-05-01T07:30:00+09:00"
    """
}
