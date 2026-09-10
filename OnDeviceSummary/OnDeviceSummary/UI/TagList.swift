import SwiftUI

/// タグを利用可能な横幅に合わせて並べるビュー。
struct TagList: View {
    /// 表示するタグ。
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
