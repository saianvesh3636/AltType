import SwiftUI
import SpeechKit

// MARK: - Theme Selection Button

struct ThemeSelectionButton: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme Icon with Preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeIconColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(mode.description)
                        .font(.system(size: 14, weight: .medium))
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
            .frame(maxWidth: .infinity, alignment: .leading) // 1. Set the frame to fill the width
            .contentShape(Rectangle())                      // 2. Define the entire frame as tappable
            .padding(.horizontal, 16)                       // 3. Now, add your padding
            .padding(.vertical, 12)
            .background(                                    // 4. Finally, apply the background
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.08) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1.5)
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
            return LinearGradient(colors: [Color.black, Color.gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
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

// MARK: - Color Palette Button

struct ColorPaletteButton: View {
    let palette: PaletteOption
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Color Preview
                HStack(spacing: 6) {
                    let paletteColors = palette.createPalette()
                    
                    ForEach(0..<3) { index in
                        let color = [paletteColors.primary.light, paletteColors.secondary.light, paletteColors.accent.light][index]
                        Circle()
                            .fill(Color(color))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appOnSurface(from: paletteManager).opacity(0.05))
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(palette.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(palette.description)
                        .font(.system(size: 14, weight: .medium))
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
            .frame(maxWidth: .infinity, alignment: .leading) // 1. Set the frame to fill the width
            .contentShape(Rectangle())                      // 2. Define the entire frame as tappable
            .padding(.horizontal, 16)                       // 3. Now, add your padding
            .padding(.vertical, 12)
            .background(                                    // 4. Finally, apply the background
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.08) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Engine Option Button

struct EngineOptionButton: View {
    let engine: SpeechEnginePreference
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Engine Icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(engineColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: engine.systemImage)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(engineColor)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(engine.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(engine.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    
                    // Performance indicators
                    HStack(spacing: 16) {
                        performanceIndicator(title: "Speed", rating: engine.speedRating)
                        performanceIndicator(title: "Accuracy", rating: engine.accuracyRating)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.appAccent(from: paletteManager))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.appAccent(from: paletteManager).opacity(0.1) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.appAccent(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
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

// MARK: - Model Option Button

struct ModelOptionButton: View {
    let model: WhisperModelPreference
    let isSelected: Bool
    @ObservedObject var modelManager: ModelManager
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
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
                        
                        // Show progress or error states inline
                        if case .downloading(let progress) = modelManager.modelStatuses[model.rawValue] {
                            downloadProgressView(progress: progress)
                        } else if case .failed(let error) = modelManager.modelStatuses[model.rawValue] {
                            errorView(error: error)
                        }
                        
                        // Performance indicators
                        HStack(spacing: 16) {
                            performanceIndicator(title: "Speed", rating: model.speedRating)
                            performanceIndicator(title: "Accuracy", rating: model.accuracyRating)
                        }
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.appAccent(from: paletteManager))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.appAccent(from: paletteManager).opacity(0.1) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.appAccent(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
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
            Button {
                Task {
                    await modelManager.downloadModelIfNeeded(model.rawValue)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appAccent(from: paletteManager))
                    Text("Download")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.appAccent(from: paletteManager))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appAccent(from: paletteManager).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.appAccent(from: paletteManager).opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
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
            Button {
                Task {
                    await modelManager.downloadModelIfNeeded(model.rawValue)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appError(from: paletteManager))
                    Text("Retry")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.appError(from: paletteManager))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appError(from: paletteManager).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.appError(from: paletteManager).opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
        case .none:
            EmptyView()
        }
    }
    
    
    private func downloadProgressView(progress: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("Downloading...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.appAccent(from: paletteManager))
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appAccent(from: paletteManager))
                
                Button("Cancel") {
                    modelManager.cancelDownload(model.rawValue)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.appError(from: paletteManager))
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.appAccent(from: paletteManager)))
                .scaleEffect(y: 0.8)
        }
    }
    
    private func errorView(error: Error) -> some View {
        HStack {
            Text("Download failed")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appError(from: paletteManager))
            
            Spacer()
            
            Button("Clear") {
                modelManager.resetModelStatus(model.rawValue)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
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

// Extensions moved to SettingsExtensions.swift to avoid duplicates

// // #Preview {
//     VStack(spacing: 20) {
//         ThemeSelectionButton(
//             mode: .dark,
//             isSelected: true
//         ) {}
//         
//         ColorPaletteButton(
//             palette: .arcticMinimalist,
//             isSelected: false
//         ) {}
//     }
//     .environmentObject(PaletteManager())
//     .padding()
// }