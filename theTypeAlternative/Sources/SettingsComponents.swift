import SwiftUI
import AppServices
import SpeechKit

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .foregroundColor(Color.appOnSurface(from: paletteManager))
            
            VStack(alignment: .leading, spacing: 0) {
                content
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: Content
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                if !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                }
            }
            
            Spacer()
            
            content
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Toggle Settings Row

struct ToggleSettingsRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let action: (() -> Void)?
    @EnvironmentObject var paletteManager: PaletteManager
    
    init(title: String, description: String, isOn: Binding<Bool>, action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.appPrimary(from: paletteManager)))
                .onChange(of: isOn) { _, _ in
                    action?()
                }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Slider Settings Row

struct SliderSettingsRow: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                }
                
                Spacer()
                
                Text("\(Int(value))\(suffix)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appAccent(from: paletteManager))
                    .frame(minWidth: 40)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(Color.appPrimary(from: paletteManager))
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Theme Selection Row

struct ThemeSelectionRow: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme Icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeGradient)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeIconColor)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(mode.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.appSuccess(from: paletteManager))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var themeGradient: LinearGradient {
        switch mode {
        case .light:
            return LinearGradient(colors: [.white, Color.gray.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [Color.black, Color.gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .system:
            return LinearGradient(colors: [.white, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var themeIconColor: Color {
        switch mode {
        case .light:
            return .black.opacity(0.8)
        case .dark:
            return .white
        case .system:
            return Color.appOnSurface(from: paletteManager)
        }
    }
}

// MARK: - Color Palette Selection Row

struct ColorPaletteSelectionRow: View {
    let palette: PaletteOption
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Color Preview
                HStack(spacing: 8) {
                    let paletteColors = palette.createPalette()
                    
                    ForEach(0..<3) { index in
                        let color = [paletteColors.primary.light, paletteColors.secondary.light, paletteColors.accent.light][index]
                        Circle()
                            .fill(Color(color))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSurface(from: paletteManager).opacity(0.3))
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(palette.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(palette.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.appSuccess(from: paletteManager))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Engine Selection Row

struct EngineSelectionRow: View {
    let engine: SpeechEnginePreference
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Engine Icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(engineColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: engine.systemImage)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(engineColor)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(engine.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(engine.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        .multilineTextAlignment(.leading)
                    
                    // Performance indicators
                    HStack(spacing: 20) {
                        performanceIndicator(title: "Speed", rating: engine.speedRating)
                        performanceIndicator(title: "Accuracy", rating: engine.accuracyRating)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.appSuccess(from: paletteManager))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var engineColor: Color {
        switch engine {
        case .auto:
            return Color.appPrimary(from: paletteManager)
        case .whisperKit:
            return Color.appAccent(from: paletteManager)
        case .appleSpeech:
            return Color.appSecondary(from: paletteManager)
        }
    }
    
    @ViewBuilder
    private func performanceIndicator(title: String, rating: Int) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= rating ? Color.appAccent(from: paletteManager) : Color.appOnSurface(from: paletteManager).opacity(0.2))
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}

// MARK: - WhisperKit Model Selection Row

struct WhisperModelSelectionRow: View {
    let model: WhisperModelPreference
    let isSelected: Bool
    @ObservedObject var modelManager: ModelManager
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(model.displayName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Text(model.sizeInfo)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.appOnSurface(from: paletteManager).opacity(0.1))
                                )
                            
                            Spacer()
                            
                            modelStatusIndicator
                        }
                        
                        Text(model.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            .multilineTextAlignment(.leading)
                        
                        // Performance indicators
                        HStack(spacing: 20) {
                            performanceIndicator(title: "Speed", rating: model.speedRating)
                            performanceIndicator(title: "Accuracy", rating: model.accuracyRating)
                        }
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.appSuccess(from: paletteManager))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.05) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: isSelected ? 2 : 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Download/management controls
            if case .notDownloaded = modelManager.modelStatuses[model.rawValue] {
                downloadButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else if case .downloading(let progress) = modelManager.modelStatuses[model.rawValue] {
                downloadProgressView(progress: progress)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else if case .failed(let error) = modelManager.modelStatuses[model.rawValue] {
                errorView(error: error)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
    
    @ViewBuilder
    private var modelStatusIndicator: some View {
        switch modelManager.modelStatuses[model.rawValue] {
        case .available:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appSuccess(from: paletteManager))
                Text("Ready")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appSuccess(from: paletteManager))
            }
            
        case .notDownloaded:
            HStack(spacing: 4) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appAccent(from: paletteManager))
                Text("Download")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appAccent(from: paletteManager))
            }
            
        case .downloading(let progress):
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appAccent(from: paletteManager))
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appAccent(from: paletteManager))
            }
            
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appError(from: paletteManager))
                Text("Failed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appError(from: paletteManager))
            }
            
        case .none:
            EmptyView()
        }
    }
    
    private var downloadButton: some View {
        Button("Download Model") {
            Task {
                await modelManager.downloadModelIfNeeded(model.rawValue)
            }
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(Color.appAccent(from: paletteManager))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appAccent(from: paletteManager).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appAccent(from: paletteManager).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func downloadProgressView(progress: Double) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Downloading...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appAccent(from: paletteManager))
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appAccent(from: paletteManager))
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.appAccent(from: paletteManager)))
            
            Button("Cancel") {
                modelManager.cancelDownload(model.rawValue)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.appError(from: paletteManager))
        }
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 8) {
            Text("Download failed: \(error.localizedDescription)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appError(from: paletteManager))
                .multilineTextAlignment(.center)
            
            HStack {
                Button("Retry") {
                    Task {
                        await modelManager.downloadModelIfNeeded(model.rawValue)
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appAccent(from: paletteManager).opacity(0.15))
                )
                
                Button("Clear") {
                    modelManager.resetModelStatus(model.rawValue)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            }
        }
    }
    
    @ViewBuilder
    private func performanceIndicator(title: String, rating: Int) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= rating ? Color.appAccent(from: paletteManager) : Color.appOnSurface(from: paletteManager).opacity(0.2))
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}

// MARK: - Settings Permission Row

struct SettingsPermissionRow: View {
    let title: String
    let description: String
    let icon: String
    let state: PermissionState
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                statusIndicator
                
                if state != .granted && state != .requesting {
                    Button(state == .unknown ? "Enable" : "Settings") {
                        action()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor)
                    )
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor)
            
            Text(state.displayText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .granted: return Color.appSuccess(from: paletteManager)
        case .denied, .restricted: return Color.appError(from: paletteManager)
        case .requesting: return Color.appAccent(from: paletteManager)
        case .unknown: return Color.appOnSurface(from: paletteManager).opacity(0.6)
        }
    }
    
    private var statusIcon: String {
        switch state {
        case .granted: return "checkmark.circle.fill"
        case .denied, .restricted: return "exclamationmark.triangle.fill"
        case .requesting: return "clock.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}