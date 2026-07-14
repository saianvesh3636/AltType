import Foundation

/// Centralized path constants for model storage
enum ModelPaths {

    // MARK: - Base Directories

    /// Application Support directory for the app
    static var appSupportDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("TheTypeAlternative")
    }

    /// Base directory for all speech recognition models
    static var modelsDirectory: URL? {
        appSupportDirectory?.appendingPathComponent("Models")
    }

    // MARK: - WhisperKit Model Paths

    /// Directory for WhisperKit models
    static var whisperKitModelsDirectory: URL? {
        modelsDirectory
    }

    /// Get path for a specific WhisperKit model
    static func whisperKitModelPath(for modelName: String) -> URL? {
        whisperKitModelsDirectory?.appendingPathComponent("openai_whisper-\(modelName)")
    }

    /// Ensure models directory exists
    static func ensureModelsDirectoryExists() {
        guard let modelsDir = modelsDirectory else { return }
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true, attributes: nil)
    }
}
