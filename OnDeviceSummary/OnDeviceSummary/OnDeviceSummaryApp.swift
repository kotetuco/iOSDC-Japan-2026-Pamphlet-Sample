import SwiftData
import SwiftUI

/// サンプルアプリのエントリーポイント。
@main
struct OnDeviceSummaryApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: LogEntry.self)
    }
}
