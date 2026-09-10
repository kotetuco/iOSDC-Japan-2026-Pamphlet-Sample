import SwiftUI

/// 横幅に収まらない要素を次の行へ折り返すレイアウト。
struct FlowLayout: Layout {
    /// 要素間と行間に設ける余白。
    var spacing: CGFloat = 8

    /// サブビューを折り返して配置するために必要なサイズを返す。
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(for: proposal, subviews: subviews).size
    }

    /// サブビューを利用可能な横幅に合わせて折り返し配置する。
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangement(for: proposal, subviews: subviews).rows

        for row in rows {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    /// 各サブビューの配置先とレイアウト全体のサイズを計算する。
    private func arrangement(for proposal: ProposedViewSize, subviews: Subviews) -> (rows: [Row], size: CGSize) {
        let maximumWidth = proposal.width ?? .greatestFiniteMagnitude
        var rows = [Row()]

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            var row = rows.removeLast()
            let nextX = row.items.isEmpty ? 0 : row.width + spacing

            if nextX + size.width > maximumWidth, !row.items.isEmpty {
                rows.append(row)
                row = Row()
            }

            let origin = CGPoint(x: row.items.isEmpty ? 0 : row.width + spacing, y: 0)
            row.items.append(RowItem(index: index, origin: origin, size: size))
            row.width = max(row.width, origin.x + size.width)
            row.height = max(row.height, size.height)
            rows.append(row)
        }

        var originY: CGFloat = 0
        for rowIndex in rows.indices {
            for itemIndex in rows[rowIndex].items.indices {
                rows[rowIndex].items[itemIndex].origin.y = originY
            }
            originY += rows[rowIndex].height + spacing
        }

        let width = rows.map(\.width).max() ?? 0
        return (rows, CGSize(width: width, height: max(0, originY - spacing)))
    }

    /// 1行分の配置情報。
    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// 1つのサブビューの配置情報。
    private struct RowItem {
        let index: Int
        var origin: CGPoint
        let size: CGSize
    }
}
