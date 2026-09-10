import Testing
@testable import OnDeviceSummary

struct QwenPromptFormatterTests {
    @Test func buildsQwenChatPromptWithoutThinkingOutput() {
        let prompt = QwenPromptFormatter.prompt(instruction: SummaryPrompt.instruction, input: "08:00 朝食")

        #expect(prompt.contains("<|im_start|>system\n\(SummaryPrompt.instruction)<|im_end|>"))
        #expect(prompt.contains("<|im_start|>user\n08:00 朝食<|im_end|>"))
        #expect(prompt.contains("<|im_start|>assistant\n<think>\n\n</think>"))
    }
}
