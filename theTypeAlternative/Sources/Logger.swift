import Foundation
import os.log

/// Optimized logging utility that only prints in debug builds
/// Reduces runtime overhead in release builds
struct Logger {
    
    // Performance logging - ONLY active in debug builds
    #if DEBUG
    static let performanceLogger = os.Logger(subsystem: "com.thetypealternative.performance", category: "AppCoordinator")
    #endif
    
    /// Log general debug information
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("🔍 [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }
    
    /// Log application lifecycle events
    static func lifecycle(_ message: String) {
        #if DEBUG
        print("📱 LIFECYCLE: \(message)")
        #endif
    }
    
    /// Log speech recognition events
    static func speech(_ message: String) {
        #if DEBUG
        print("🎤 SPEECH: \(message)")
        #endif
    }
    
    /// Log hotkey events
    static func hotkey(_ message: String) {
        #if DEBUG
        print("🎹 HOTKEY: \(message)")
        #endif
    }
    
    /// Log text insertion events
    static func textInsertion(_ message: String) {
        #if DEBUG
        print("📝 TEXT: \(message)")
        #endif
    }
    
    /// Log permission-related events
    static func permission(_ message: String) {
        #if DEBUG
        print("🔐 PERMISSION: \(message)")
        #endif
    }
    
    /// Log error conditions (always shown, even in release)
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("❌ ERROR [\(fileName):\(line)] \(function) - \(message)")
    }
    
    /// Log warning conditions (always shown, even in release)
    static func warning(_ message: String) {
        print("⚠️ WARNING: \(message)")
    }
    
    /// Log success conditions
    static func success(_ message: String) {
        #if DEBUG
        print("✅ SUCCESS: \(message)")
        #endif
    }
    
    /// Log performance-related information
    static func performance(_ message: String) {
        #if DEBUG
        print("⚡ PERFORMANCE: \(message)")
        performanceLogger.info("\(message)")
        #endif
    }
    
    /// Log timing measurements (detailed performance data)
    static func timing(_ message: String) {
        #if DEBUG
        print("⏱️ \(message)")
        #endif
    }
    
    /// Log engine/processing events
    static func engine(_ message: String) {
        #if DEBUG
        print("🤖 \(message)")
        #endif
    }
    
    /// Log model/AI related events
    static func model(_ message: String) {
        #if DEBUG
        print("🧠 \(message)")
        #endif
    }
    
    /// Log audio processing events
    static func audio(_ message: String) {
        #if DEBUG
        print("🔊 \(message)")
        #endif
    }
    
    /// Log transcription results
    static func transcription(_ message: String) {
        #if DEBUG
        print("📝 \(message)")
        #endif
    }
    
    /// Log UI/UX events
    static func ui(_ message: String) {
        #if DEBUG
        print("🖥️ \(message)")
        #endif
    }
    
    /// Log configuration/settings events
    static func config(_ message: String) {
        #if DEBUG
        print("🔧 \(message)")
        #endif
    }
    
    /// Log general processing events
    static func process(_ message: String) {
        #if DEBUG
        print("🔄 \(message)")
        #endif
    }
}

/// Utility for measuring execution time
struct PerformanceTimer {
    private let startTime: CFAbsoluteTime
    private let operation: String
    
    init(_ operation: String) {
        self.operation = operation
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func end() {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.performance("\(operation) took \(String(format: "%.3f", timeElapsed * 1000))ms")
    }
}