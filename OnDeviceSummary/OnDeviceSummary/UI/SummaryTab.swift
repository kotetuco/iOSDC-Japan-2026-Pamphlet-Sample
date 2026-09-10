import SwiftData
import SwiftUI

/// 選択した日付のライフログをFoundation Modelsで要約するタブ。
struct SummaryTab: View {
    let seedError: String?

    @Query(sort: \LogEntry.createdAt) private var entries: [LogEntry]
    @State private var selectedDate: Date?
    @State private var runState: EngineRunState = .idle
    @State private var execuTorchState: EngineRunState = .idle
    @State private var foundationAvailability: EngineAvailability?
    @State private var execuTorchAvailability: EngineAvailability?
    @State private var activeRunID: UUID?
    @State private var summaryTask: Task<Void, Never>?

    private let engine = FoundationModelsSummarizer()
    private let execuTorchEngine = ExecuTorchSummarizer()

    var body: some View {
        NavigationStack {
            List {
                if let seedError {
                    Section { Label(seedError, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                }

                SummaryInputSection(
                    availableDates: availableDates,
                    selectedDate: $selectedDate,
                    entryCount: selectedEntries.count,
                    inputText: inputText
                )

                EngineActionsSection(
                    isRunDisabled: isRunDisabled,
                    foundationAvailability: foundationAvailability,
                    execuTorchAvailability: execuTorchAvailability,
                    runFoundationModels: runFoundationModels,
                    runExecuTorch: runExecuTorch
                )

                Section("結果") {
                    ResultCard(engineName: engine.name, state: runState)
                    ResultCard(engineName: execuTorchEngine.name, state: execuTorchState)
                }
            }
            .navigationTitle("要約比較")
            .task {
                async let foundation = engine.availability
                async let execuTorch = execuTorchEngine.availability
                foundationAvailability = await foundation
                execuTorchAvailability = await execuTorch
            }
            .onAppear(perform: selectFirstDateIfNeeded)
            .onChange(of: entries.count) { _, _ in selectFirstDateIfNeeded() }
            .onChange(of: selectedDate) { _, _ in resetResults() }
            .onDisappear { summaryTask?.cancel() }
        }
    }

    private var availableDates: [Date] {
        Set(entries.map { Calendar.japan.startOfDay(for: $0.createdAt) }).sorted()
    }

    private var selectedEntries: [LogEntry] {
        guard let selectedDate else { return [] }
        return entries
            .filter { Calendar.japan.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var inputText: String { SummaryPrompt.input(from: selectedEntries) }

    private var isRunDisabled: Bool {
        inputText.isEmpty || runState.isRunning || execuTorchState.isRunning
    }

    private func selectFirstDateIfNeeded() {
        if selectedDate == nil || selectedEntries.isEmpty { selectedDate = availableDates.first }
    }

    private func runFoundationModels() {
        runEngine(engine, setState: { runState = $0 }, setAvailability: { foundationAvailability = $0 })
    }

    private func runExecuTorch() {
        runEngine(
            execuTorchEngine,
            setState: { execuTorchState = $0 },
            setAvailability: { execuTorchAvailability = $0 }
        )
    }

    private func runEngine(
        _ engine: some SummarizerEngine,
        setState: @escaping (EngineRunState) -> Void,
        setAvailability: @escaping (EngineAvailability) -> Void
    ) {
        let input = inputText
        let runDate = selectedDate
        let runID = UUID()
        activeRunID = runID
        setState(.running)
        summaryTask?.cancel()
        summaryTask = Task {
            do {
                let currentAvailability = await engine.availability
                try Task.checkCancellation()
                guard activeRunID == runID, selectedDate == runDate else { return }
                setAvailability(currentAvailability)
                if case let .unavailable(reason) = currentAvailability {
                    setState(.failure(reason))
                    return
                }
                let output = try await engine.summarize(input)
                try Task.checkCancellation()
                guard activeRunID == runID, selectedDate == runDate else { return }
                setState(.success(output))
            } catch is CancellationError {
                guard activeRunID == runID else { return }
                setState(.idle)
                summaryTask = nil
            } catch {
                guard activeRunID == runID, selectedDate == runDate else { return }
                setState(.failure(error.localizedDescription))
            }
        }
    }

    private func resetResults() {
        summaryTask?.cancel()
        summaryTask = nil
        activeRunID = nil
        runState = .idle
        execuTorchState = .idle
    }
}
