import SwiftUI
import SpeechKit
import AppServices

struct SpeechDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var speechEngineSettings: SpeechEngineSettings
    @EnvironmentObject var speechEngineManager: SpeechEngineManager
    @EnvironmentObject var paletteManager: PaletteManager
    @Environment(\.features) var features

    // Locales supported by Apple's SpeechTranscriber; WhisperKit follows the same selection
    private let recognitionLocales: [(id: String, name: String)] = [
        ("en-US", "English (US)"),
        ("en-GB", "English (UK)"),
        ("en-IN", "English (India)"),
        ("en-AU", "English (Australia)"),
        ("es-ES", "Spanish (Spain)"),
        ("es-MX", "Spanish (Mexico)"),
        ("fr-FR", "French"),
        ("de-DE", "German"),
        ("it-IT", "Italian"),
        ("pt-BR", "Portuguese (Brazil)"),
        ("ja-JP", "Japanese"),
        ("ko-KR", "Korean"),
        ("zh-CN", "Chinese (Simplified)")
    ]
    
    var body: some View {
        ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Speech Recognition")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Spacer()
                        }
                        
                        Text("Configure speech processing and language settings")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    VStack(spacing: 24) {
                        // Engine Selection
                        SettingsDetailCard(title: "Recognition Engine", icon: "brain.head.profile.fill") {
                            VStack(spacing: 16) {
                                ForEach(speechEngineSettings.availableEnginePreferences) { engine in
                                    EngineOptionRow(
                                        engine: engine,
                                        isSelected: speechEngineSettings.enginePreference == engine,
                                        action: {
                                            speechEngineSettings.enginePreference = engine
                                        }
                                    )
                                }
                            }
                        }

                        // Accuracy & Speed guidance
                        SettingsDetailCard(title: "Choosing for Accuracy & Speed", icon: "slider.horizontal.3") {
                            VStack(alignment: .leading, spacing: 12) {
                                GuidanceRow(
                                    icon: "waveform.circle",
                                    title: "System Speech (recommended)",
                                    detail: "Apple's on-device long-form model. Best balance of accuracy and speed, starts instantly, and handles long dictations without limits."
                                )
                                GuidanceRow(
                                    icon: "hare",
                                    title: "WhisperKit tiny / base",
                                    detail: "Fastest Whisper options with modest accuracy — fine for quick notes in clear audio."
                                )
                                GuidanceRow(
                                    icon: "tortoise",
                                    title: "WhisperKit small / medium",
                                    detail: "Noticeably better accuracy for heavy accents, technical vocabulary, and noisy rooms — at the cost of slower processing and larger downloads."
                                )
                                GuidanceRow(
                                    icon: "globe",
                                    title: "Language first",
                                    detail: "A mismatched recognition language hurts accuracy far more than any engine choice. Set it below to the language you actually speak."
                                )
                            }
                        }

                        // WhisperKit Model Selection (only show when WhisperKit is preferred and supported)
                        if features.supportsWhisperKit && speechEngineSettings.enginePreference == .whisperKit {
                            SettingsDetailCard(title: "WhisperKit Model", icon: "cpu.fill") {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Current Model")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager))

                                        Spacer()

                                        Text(speechEngineSettings.whisperModelPreference.sizeInfo)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.appAccent(from: paletteManager).opacity(0.15))
                                            )
                                    }

                                    ForEach(speechEngineSettings.availableWhisperModels) { model in
                                        WhisperModelRow(
                                            model: model,
                                            isSelected: speechEngineSettings.whisperModelPreference == model,
                                            modelManager: speechEngineManager.modelManager,
                                            action: {
                                                speechEngineSettings.whisperModelPreference = model
                                            }
                                        )
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.3), value: speechEngineSettings.enginePreference == .whisperKit)
                        }
                        
                        // Audio & Language Settings
                        SettingsDetailCard(title: "Audio & Language", icon: "waveform.and.mic") {
                            VStack(spacing: 20) {
                                // Language Selection
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recognition Language")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.appOnSurface(from: paletteManager))

                                    Text("Applies to both engines. Matching this to the language you speak matters more for accuracy than any other setting.")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))

                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(recognitionLocales, id: \.id) { locale in
                                            LanguageOptionButton(
                                                language: locale.name,
                                                isSelected: speechEngineSettings.selectedLocaleIdentifier == locale.id,
                                                action: {
                                                    speechEngineSettings.selectedLocaleIdentifier = locale.id
                                                }
                                            )
                                        }
                                    }
                                }
                                
                                Divider()
                                    .opacity(0.3)
                                
                                // Sound Feedback
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sound Feedback")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                                        
                                        Text("Play sounds when starting and stopping")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $speechEngineSettings.enableSounds)
                                        .toggleStyle(ModernToggleStyle())
                                }
                                
                                // Silence Timeout
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Silence Timeout")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                                        
                                        Spacer()
                                        
                                        Text("\(Int(speechEngineSettings.silenceTimeout))s")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.appAccent(from: paletteManager))
                                    }
                                    
                                    Slider(value: $speechEngineSettings.silenceTimeout, in: 5...60, step: 1)
                                        .tint(Color.appPrimary(from: paletteManager))
                                    
                                    Text("Automatically stop listening after silence")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                }
                            }
                        }
                        
                        // Privacy Information
                        SettingsDetailCard(title: "Privacy", icon: "lock.shield.fill") {
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(Color.appSuccess(from: paletteManager))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("On-Device Processing")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                                        
                                        Text("All speech recognition happens locally on your device. No data is sent to external servers.")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(Color.appAccent(from: paletteManager))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("No Audio Storage")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                                        
                                        Text("Audio is processed in real-time and immediately discarded. Nothing is saved or stored.")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                }
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
    }
}

struct EngineOptionRow: View {
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
                    .frame(width: 48, height: 48)
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        .multilineTextAlignment(.leading)
                    
                    // Performance indicators
                    HStack(spacing: 16) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.08) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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

struct WhisperModelRow: View {
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
                            
                            Spacer()
                            
                            modelStatusIndicator
                        }
                        
                        Text(model.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            .multilineTextAlignment(.leading)
                        
                        // Performance and size info
                        HStack(spacing: 20) {
                            performanceIndicator(title: "Speed", rating: model.speedRating)
                            performanceIndicator(title: "Accuracy", rating: model.accuracyRating)
                            
                            Spacer()
                            
                            Text(model.sizeInfo)
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
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.appSuccess(from: paletteManager))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.08) : Color.appSurface(from: paletteManager))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Download/management controls
            if case .notDownloaded = modelManager.modelStatuses[model.rawValue] {
                downloadButton
            } else if case .downloading(let progress) = modelManager.modelStatuses[model.rawValue] {
                downloadProgressView(progress: progress)
            } else if case .failed(let error) = modelManager.modelStatuses[model.rawValue] {
                errorView(error: error)
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
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
                Text("Download")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
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
        HStack {
            Spacer()
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
                    .fill(Color.appAccent(from: paletteManager).opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appAccent(from: paletteManager).opacity(0.3), lineWidth: 1)
                    )
            )
            Spacer()
        }
        .padding(.top, 12)
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
        .padding(.horizontal, 16)
        .padding(.top, 12)
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
        .padding(.horizontal, 16)
        .padding(.top, 12)
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

struct GuidanceRow: View {
    let icon: String
    let title: String
    let detail: String
    @EnvironmentObject var paletteManager: PaletteManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))

                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

struct LanguageOptionButton: View {
    let language: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            Text(language)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.appOnSurface(from: paletteManager))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.appPrimary(from: paletteManager) : Color.appSurface(from: paletteManager).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.appPrimary(from: paletteManager) : Color.appOnSurface(from: paletteManager).opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extension for engine performance ratings
extension SpeechEnginePreference {
    var speedRating: Int {
        switch self {
        case .auto: return 4
        case .whisperKit: return 3
        case .appleSpeech: return 5
        }
    }
    
    var accuracyRating: Int {
        switch self {
        case .auto: return 4
        case .whisperKit: return 5
        case .appleSpeech: return 3
        }
    }
}

// // #Preview {
//     SpeechDetailView()
//         .environmentObject(SpeechEngineSettings())
//         .environmentObject(SpeechEngineManager())
//         .environmentObject(PaletteManager())
//         .frame(width: 500, height: 800)
// }