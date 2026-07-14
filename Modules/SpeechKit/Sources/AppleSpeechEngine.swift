import Foundation
import Speech
import AVFoundation

// MARK: - Apple Speech Recognition Engine

/// Speech recognition engine using Apple's SpeechAnalyzer API (macOS 26+)
/// All processing happens on-device with the system's long-form transcription model.
/// Only microphone permission is required — SpeechAnalyzer needs no speech-recognition authorization.
@MainActor
public final class AppleSpeechEngine: SpeechRecognitionEngine {

    // MARK: - SpeechRecognitionEngine Protocol

    public let name = "System Speech"

    public var isAvailable: Bool {
        SpeechTranscriber.isAvailable
    }

    public let requiredPermissions: [SpeechPermissionType] = [.microphone]

    // MARK: - Configuration

    public struct Configuration {
        public let locale: Locale
        public let shouldReportPartialResults: Bool

        public init(
            locale: Locale = Locale(identifier: "en-US"),
            shouldReportPartialResults: Bool = true
        ) {
            self.locale = locale
            self.shouldReportPartialResults = shouldReportPartialResults
        }
    }

    private let configuration: Configuration

    // MARK: - Session State

    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var startTask: Task<Void, Never>?
    private weak var delegate: SpeechRecognitionEngineDelegate?
    private var isRecognitionActive = false
    private var isStopping = false

    // Transcript assembly: finalized results accumulate, the volatile tail is replaced on every update
    private var finalizedText = ""
    private var volatileText = ""
    private var lastConfidence: Double = 1.0

    // MARK: - Initialization

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        print("🍎 AppleSpeechEngine: Initialized (SpeechAnalyzer, locale \(configuration.locale.identifier))")
    }

    // MARK: - SpeechRecognitionEngine Implementation

    public func startRecognition(delegate: SpeechRecognitionEngineDelegate) throws {
        guard !isRecognitionActive else {
            print("⚠️ AppleSpeechEngine: Recognition already active")
            return
        }

        guard isAvailable else {
            print("❌ AppleSpeechEngine: SpeechTranscriber not available on this device")
            throw SpeechRecognitionEngineError.engineNotAvailable
        }

        self.delegate = delegate
        isRecognitionActive = true
        isStopping = false
        finalizedText = ""
        volatileText = ""
        lastConfidence = 1.0

        // Setup requires async work (asset checks, format negotiation) — run it in a task
        // and surface failures through the delegate.
        startTask = Task { [weak self] in
            await self?.beginSession()
        }
    }

    public func stopRecognition() {
        guard isRecognitionActive else {
            print("⚠️ AppleSpeechEngine: Recognition not active")
            return
        }

        print("🛑 AppleSpeechEngine: Stopping recognition")
        isRecognitionActive = false
        isStopping = true

        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Terminate the input sequence, then finish the analyzer and flush remaining finals
        inputContinuation?.finish()
        Task { [weak self] in
            await self?.finishSession()
        }
    }

    // MARK: - Session Lifecycle

    private func beginSession() async {
        do {
            guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: configuration.locale) else {
                throw SpeechRecognitionEngineError.initializationFailed(
                    "Locale \(configuration.locale.identifier) is not supported by SpeechTranscriber"
                )
            }

            let reportingOptions: Set<SpeechTranscriber.ReportingOption> =
                configuration.shouldReportPartialResults ? [.volatileResults, .fastResults] : []

            let transcriber = SpeechTranscriber(
                locale: locale,
                transcriptionOptions: [],
                reportingOptions: reportingOptions,
                attributeOptions: [.transcriptionConfidence]
            )
            self.transcriber = transcriber

            try await ensureAssetsInstalled(for: transcriber)

            // Session may have been stopped while assets were downloading
            guard isRecognitionActive else { return }

            let analyzer = SpeechAnalyzer(
                modules: [transcriber],
                options: .init(priority: .userInitiated, modelRetention: .processLifetime)
            )
            self.analyzer = analyzer

            guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
                throw SpeechRecognitionEngineError.initializationFailed(
                    "No compatible audio format available for the installed speech assets"
                )
            }

            // Consume results before feeding audio so nothing is missed
            resultsTask = Task { [weak self] in
                do {
                    for try await result in transcriber.results {
                        await self?.handleResult(result)
                    }
                } catch {
                    await self?.handleStreamError(error)
                }
            }

            let (inputSequence, continuation) = AsyncStream<AnalyzerInput>.makeStream()
            self.inputContinuation = continuation

            // The analyzer does not convert audio — convert tap buffers to the analyzer format.
            // The tap callback runs on AVFAudio's realtime queue, so it must be @Sendable:
            // without it the closure inherits @MainActor isolation from this method and the
            // runtime isolation check crashes (dispatch_assert_queue) on the audio thread.
            let converter = BufferConverter()
            let inputNode = audioEngine.inputNode
            let micFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: micFormat) { @Sendable buffer, _ in
                guard let converted = try? converter.convert(buffer, to: analyzerFormat) else { return }
                continuation.yield(AnalyzerInput(buffer: converted))
            }

            audioEngine.prepare()
            try audioEngine.start()

            try await analyzer.start(inputSequence: inputSequence)
            print("✅ AppleSpeechEngine: SpeechAnalyzer session started (locale: \(locale.identifier))")
        } catch {
            print("❌ AppleSpeechEngine: Failed to start session: \(error)")
            isRecognitionActive = false
            isStopping = false
            teardownSession()
            let engineError = (error as? SpeechRecognitionEngineError)
                ?? SpeechRecognitionEngineError.initializationFailed(error.localizedDescription)
            delegate?.speechEngine(self, didFailWithError: engineError)
        }
    }

    private func finishSession() async {
        // If the user stops immediately, wait for setup to settle first
        await startTask?.value

        if let analyzer = analyzer {
            do {
                try await analyzer.finalizeAndFinishThroughEndOfInput()
            } catch {
                print("⚠️ AppleSpeechEngine: finalize failed: \(error)")
            }
        }

        // The results stream terminates once the analyzer finishes — drain remaining finals
        await resultsTask?.value

        let fullText = (finalizedText + volatileText).trimmingCharacters(in: .whitespacesAndNewlines)
        let units = countWords(in: fullText)
        delegate?.speechEngine(self, didRecognizeText: fullText, processingUnits: units, isFinal: true, confidence: lastConfidence)
        print("✅ AppleSpeechEngine: Recognition stopped — final text delivered (\(units.count) words)")

        teardownSession()
        isStopping = false
    }

    private func teardownSession() {
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        inputContinuation = nil
        analyzer = nil
        transcriber = nil
        resultsTask = nil
        startTask = nil
    }

    // MARK: - Assets

    private func ensureAssetsInstalled(for transcriber: SpeechTranscriber) async throws {
        let status = await AssetInventory.status(forModules: [transcriber])
        guard status != .unsupported else {
            throw SpeechRecognitionEngineError.initializationFailed("Speech assets are not supported on this device")
        }

        if status < .installed,
           let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            print("⬇️ AppleSpeechEngine: Downloading speech model assets…")
            delegate?.speechEngine(self, didUpdateModelLoadingState: true, progress: 0.0)
            defer { delegate?.speechEngine(self, didUpdateModelLoadingState: false, progress: 1.0) }
            try await request.downloadAndInstall()
            print("✅ AppleSpeechEngine: Speech model assets installed")
        }
    }

    // MARK: - Results

    private func handleResult(_ result: SpeechTranscriber.Result) {
        let text = String(result.text.characters)
        if let confidence = result.text.runs.compactMap(\.transcriptionConfidence).last {
            lastConfidence = confidence
        }

        if result.isFinal {
            // A finalized result supersedes all volatile results for its audio range
            if !text.isEmpty {
                finalizedText += text
            }
            volatileText = ""
        } else {
            volatileText = text
        }

        // Live preview while recording; the combined final text is delivered from finishSession
        guard isRecognitionActive, !isStopping else { return }
        let displayText = finalizedText + volatileText
        delegate?.speechEngine(
            self,
            didRecognizeText: displayText,
            processingUnits: countWords(in: displayText),
            isFinal: false,
            confidence: lastConfidence
        )
    }

    private func handleStreamError(_ error: Error) {
        print("❌ AppleSpeechEngine: Results stream error: \(error)")
        guard isRecognitionActive else { return }
        isRecognitionActive = false
        isStopping = false
        teardownSession()
        delegate?.speechEngine(
            self,
            didFailWithError: SpeechRecognitionEngineError.recognitionFailed(error.localizedDescription)
        )
    }

    /// Count words in text using word boundaries
    /// More accurate than simple whitespace splitting
    private func countWords(in text: String) -> ProcessingUnit {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .words(0) }

        // Use NSString's word enumeration for accurate word counting
        var wordCount = 0

        trimmed.enumerateSubstrings(in: trimmed.startIndex..<trimmed.endIndex,
                                   options: [.byWords, .localized]) { _, _, _, _ in
            wordCount += 1
        }

        return .words(wordCount)
    }
}

// MARK: - Public Factory

extension AppleSpeechEngine {

    /// Create an Apple Speech Engine with default configuration
    public static func standard() -> AppleSpeechEngine {
        return AppleSpeechEngine(configuration: Configuration())
    }

    /// Create an Apple Speech Engine for a specific locale
    public static func forLocale(_ locale: Locale) -> AppleSpeechEngine {
        return AppleSpeechEngine(configuration: Configuration(locale: locale))
    }
}
