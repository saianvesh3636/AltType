import Foundation
import WhisperKit
import Combine

// MARK: - Model Status

public enum ModelStatus: Sendable {
    case notDownloaded
    case downloading(progress: Double)
    case available
    case failed(Error)
}

// MARK: - Model Manager Errors

public enum ModelManagerError: Error, LocalizedError {
    case fileSystemError(String)
    case modelNotFound(String)
    case downloadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .modelNotFound(let message):
            return "Model not found: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        }
    }
}

public struct ModelInfo {
    public let name: String
    public let size: String
    public let speedRating: Int
    public let accuracyRating: Int
    public let isBundled: Bool
    public let status: ModelStatus
    
    public init(name: String, size: String, speedRating: Int, accuracyRating: Int, isBundled: Bool, status: ModelStatus) {
        self.name = name
        self.size = size
        self.speedRating = speedRating
        self.accuracyRating = accuracyRating
        self.isBundled = isBundled
        self.status = status
    }
}

// MARK: - Model Manager

/// Manages WhisperKit model downloading, bundling, and availability
@MainActor
public final class ModelManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var modelStatuses: [String: ModelStatus] = [:]
    @Published public var downloadProgress: [String: Double] = [:]
    @Published public var isFirstRun: Bool = false
    
    // MARK: - Private Properties
    
    private let defaultModelName = "tiny"  // Default tiny model (39MB) for first-run
    private var downloadTasks: [String: Task<Void, Never>] = [:]
    
    // Available models with their specifications
    // Note: "large" model not available in WhisperKit - removed
    private let availableModels: [String: ModelInfo] = [
        "tiny": ModelInfo(name: "tiny", size: "39 MB", speedRating: 5, accuracyRating: 1, isBundled: false, status: .notDownloaded),
        "base": ModelInfo(name: "base", size: "74 MB", speedRating: 4, accuracyRating: 2, isBundled: false, status: .notDownloaded),
        "small": ModelInfo(name: "small", size: "244 MB", speedRating: 3, accuracyRating: 3, isBundled: false, status: .notDownloaded),
        "medium": ModelInfo(name: "medium", size: "769 MB", speedRating: 2, accuracyRating: 4, isBundled: false, status: .notDownloaded)
    ]
    
    // MARK: - Initialization
    
    public init() {
        // Check availability for all models
        for (modelName, _) in availableModels {
            modelStatuses[modelName] = checkModelAvailability(modelName)
        }
        
        print("🎯 ModelManager: Initialized - checking model availability")
        logModelStatuses()
        
        // Trigger first-run download if no models are available
        ensureDefaultModelAvailable()
    }
    
    // MARK: - Public Interface
    
    /// Check if a model is available for use
    public func isModelAvailable(_ modelName: String) -> Bool {
        switch modelStatuses[modelName] {
        case .available:
            return true
        default:
            return false
        }
    }
    
    /// Get model information
    public func getModelInfo(_ modelName: String) -> ModelInfo? {
        guard let modelInfo = availableModels[modelName] else { return nil }
        
        // Update with current status
        if let currentStatus = modelStatuses[modelName] {
            return ModelInfo(
                name: modelInfo.name,
                size: modelInfo.size,
                speedRating: modelInfo.speedRating,
                accuracyRating: modelInfo.accuracyRating,
                isBundled: modelInfo.isBundled,
                status: currentStatus
            )
        }
        
        return modelInfo
    }
    
    /// Get all available model information
    public func getAllModelInfo() -> [ModelInfo] {
        return availableModels.keys.compactMap { getModelInfo($0) }
    }
    
    /// Download a model if not available
    public func downloadModelIfNeeded(_ modelName: String) async {
        guard availableModels[modelName] != nil else {
            print("❌ ModelManager: Unknown model: \(modelName)")
            return
        }
        
        // If already available, no need to download
        if isModelAvailable(modelName) {
            print("✅ ModelManager: Model \(modelName) already available")
            return
        }
        
        // Check if already downloading
        if case .downloading = modelStatuses[modelName] {
            print("⏳ ModelManager: Model \(modelName) already downloading")
            return
        }
        
        await downloadModel(modelName)
    }
    
    /// Cancel model download
    public func cancelDownload(_ modelName: String) {
        downloadTasks[modelName]?.cancel()
        downloadTasks.removeValue(forKey: modelName)
        modelStatuses[modelName] = .notDownloaded
        downloadProgress.removeValue(forKey: modelName)
        
        print("🚫 ModelManager: Cancelled download for \(modelName)")
    }
    
    /// Reset model status from failed back to not downloaded (for retry)
    public func resetModelStatus(_ modelName: String) {
        // Cancel any ongoing downloads
        downloadTasks[modelName]?.cancel()
        downloadTasks.removeValue(forKey: modelName)
        
        // Reset status to not downloaded
        modelStatuses[modelName] = .notDownloaded
        downloadProgress.removeValue(forKey: modelName)
        
        print("🔄 ModelManager: Reset status for \(modelName) to not downloaded")
    }
    
    // MARK: - Private Methods
    
    /// Check if a model is already downloaded in the expected location
    private func checkModelAvailability(_ modelName: String) -> ModelStatus {
        // Priority 1: Check bundled models in app bundle
        if let bundledPath = getBundledModelPath(for: modelName),
           FileManager.default.fileExists(atPath: bundledPath.path) {
            print("✅ ModelManager: Found bundled model at \(bundledPath.path)")
            return .available
        }

        // Priority 2: Check app-managed download location (Application Support) - legacy
        if let appManagedPath = getAppManagedModelPath(for: modelName),
           FileManager.default.fileExists(atPath: appManagedPath.path) {
            print("✅ ModelManager: Found app-managed model at \(appManagedPath.path)")
            return .available
        }

        // Priority 3: Check WhisperKit's default Documents location
        // In sandboxed mode, app has automatic access to Documents folder
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let documentsURL = documentsURL {
            let whisperKitPath = documentsURL
                .appendingPathComponent("huggingface")
                .appendingPathComponent("models")
                .appendingPathComponent("argmaxinc")
                .appendingPathComponent("whisperkit-coreml")
                .appendingPathComponent("openai_whisper-\(modelName)")

            if FileManager.default.fileExists(atPath: whisperKitPath.path) {
                print("✅ ModelManager: Found WhisperKit model at \(whisperKitPath.path)")
                return .available
            }
        }

        return .notDownloaded
    }
    
    /// Download a model with progress tracking
    private func downloadModel(_ modelName: String) async {
        print("📥 ModelManager: Starting download for \(modelName)")

        // Update status to downloading
        await MainActor.run {
            self.modelStatuses[modelName] = .downloading(progress: 0.0)
            self.downloadProgress[modelName] = 0.0
        }

        // Create a download task that can be cancelled
        let downloadTask = Task { @MainActor in
            do {
                // Simulate download progress for better UX
                // WhisperKit doesn't provide progress callbacks, so we fake it
                for progress in stride(from: 0.0, through: 0.95, by: 0.05) {
                    guard !Task.isCancelled else {
                        self.modelStatuses[modelName] = .notDownloaded
                        self.downloadProgress.removeValue(forKey: modelName)
                        return
                    }

                    await MainActor.run {
                        self.modelStatuses[modelName] = .downloading(progress: progress)
                        self.downloadProgress[modelName] = progress
                    }

                    // Simulate download time based on model size
                    let sleepTime: UInt64
                    switch modelName {
                    case "medium":
                        sleepTime = 200_000_000  // 200ms
                    case "small":
                        sleepTime = 150_000_000  // 150ms
                    default:
                        sleepTime = 100_000_000  // 100ms for tiny/base
                    }
                    try? await Task.sleep(nanoseconds: sleepTime)
                }

                // Now actually download the model using WhisperKit
                print("📥 ModelManager: Downloading \(modelName) to ~/Documents/huggingface/models/")

                let _ = try await WhisperKit(WhisperKitConfig(
                    model: modelName,
                    modelRepo: "argmaxinc/whisperkit-coreml"
                ))

                await MainActor.run {
                    self.modelStatuses[modelName] = .available
                    self.downloadProgress.removeValue(forKey: modelName)
                    print("✅ ModelManager: Successfully downloaded \(modelName)")
                }
            } catch {
                await MainActor.run {
                    self.modelStatuses[modelName] = .failed(error)
                    self.downloadProgress.removeValue(forKey: modelName)
                    print("❌ ModelManager: Failed to download \(modelName): \(error)")
                }
            }
        }

        // Store task so it can be cancelled
        downloadTasks[modelName] = downloadTask
        await downloadTask.value
        downloadTasks.removeValue(forKey: modelName)
    }
    
    
    /// Get bundled model path (in app bundle)
    private func getBundledModelPath(for modelName: String) -> URL? {
        guard let bundleURL = Bundle.main.url(forResource: "openai_whisper-\(modelName)", withExtension: nil, subdirectory: "Models") else {
            return nil
        }
        return bundleURL
    }
    
    /// Get app-managed model storage path (in Application Support)
    private func getAppManagedModelPath(for modelName: String) -> URL? {
        return ModelPaths.whisperKitModelPath(for: modelName)
    }
    
    
    /// Get the best available model path for WhisperKit initialization
    public func getModelPath(for modelName: String) -> String? {
        // Priority order: bundled -> app-managed (Application Support)

        // Check bundled models first
        if let bundledPath = getBundledModelPath(for: modelName),
           FileManager.default.fileExists(atPath: bundledPath.path) {
            return bundledPath.path
        }

        // Check app-managed models in Application Support
        if let appManagedPath = getAppManagedModelPath(for: modelName),
           FileManager.default.fileExists(atPath: appManagedPath.path) {
            return appManagedPath.path
        }

        return nil
    }
    
    /// Get Application Support models folder for WhisperKit (legacy - for cleanup only)
    private func getAppSupportModelsFolder() -> URL? {
        // Ensure directory exists
        ModelPaths.ensureModelsDirectoryExists()
        return ModelPaths.modelsDirectory
    }
    
    // MARK: - Model Storage Management
    
    /// Clean up downloaded models (for app uninstall/reset)
    public func cleanupDownloadedModels() {
        var cleanedCount = 0

        // Clean up models in Application Support using centralized path
        guard let appModelsURL = ModelPaths.modelsDirectory else {
            print("❌ ModelManager: Could not access models directory")
            return
        }

        do {
            if FileManager.default.fileExists(atPath: appModelsURL.path) {
                let contents = try FileManager.default.contentsOfDirectory(at: appModelsURL, includingPropertiesForKeys: nil)
                for modelURL in contents {
                    try FileManager.default.removeItem(at: modelURL)
                    print("🗑️ ModelManager: Cleaned up model at \(modelURL.path)")
                    cleanedCount += 1
                }
                // Remove the Models directory itself
                try FileManager.default.removeItem(at: appModelsURL)
            }
        } catch {
            print("❌ ModelManager: Failed to cleanup models: \(error)")
        }

        print("✅ ModelManager: Cleaned up \(cleanedCount) downloaded models")

        // Refresh model availability after cleanup
        refreshModelAvailability()
    }
    
    /// Get total size of downloaded models
    public func getDownloadedModelsSize() -> UInt64 {
        var totalSize: UInt64 = 0

        // Check models in Application Support using centralized path
        guard let appModelsURL = ModelPaths.modelsDirectory else {
            return 0
        }

        if FileManager.default.fileExists(atPath: appModelsURL.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: appModelsURL, includingPropertiesForKeys: [.fileSizeKey])
                for modelURL in contents {
                    if modelURL.lastPathComponent.hasPrefix("openai_whisper-") {
                        let resources = try modelURL.resourceValues(forKeys: [.totalFileSizeKey])
                        if let size = resources.totalFileSize {
                            totalSize += UInt64(size)
                        }
                    }
                }
            } catch {
                print("❌ ModelManager: Failed to calculate models size: \(error)")
            }
        }

        return totalSize
    }
    
    // MARK: - Debugging
    
    private func logModelStatuses() {
        print("📋 ModelManager: Model Status Overview:")
        for (modelName, status) in modelStatuses {
            let statusText: String
            switch status {
            case .available:
                statusText = "✅ Available"
            case .notDownloaded:
                statusText = "❌ Not Downloaded"
            case .downloading(let progress):
                statusText = "⏳ Downloading (\(Int(progress * 100))%)"
            case .failed(let error):
                statusText = "❌ Failed: \(error.localizedDescription)"
            }
            
            print("   \(modelName): \(statusText)")
        }
    }
    
    /// Refresh model availability (useful after app updates or file system changes)
    public func refreshModelAvailability() {
        print("🔄 ModelManager: Refreshing model availability")
        
        for (modelName, _) in availableModels {
            modelStatuses[modelName] = checkModelAvailability(modelName)
        }
        
        logModelStatuses()
    }
    
    /// Ensure default model is available for first-run experience
    private func ensureDefaultModelAvailable() {
        // Check if any model is available
        let hasAnyModel = modelStatuses.values.contains { status in
            if case .available = status { return true }
            return false
        }
        
        if hasAnyModel {
            print("✅ ModelManager: At least one model already available")
            isFirstRun = false
            return
        }
        
        print("🚀 ModelManager: First-run detected - checking for bundled model or scheduling download")
        isFirstRun = true
        
        // First try to copy bundled model if available
        Task {
            if await copyBundledModelIfAvailable(defaultModelName) {
                print("✅ ModelManager: Bundled model copied successfully")
                await MainActor.run {
                    self.modelStatuses[self.defaultModelName] = .available
                    self.isFirstRun = false
                }
            } else {
                // No bundled model, download it
                await downloadModelIfNeeded(defaultModelName)
                await MainActor.run {
                    self.isFirstRun = false
                }
            }
        }
    }
    
    /// Copy bundled model to app-managed location
    private func copyBundledModelIfAvailable(_ modelName: String) async -> Bool {
        guard let bundledPath = getBundledModelPath(for: modelName),
              FileManager.default.fileExists(atPath: bundledPath.path) else {
            print("ℹ️ ModelManager: No bundled model found for \(modelName)")
            return false
        }
        
        guard let appManagedPath = getAppManagedModelPath(for: modelName) else {
            print("❌ ModelManager: Could not create app-managed path for \(modelName)")
            return false
        }
        
        do {
            // Remove existing model if it exists
            if FileManager.default.fileExists(atPath: appManagedPath.path) {
                try FileManager.default.removeItem(at: appManagedPath)
            }
            
            // Copy the bundled model to app-managed location
            try FileManager.default.copyItem(at: bundledPath, to: appManagedPath)
            
            print("📦 ModelManager: Copied bundled model from \(bundledPath.path) to \(appManagedPath.path)")
            return true
        } catch {
            print("❌ ModelManager: Failed to copy bundled model: \(error)")
            return false
        }
    }
}

// MARK: - Model Management Extensions

extension ModelManager {
    
    /// Get the best available model based on user preference
    public func getBestAvailableModel(preferredModel: String) -> String {
        // If preferred model is available, use it
        if isModelAvailable(preferredModel) {
            print("✅ ModelManager: Using preferred model '\(preferredModel)'")
            return preferredModel
        }
        
        print("⚠️ ModelManager: Preferred model '\(preferredModel)' not available")
        
        // Check if any model is available (prioritize in order of size/capability)
        let fallbackOrder = ["base", "tiny", "small", "medium"]
        for modelName in fallbackOrder {
            if isModelAvailable(modelName) {
                print("✅ ModelManager: Using fallback model '\(modelName)' instead of '\(preferredModel)'")
                return modelName
            }
        }
        
        // If no models are available, trigger download of preferred model and return it
        // WhisperKit will handle the download automatically when initialized
        print("📥 ModelManager: No models available, WhisperKit will download '\(preferredModel)' automatically")
        return preferredModel
    }
    
    /// Prepare model for use (download if needed, but don't block)
    public func prepareModel(_ modelName: String) {
        guard !isModelAvailable(modelName) else { return }
        
        Task {
            await downloadModelIfNeeded(modelName)
        }
    }
}