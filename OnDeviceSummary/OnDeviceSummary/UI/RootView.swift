import SwiftData
import SwiftUI

/// サンプルデータと要約画面を切り替えるアプリのルート画面。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var seedError: String?
    @State private var isSeedErrorAlertPresented = false

    var body: some View {
        TabView {
            Tab("サンプルデータ", systemImage: "list.bullet.rectangle") {
                SampleDataTab(seedError: seedError)
            }
            Tab("要約", systemImage: "sparkles") {
                SummaryTab(seedError: seedError)
            }
        }
        .alert("サンプルデータの読み込みに失敗しました", isPresented: $isSeedErrorAlertPresented) {
            Button("閉じる", role: .cancel) {}
        } message: {
            Text(seedError ?? "")
        }
        .task(seedSampleDataIfNeeded)
    }

    @Sendable
    private func seedSampleDataIfNeeded() async {
        do {
            let resourceURL = Bundle.main.url(forResource: "dummy_2026_05", withExtension: "csv")
            let seeder = LogEntrySeeder(modelContainer: modelContext.container)
            try await seeder.seedIfNeeded(from: resourceURL)
        } catch {
            seedError = error.localizedDescription
            isSeedErrorAlertPresented = true
        }
    }
}

#Preview {
    RootView().modelContainer(for: LogEntry.self, inMemory: true)
}
