/// Qwen3のチャットテンプレートへ入力を埋め込む処理。
nonisolated enum QwenPromptFormatter {
    /// Qwen3の推論出力を抑制したチャットプロンプトを生成する。
    static func prompt(instruction: String, input: String) -> String {
        """
        <|im_start|>system
        \(instruction)<|im_end|>
        <|im_start|>user
        \(input)<|im_end|>
        <|im_start|>assistant
        <think>

        </think>

        """
    }
}
