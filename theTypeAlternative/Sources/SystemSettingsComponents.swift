import SwiftUI
import AppServices
import SpeechKit

// MARK: - System Settings Section (Updated to match previous SettingsCard style)

struct SystemSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @EnvironmentObject var paletteManager: PaletteManager
    
    init(title: String, icon: String = "gear", @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header with Icon
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.appPrimary(from: paletteManager))
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
            }
            
            // Section Content
            VStack(spacing: 1) {
                content
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface(from: paletteManager))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appOnSurface(from: paletteManager).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - System Settings Row

struct SystemSettingsRow<Content: View>: View {
    let isButton: Bool
    @ViewBuilder let content: Content
    @EnvironmentObject var paletteManager: PaletteManager
    
    init(isButton: Bool = false, @ViewBuilder content: () -> Content) {
        self.isButton = isButton
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)  // Expand to full width
            .contentShape(Rectangle())  // Make entire area clickable
            .background(
                Rectangle()
                    .fill(Color.clear)
            )
            .overlay(
                // Bottom border (except for last item) - more subtle
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.appOnSurface(from: paletteManager).opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.leading, 16)
                }
            )
    }
}

// MARK: - Permission Status Row

struct PermissionStatusRow: View {
    let title: String
    let description: String
    let state: PermissionState
    let icon: String
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Status Indicator
                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                    
                    Text(state.displayText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(statusColor)
                }
                
                // Action Button
                if state != .granted && state != .requesting {
                    Button(state == .unknown ? "Enable" : "Settings") {
                        action()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor)
                    )
                    .disabled(state == .requesting)
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .granted: return .green  // Always green for granted permissions
        case .denied, .restricted: return .red  // Always red for denied permissions
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

// MARK: - Modal Sheet Views

struct AppearanceConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        ZStack {
            // Background overlay to catch clicks outside the modal
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
            // Header
            HStack {
                Text("Appearance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appAccent(from: paletteManager), lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appSurface(from: paletteManager))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                // Theme Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Theme")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    VStack(spacing: 8) {
                        ForEach(AppearanceMode.allCases) { mode in
                            ThemeSelectionButton(
                                mode: mode,
                                isSelected: appearanceSettings.preferredMode == mode
                            ) {
                                appearanceSettings.preferredMode = mode
                            }
                        }
                    }
                }
                
                Divider()
                
                // Color Palette Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Color Palette")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    VStack(spacing: 8) {
                        ForEach(PaletteOption.allCases) { palette in
                            ColorPaletteButton(
                                palette: palette,
                                isSelected: paletteManager.selectedPalette == palette
                            ) {
                                paletteManager.selectedPalette = palette
                            }
                        }
                    }
                }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            }
        }
        .frame(maxWidth: 600, maxHeight: 600)
        .frame(minWidth: 500)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.appBackground(from: paletteManager))
    }
}

struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    // Simple list view for currently supported languages
    // TODO: When expanding language support, uncomment the grouped version below
    /*
    // Computed property to group languages by region (for future use)
    private var groupedLanguages: [(String, [String])] {
        [
            ("English", expandedLanguages.filter { $0.hasPrefix("English") }),
            ("European", expandedLanguages.filter { 
                !["English", "Chinese", "Arabic", "Hebrew", "Persian", "Swahili", "Amharic", "Hindi", "Urdu", "Bengali", "Tamil", "Telugu", "Marathi", "Gujarati", "Kannada", "Malayalam", "Punjabi", "Nepali", "Japanese", "Korean", "Thai", "Vietnamese", "Indonesian", "Malay"].contains { $0.hasPrefix($0) } &&
                !["Portuguese (Brazil)", "Spanish (Mexico)", "Spanish (Argentina)", "French (Canada)"].contains($0) &&
                (europeanLanguages.contains($0))
            }),
            ("Asian", expandedLanguages.filter { asianLanguages.contains($0) }),
            ("Middle Eastern & African", expandedLanguages.filter { middleEasternAfricanLanguages.contains($0) }),
            ("Americas (Regional)", expandedLanguages.filter { americasLanguages.contains($0) })
        ]
    }
    
    private let europeanLanguages = Set([
        "Spanish", "French", "German", "Italian", "Portuguese", "Dutch", "Russian", "Polish",
        "Swedish", "Norwegian", "Danish", "Finnish", "Czech", "Hungarian", "Romanian",
        "Ukrainian", "Greek", "Turkish", "Croatian", "Slovak", "Bulgarian", "Lithuanian"
    ])
    
    private let asianLanguages = Set([
        "Chinese (Simplified)", "Chinese (Traditional)", "Japanese", "Korean", "Thai", "Vietnamese",
        "Indonesian", "Malay", "Hindi", "Urdu", "Bengali", "Tamil", "Telugu", "Marathi",
        "Gujarati", "Kannada", "Malayalam", "Punjabi", "Nepali"
    ])
    
    private let middleEasternAfricanLanguages = Set([
        "Arabic", "Hebrew", "Persian (Farsi)", "Swahili", "Amharic"
    ])
    
    private let americasLanguages = Set([
        "Portuguese (Brazil)", "Spanish (Mexico)", "Spanish (Argentina)", "French (Canada)"
    ])
    */
    
    // Currently supported languages
    private let languages = [
        "English (US)", "English (UK)", "Spanish", "French", 
        "German", "Italian", "Portuguese", "Japanese", "Chinese"
    ]
    
    // TODO: Expand language support - uncomment when adding more language support
    /*
    private let expandedLanguages = [
        // English variants
        "English (US)", "English (UK)", "English (Canada)", "English (Australia)",
        
        // European languages
        "Spanish", "French", "German", "Italian", "Portuguese", "Dutch", "Russian", "Polish",
        "Swedish", "Norwegian", "Danish", "Finnish", "Czech", "Hungarian", "Romanian",
        "Ukrainian", "Greek", "Turkish", "Croatian", "Slovak", "Bulgarian", "Lithuanian",
        
        // Asian languages
        "Chinese (Simplified)", "Chinese (Traditional)", "Japanese", "Korean", "Thai", "Vietnamese",
        "Indonesian", "Malay", "Hindi", "Urdu", "Bengali", "Tamil", "Telugu", "Marathi",
        "Gujarati", "Kannada", "Malayalam", "Punjabi", "Nepali",
        
        // Middle Eastern & African
        "Arabic", "Hebrew", "Persian (Farsi)", "Swahili", "Amharic",
        
        // Americas
        "Portuguese (Brazil)", "Spanish (Mexico)", "Spanish (Argentina)", "French (Canada)"
    ]
    */
    
    var body: some View {
        ZStack {
            // Background overlay to catch clicks outside the modal
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
            // Header
            HStack {
                Text("Language")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appAccent(from: paletteManager), lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appSurface(from: paletteManager))
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(languages, id: \.self) { language in
                        Button(action: {
                            selectedLanguage = language
                            UserDefaults.standard.set(language, forKey: "SelectedLanguage")
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Text(language)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if selectedLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.appAccent(from: paletteManager))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Rectangle()
                                    .fill(selectedLanguage == language ? 
                                          Color.appAccent(from: paletteManager).opacity(0.1) : 
                                          Color.clear)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if language != languages.last {
                            Divider()
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 200, maxHeight: 400)
            }
        }
        .frame(maxWidth: 450, maxHeight: 500)
        .frame(minWidth: 380, minHeight: 300)
        .background(Color.appBackground(from: paletteManager))
    }
}

struct EngineSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speechEngineSettings: SpeechEngineSettings
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        ZStack {
            // Background overlay to catch clicks outside the modal
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recognition Engine")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appAccent(from: paletteManager), lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appSurface(from: paletteManager))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                ForEach(SpeechEnginePreference.allCases) { engine in
                    EngineOptionButton(
                        engine: engine,
                        isSelected: speechEngineSettings.enginePreference == engine
                    ) {
                        speechEngineSettings.enginePreference = engine
                    }
                }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            }
        }
        .frame(maxWidth: 520, maxHeight: 500)
        .frame(minWidth: 450)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.appBackground(from: paletteManager))
    }
}

struct ModelManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speechEngineSettings: SpeechEngineSettings
    @EnvironmentObject var speechEngineManager: SpeechEngineManager
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        ZStack {
            // Background overlay to catch clicks outside the modal
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
            // Header
            HStack {
                Text("WhisperKit Model")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appAccent(from: paletteManager), lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appSurface(from: paletteManager))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Choose the WhisperKit model that best fits your needs. Larger models provide better accuracy but require more storage and processing power.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.8))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 16) {
                    ForEach(WhisperModelPreference.allCases) { model in
                        ModelOptionButton(
                            model: model,
                            isSelected: speechEngineSettings.whisperModelPreference == model,
                            modelManager: speechEngineManager.modelManager
                        ) {
                            speechEngineSettings.whisperModelPreference = model
                        }
                    }
                }
                
                Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            }
        }
        .frame(maxWidth: 580, maxHeight: 600)
        .frame(minWidth: 500)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.appBackground(from: paletteManager))
    }
}

struct StorageManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speechEngineManager: SpeechEngineManager
    @EnvironmentObject var paletteManager: PaletteManager
    @State private var showingCleanupConfirmation = false
    
    var body: some View {
        ZStack {
            // Background overlay to catch clicks outside the modal
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
            // Header
            HStack {
                Text("Storage")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.appAccent(from: paletteManager))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appAccent(from: paletteManager), lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appSurface(from: paletteManager))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Storage Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Storage Usage")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    HStack {
                        Text("Downloaded Models:")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                        
                        Spacer()
                        
                        Text(formatBytes(speechEngineManager.modelManager.getDownloadedModelsSize()))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.appAccent(from: paletteManager))
                    }
                    
                    Text("Models are stored in Application Support and automatically removed when you delete the app.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                }
                
                Divider()
                
                // Cleanup Action
                VStack(alignment: .leading, spacing: 12) {
                    Text("Storage Management")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Button(action: {
                        showingCleanupConfirmation = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.appError(from: paletteManager))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clean Up Downloaded Models")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color.appError(from: paletteManager))
                                
                                Text("Remove all downloaded models to free up space")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appError(from: paletteManager).opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appError(from: paletteManager).opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                    .disabled(speechEngineManager.modelManager.getDownloadedModelsSize() == 0)
                }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            }
        }
        .frame(maxWidth: 500, maxHeight: 450)
        .frame(minWidth: 420)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.appBackground(from: paletteManager))
        .alert("Clean Up Downloaded Models?", isPresented: $showingCleanupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clean Up", role: .destructive) {
                speechEngineManager.modelManager.cleanupDownloadedModels()
            }
        } message: {
            Text("This will permanently delete all downloaded WhisperKit models to free up storage space. You can re-download them later if needed.\n\nThis action cannot be undone.")
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Engine-Specific Permissions View

struct EngineSpecificPermissionsView: View {
    let selectedEngine: String
    let permissionManager: any PermissionServiceProtocol
    @EnvironmentObject var paletteManager: PaletteManager
    @Environment(\.features) var features
    @State private var microphoneState: PermissionState = .unknown
    @State private var accessibilityState: PermissionState = .unknown

    var body: some View {
        VStack(spacing: 12) {
            ForEach(requiredPermissions, id: \.self) { permission in
                SystemSettingsRow {
                    PermissionStatusRow(
                        title: permission.displayName,
                        description: descriptionFor(permission: permission),
                        state: stateFor(permission: permission),
                        icon: iconFor(permission: permission)
                    ) {
                        requestPermission(permission)
                    }
                }
            }

            if !missingPermissions.isEmpty {
                SystemSettingsRow {
                    HStack(spacing: 16) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appAccent(from: paletteManager))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(engineSpecificMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            if selectedEngine.lowercased() == "auto" && !missingPermissions.isEmpty {
                                Text("Enable the missing permissions to use all speech engines")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            updateStates()
        }
        .onReceive(permissionManager.overallStatePublisher) { _ in
            updateStates()
        }
    }

    private func updateStates() {
        microphoneState = permissionManager.microphoneState
        accessibilityState = permissionManager.accessibilityState
    }

    private var requiredPermissions: [PermissionType] {
        var permissions: [PermissionType] = [.microphone]

        if features.requiresAccessibility {
            permissions.append(.accessibility)
        }

        return permissions
    }
    
    private var missingPermissions: [PermissionType] {
        var missing: [PermissionType] = []
        if microphoneState != .granted {
            missing.append(.microphone)
        }
        if accessibilityState != .granted {
            missing.append(.accessibility)
        }
        return missing
    }
    
    private var engineSpecificMessage: String {
        switch selectedEngine.lowercased() {
        case "apple", "applespeech":
            return missingPermissions.isEmpty ? "System Speech Engine ready" : "System Speech Engine requires permissions"
        case "auto":
            return missingPermissions.isEmpty ? "All engines available" : "Missing permissions detected"
        default:
            return missingPermissions.isEmpty ? "WhisperKit Engine ready" : "WhisperKit Engine requires permissions"
        }
    }
    
    private func stateFor(permission: PermissionType) -> PermissionState {
        switch permission {
        case .microphone:
            return microphoneState
        case .accessibility:
            return accessibilityState
        }
    }

    private func descriptionFor(permission: PermissionType) -> String {
        switch permission {
        case .microphone:
            return "Required for speech recognition"
        case .accessibility:
            return "Required to detect global hotkey activation"
        }
    }

    private func iconFor(permission: PermissionType) -> String {
        switch permission {
        case .microphone:
            return "mic.fill"
        case .accessibility:
            return "keyboard.fill"
        }
    }

    private func requestPermission(_ permission: PermissionType) {
        Task {
            switch permission {
            case .microphone:
                await permissionManager.requestMicrophone()
            case .accessibility:
                await permissionManager.requestAccessibility()
            }
        }
    }
}

// // #Preview {
//     SystemSettingsSection(title: "General", icon: "gear") {
//         SystemSettingsRow {
//             HStack {
//                 Text("Sample Setting")
//                     .font(.system(size: 15, weight: .medium))
//                 Spacer()
//                 Toggle("", isOn: .constant(true))
//             }
//         }
//     }
//     .environmentObject(PaletteManager())
//     .padding()
// }
