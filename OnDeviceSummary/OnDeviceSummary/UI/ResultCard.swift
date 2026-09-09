import SwiftUI
import UIKit

/// 要約結果の状態と、成功時のメタデータを表示するカード。
struct ResultCard: View {
    let engineName: String
    let state: EngineRunState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(engineName).font(.headline)
                Spacer()
                statusLabel
            }

            switch state {
            case .idle:
                Text("未実行").foregroundStyle(.secondary)
            case .running:
                ProgressView("要約中…")
            case let .success(output):
                VStack(alignment: .leading, spacing: 10) {
                    Text(output.text).textSelection(.enabled)
                    HStack {
                        if let load = output.loadDuration {
                            LabeledContent("ロード時間", value: load.secondsText)
                        }
                        LabeledContent("処理時間", value: output.totalDuration.secondsText)
                        if let first = output.firstTokenDuration {
                            LabeledContent("初回トークン", value: first.secondsText)
                        }
                        if output.usedRawFallback {
                            LabeledContent("試行", value: "全\(output.attemptCount ?? 0)回失敗・生出力")
                        } else if let attempts = output.attemptCount {
                            LabeledContent("試行", value: "\(attempts)回目で成功")
                        }
                        LabeledContent("出力", value: "\(output.text.count)字")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Button("コピー", systemImage: "doc.on.doc", action: copyOutputText)
                        .buttonStyle(.bordered)
                }
            case let .failure(message):
                Text(message).foregroundStyle(.red).textSelection(.enabled)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch state {
        case .idle: Label("未実行", systemImage: "circle").foregroundStyle(.secondary)
        case .running: Label("実行中", systemImage: "hourglass").foregroundStyle(.orange)
        case .success: Label("成功", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .failure: Label("失敗", systemImage: "xmark.circle.fill").foregroundStyle(.red)
        }
    }

    private func copyOutputText() {
        if case let .success(output) = state { UIPasteboard.general.string = output.text }
    }
}
