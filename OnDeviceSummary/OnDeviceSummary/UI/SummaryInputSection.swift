import SwiftUI

/// 要約対象の日付と入力テキストのプレビューを表示するセクション。
struct SummaryInputSection: View {
    let availableDates: [Date]
    @Binding var selectedDate: Date?
    let entryCount: Int
    let inputText: String

    var body: some View {
        Section("入力") {
            Picker("日付", selection: $selectedDate) {
                ForEach(availableDates, id: \.self) { date in
                    Text(DateDisplay.pickerTitle(for: date)).tag(Optional(date))
                }
            }

            LabeledContent("対象件数", value: "\(entryCount)件")
            LabeledContent("入力文字数", value: "\(inputText.count)字")

            if !inputText.isEmpty {
                DisclosureGroup("入力プレビュー") {
                    Text(inputText)
                        .font(.caption)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}
