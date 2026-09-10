/// 要約エンジンの実行状態。
enum EngineRunState: Equatable {
    case idle
    case running
    case success(SummaryOutput)
    case failure(String)

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
}
