import SwiftUI
import AppKit
import SpeechKit

struct StorageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speechEngineManager: SpeechEngineManager
    @EnvironmentObject var paletteManager: PaletteManager
    
    @State private var showingCleanupConfirmation = false
    @State private var storageInfo: StorageInfo = StorageInfo()
    
    var body: some View {
        ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Storage Management")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Spacer()
                        }
                        
                        Text("Manage downloaded models and app storage")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    VStack(spacing: 24) {
                        // Storage Overview
                        SettingsDetailCard(title: "Storage Overview", icon: "chart.pie.fill") {
                            VStack(spacing: 20) {
                                // Total Usage
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total App Storage")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                                        
                                        Text("Application data and downloaded models")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatBytes(storageInfo.totalSize))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color.appAccent(from: paletteManager))
                                }
                                
                                // Storage Breakdown
                                VStack(spacing: 12) {
                                    StorageBreakdownRow(
                                        title: "Application",
                                        size: storageInfo.appSize,
                                        color: Color.appPrimary(from: paletteManager),
                                        icon: "app.fill"
                                    )
                                    
                                    StorageBreakdownRow(
                                        title: "Downloaded Models",
                                        size: storageInfo.modelsSize,
                                        color: Color.appAccent(from: paletteManager),
                                        icon: "cpu.fill"
                                    )
                                    
                                    StorageBreakdownRow(
                                        title: "Cache & Data",
                                        size: storageInfo.cacheSize,
                                        color: Color.appSecondary(from: paletteManager),
                                        icon: "folder.fill"
                                    )
                                }
                            }
                        }
                        
                        // Downloaded Models
                        SettingsDetailCard(title: "Downloaded Models", icon: "externaldrive.fill") {
                            VStack(spacing: 16) {
                                if storageInfo.downloadedModels.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "icloud.slash")
                                            .font(.system(size: 40, weight: .light))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.4))
                                        
                                        Text("No models downloaded")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                        
                                        Text("Models will appear here when downloaded from Speech Recognition settings")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.5))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.vertical, 20)
                                } else {
                                    ForEach(storageInfo.downloadedModels, id: \.name) { model in
                                        ModelStorageRow(model: model)
                                    }
                                }
                            }
                        }
                        
                        // Storage Actions
                        SettingsDetailCard(title: "Storage Actions", icon: "wrench.and.screwdriver.fill") {
                            VStack(spacing: 16) {
                                // Clean Up Models
                                StorageActionRow(
                                    title: "Clean Up Models",
                                    description: "Remove all downloaded WhisperKit models",
                                    icon: "trash.fill",
                                    actionText: "Clean Up",
                                    destructive: true,
                                    isEnabled: !storageInfo.downloadedModels.isEmpty
                                ) {
                                    showingCleanupConfirmation = true
                                }
                                
                                Divider()
                                    .opacity(0.3)
                                
                                // Refresh Storage Info
                                StorageActionRow(
                                    title: "Refresh Storage Info",
                                    description: "Update storage calculations",
                                    icon: "arrow.clockwise",
                                    actionText: "Refresh",
                                    destructive: false,
                                    isEnabled: true
                                ) {
                                    refreshStorageInfo()
                                }
                            }
                        }
                        
                        // Storage Information
                        SettingsDetailCard(title: "Storage Information", icon: "info.circle.fill") {
                            VStack(spacing: 16) {
                                InfoRow(
                                    title: "Application Location",
                                    value: Bundle.main.bundlePath,
                                    icon: "app.fill"
                                )
                                
                                InfoRow(
                                    title: "Models Location",
                                    value: getModelsPath(),
                                    icon: "folder.fill"
                                )
                                
                                InfoRow(
                                    title: "Automatic Cleanup",
                                    value: "Models are automatically removed when app is deleted",
                                    icon: "checkmark.shield.fill"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 32)
                }
        }
        .background(Color.appBackground(from: paletteManager))
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appPrimary(from: paletteManager))
                    .padding()
                }
                Spacer()
            }
        )
        .onAppear {
            refreshStorageInfo()
        }
        .alert("Clean Up Downloaded Models?", isPresented: $showingCleanupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clean Up", role: .destructive) {
                cleanUpModels()
            }
        } message: {
            Text("This will permanently delete all downloaded WhisperKit models to free up storage space. You can re-download them later if needed.\n\nThis action cannot be undone.")
        }
    }
    
    private func refreshStorageInfo() {
        Task { @MainActor in
            storageInfo = StorageInfo()
            
            // Get total models size
            storageInfo.modelsSize = speechEngineManager.modelManager.getDownloadedModelsSize()
            
            // Get downloaded models info
            storageInfo.downloadedModels = getDownloadedModelsInfo()
            
            // Calculate total
            storageInfo.totalSize = storageInfo.appSize + storageInfo.modelsSize + storageInfo.cacheSize
        }
    }
    
    private func getDownloadedModelsInfo() -> [ModelInfo] {
        // Get available models from the model manager
        let availableModels = WhisperModelPreference.allCases
        var models: [ModelInfo] = []
        
        for model in availableModels {
            if case .available = speechEngineManager.modelManager.modelStatuses[model.rawValue] {
                // Estimate model size based on model type
                let size = estimateModelSize(for: model)
                models.append(ModelInfo(
                    name: model.displayName,
                    size: size,
                    lastUsed: Date(), // Would be tracked in a real implementation
                    type: model.rawValue
                ))
            }
        }
        
        return models.sorted { $0.size > $1.size }
    }
    
    private func estimateModelSize(for model: WhisperModelPreference) -> UInt64 {
        // Rough estimates based on typical Whisper model sizes
        switch model {
        case .tiny:
            return 39 * 1024 * 1024  // ~39 MB
        case .base:
            return 142 * 1024 * 1024 // ~142 MB
        case .small:
            return 244 * 1024 * 1024 // ~244 MB
        case .medium:
            return 769 * 1024 * 1024 // ~769 MB
        }
    }
    
    private func getModelsPath() -> String {
        AppConfiguration.modelsDirectory?.path ?? ""
    }
    
    private func cleanUpModels() {
        speechEngineManager.modelManager.cleanupDownloadedModels()
        refreshStorageInfo()
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Views

struct StorageBreakdownRow: View {
    let title: String
    let size: UInt64
    let color: Color
    let icon: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager))
            
            Spacer()
            
            Text(formatBytes(size))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct ModelStorageRow: View {
    let model: ModelInfo
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Model Icon
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appAccent(from: paletteManager).opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appAccent(from: paletteManager))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text("Downloaded \(RelativeDateTimeFormatter().localizedString(for: model.lastUsed, relativeTo: Date()))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatBytes(model.size))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.appAccent(from: paletteManager))
                
                Text(model.type.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appOnSurface(from: paletteManager).opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface(from: paletteManager).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct StorageActionRow: View {
    let title: String
    let description: String
    let icon: String
    let actionText: String
    let destructive: Bool
    let isEnabled: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            }
            
            Spacer()
            
            Button(actionText) {
                action()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(buttonTextColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(buttonBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(buttonBorderColor, lineWidth: 1)
                    )
            )
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
    }
    
    private var iconColor: Color {
        if destructive {
            return Color.appError(from: paletteManager)
        } else {
            return Color.appAccent(from: paletteManager)
        }
    }
    
    private var buttonTextColor: Color {
        if destructive {
            return Color.appError(from: paletteManager)
        } else {
            return Color.appAccent(from: paletteManager)
        }
    }
    
    private var buttonBackgroundColor: Color {
        if destructive {
            return Color.appError(from: paletteManager).opacity(0.1)
        } else {
            return Color.appAccent(from: paletteManager).opacity(0.1)
        }
    }
    
    private var buttonBorderColor: Color {
        if destructive {
            return Color.appError(from: paletteManager).opacity(0.3)
        } else {
            return Color.appAccent(from: paletteManager).opacity(0.3)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

// MARK: - Data Models

struct StorageInfo {
    var totalSize: UInt64 = 0
    var appSize: UInt64 = 25 * 1024 * 1024 // Estimated ~25 MB for app
    var modelsSize: UInt64 = 0
    var cacheSize: UInt64 = 5 * 1024 * 1024 // Estimated ~5 MB for cache
    var downloadedModels: [ModelInfo] = []
}

struct ModelInfo {
    let name: String
    let size: UInt64
    let lastUsed: Date
    let type: String
}

// // #Preview {
//     StorageDetailView()
//         .environmentObject(SpeechEngineManager())
//         .environmentObject(PaletteManager())
//         .frame(width: 500, height: 800)
// }