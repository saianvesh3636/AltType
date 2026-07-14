import Foundation

/// Dedicated logger for speech-to-text conversions
@MainActor
class SpeechLogger {
    static let shared = SpeechLogger()
    
    private var allSpeechEntries: [SpeechEntry] = [] // For debugging - includes partial results
    private var finalSpeechEntries: [SpeechEntry] = [] // For history - only final results
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        print("📝 SpeechLogger initialized")
    }
    
    /// Log a speech recognition result
    func logSpeechRecognition(text: String, isFinal: Bool, confidence: Double = 0.0) {
        // Only process and store final results to reduce noise
        guard isFinal else { return }
        
        let entry = SpeechEntry(
            text: text,
            isFinal: isFinal,
            confidence: confidence,
            timestamp: Date()
        )
        
        // Store final results in both collections
        allSpeechEntries.append(entry)
        finalSpeechEntries.append(entry)
        
        // Print to console with clear formatting - only final results
        let timestamp = dateFormatter.string(from: entry.timestamp)
        let confidenceText = confidence > 0 ? String(format: " (%.0f%%)", confidence * 100) : ""
        
        print("🗣️ SPEECH[FINAL] [\(timestamp)]\(confidenceText): \"\(text)\"")
        
        // Log completed conversion
        logCompletedConversion(text: text, timestamp: entry.timestamp)
    }
    
    /// Log a completed speech-to-text conversion
    private func logCompletedConversion(text: String, timestamp: Date) {
        let timestampString = dateFormatter.string(from: timestamp)
        
        print("✅ SPEECH_COMPLETED [\(timestampString)]: \"\(text)\"")
        print("📊 SPEECH_STATS: Final entries: \(finalSpeechEntries.count), All entries: \(allSpeechEntries.count)")
        
        // Also log to a persistent format that could be saved to file
        logToPersistentFormat(text: text, timestamp: timestamp)
    }
    
    /// Log in a format that could be easily saved to file
    private func logToPersistentFormat(text: String, timestamp: Date) {
        let timestampString = dateFormatter.string(from: timestamp)
        let logEntry = "[\(timestampString)] \(text)"
        
        print("💾 SPEECH_LOG_ENTRY: \(logEntry)")
    }
    
    /// Get all speech entries (including partial results for debugging)
    func getAllEntries() -> [SpeechEntry] {
        return allSpeechEntries
    }
    
    /// Get only final speech results (for history display)
    func getFinalEntries() -> [SpeechEntry] {
        return finalSpeechEntries
    }
    
    /// Print summary of all converted speech
    func printSpeechSummary() {
        let finalEntries = getFinalEntries()
        
        print("\n" + "="*60)
        print("📋 SPEECH CONVERSION SUMMARY")
        print("="*60)
        print("Total speech conversions: \(finalEntries.count)")
        print("Total entries (including partial): \(allSpeechEntries.count)")
        
        if finalEntries.isEmpty {
            print("No completed speech conversions yet.")
        } else {
            print("\nAll converted speech (most recent first):")
            for (index, entry) in finalEntries.reversed().enumerated() {
                let timestamp = dateFormatter.string(from: entry.timestamp)
                print("\(index + 1). [\(timestamp)] \"\(entry.text)\"")
            }
        }
        print("="*60 + "\n")
    }
    
    /// Clear all logged entries
    func clearHistory() {
        let previousAllCount = allSpeechEntries.count
        let previousFinalCount = finalSpeechEntries.count
        allSpeechEntries.removeAll()
        finalSpeechEntries.removeAll()
        print("🧹 SpeechLogger: Cleared \(previousAllCount) total entries (\(previousFinalCount) final)")
    }
}

/// Data structure for speech entries
struct SpeechEntry: Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Double
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// Helper for creating separator lines
private func *(left: String, right: Int) -> String {
    return String(repeating: left, count: right)
}