import SwiftUI

/// Foundation Modelsの要約実行ボタンと利用不可時の理由を表示するセクション。
struct EngineActionsSection: View {
    let isRunDisabled: Bool
    let availability: EngineAvailability?
    let runFoundationModels: () -> Void

    var body: some View {
        Section {
            Button(action: runFoundationModels) {
                Label("Foundation Modelsで要約", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isRunDisabled)

            if case let .unavailable(reason) = availability {
                Text(reason).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
