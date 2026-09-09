import SwiftData
import SwiftUI

/// 選択した日付のライフログをFoundation Modelsで要約するタブ。
struct SummaryTab: View {
    let seedError: String?

    @Query(sort: \LogEntry.createdAt) private var entries: [LogEntry]
    @State private var selectedDate: Date?
    @State private var runState: EngineRunState = .idle
    @State private var availability: EngineAvailability?
    @State private var activeRunID: UUID?
    @State private var summaryTask: Task<Void, Never>?

    private let engine = FoundationModelsSummarizer()

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
                    availability: availability,
                    runFoundationModels: runFoundationModels
                )

                Section("結果") {
                    ResultCard(engineName: engine.name, state: runState)
                }
            }
            .navigationTitle("要約")
            .task { availability = await engine.availability }
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

    private var isRunDisabled: Bool { inputText.isEmpty || runState.isRunning }

    private func selectFirstDateIfNeeded() {
        if selectedDate == nil || selectedEntries.isEmpty { selectedDate = availableDates.first }
    }

    private func runFoundationModels() {
        let input = inputText
        let runDate = selectedDate
        let runID = UUID()
        activeRunID = runID
        runState = .running
        summaryTask?.cancel()
        summaryTask = Task {
            do {
                let currentAvailability = await engine.availability
                try Task.checkCancellation()
                guard activeRunID == runID, selectedDate == runDate else { return }
                availability = currentAvailability
                if case let .unavailable(reason) = currentAvailability {
                    runState = .failure(reason)
                    return
                }
                runState = .success(try await engine.summarize(input))
            } catch is CancellationError {
                return
            } catch {
                guard activeRunID == runID, selectedDate == runDate else { return }
                runState = .failure(error.localizedDescription)
            }
        }
    }

    private func resetResults() {
        summaryTask?.cancel()
        summaryTask = nil
        activeRunID = nil
        runState = .idle
    }
}
