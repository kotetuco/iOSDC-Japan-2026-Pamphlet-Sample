import SwiftUI

/// Foundation Modelsの要約実行ボタンと利用不可時の理由を表示するセクション。
struct EngineActionsSection: View {
    let isRunDisabled: Bool
    let foundationAvailability: EngineAvailability?
    let execuTorchAvailability: EngineAvailability?
    let runFoundationModels: () -> Void
    let runExecuTorch: () -> Void

    var body: some View {
        Section {
            Button(action: runFoundationModels) {
                Label("Foundation Modelsで要約", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isRunDisabled)

            Button(action: runExecuTorch) {
                Label("ExecuTorchで要約", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isRunDisabled)

            if case let .unavailable(reason) = foundationAvailability {
                Text(reason).font(.footnote).foregroundStyle(.secondary)
            }
            if case let .unavailable(reason) = execuTorchAvailability {
                Text(reason).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
