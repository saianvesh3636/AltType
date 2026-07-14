import Foundation

enum AppConfiguration {
    static let appName = "AltType"
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"

    // MARK: - File Paths

    /// Application Support directory for the app
    static var appSupportDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("TheTypeAlternative")
    }

    /// Base directory for all speech recognition models
    static var modelsDirectory: URL? {
        appSupportDirectory?.appendingPathComponent("Models")
    }

    /// Directory for WhisperKit models specifically
    static var whisperKitModelsDirectory: URL? {
        modelsDirectory?.appendingPathComponent("WhisperKit")
    }

    /// Get path for a specific WhisperKit model
    static func whisperKitModelPath(for modelName: String) -> URL? {
        whisperKitModelsDirectory?.appendingPathComponent("openai_whisper-\(modelName)")
    }
}

extension AppConfiguration {
    /// Build number as an integer
    static var buildNumber: Int {
        Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)!
    }
}
