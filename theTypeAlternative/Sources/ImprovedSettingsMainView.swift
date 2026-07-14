import SwiftUI
import AppServices
import AppKit
import SpeechKit

struct ImprovedSettingsMainView: View {
    @State private var selectedHotkey = UserDefaults.standard.string(forKey: "GlobalHotkey") ?? "Option+Space"
    @State private var selectedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage") ?? "English (US)"
    @State private var autoStart = UserDefaults.standard.object(forKey: "AutoStart") as? Bool ?? false
    @State private var minimizeToMenuBar = UserDefaults.standard.object(forKey: "MinimizeToMenuBar") as? Bool ?? true
    
    // Modal Sheet States
    @State private var showingAppearanceSheet = false
    @State private var showingLanguageSheet = false
    @State private var showingEngineSheet = false
    @State private var showingModelSheet = false
    @State private var showingStorageSheet = false
    @State private var showingResetConfirmation = false

    let permissionManager: any PermissionServiceProtocol

    @Environment(\.features) var features
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    @EnvironmentObject var paletteManager: PaletteManager
    @EnvironmentObject var speechEngineSettings: SpeechEngineSettings
    @EnvironmentObject var speechEngineManager: SpeechEngineManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                settingsHeader
                
                // Content Sections
                VStack(spacing: 20) {
                    // General Section
                    generalSection
                    
                    // Speech Recognition Section
                    speechSection
                    
                    // Appearance Section
                    appearanceSection
                    
                    // Privacy & Security Section
                    privacySection

                    if features.supportsWhisperKit {
                        storageSection
                    }

                    // Advanced Section
                    advancedSection
                }
                .padding(.horizontal, 32)
                .padding(.top, 20) // Add top padding for navigation bar spacing
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground(from: paletteManager))
        .onAppear {
            permissionManager.startMonitoring()
        }
        .onDisappear {
            permissionManager.stopMonitoring()
        }
        // Modal Sheets
        .sheet(isPresented: $showingAppearanceSheet) {
            AppearanceConfigSheet()
                .environmentObject(appearanceSettings)
                .environmentObject(paletteManager)
        }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguageSelectionSheet(selectedLanguage: $selectedLanguage)
                .environmentObject(paletteManager)
        }
        .sheet(isPresented: $showingEngineSheet) {
            EngineSelectionSheet()
                .environmentObject(speechEngineSettings)
                .environmentObject(paletteManager)
        }
        .sheet(isPresented: $showingModelSheet) {
            ModelManagementSheet()
                .environmentObject(speechEngineSettings)
                .environmentObject(speechEngineManager)
                .environmentObject(paletteManager)
        }
        .sheet(isPresented: $showingStorageSheet) {
            StorageManagementSheet()
                .environmentObject(speechEngineManager)
                .environmentObject(paletteManager)
        }
        .alert("Reset All Settings?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .navigationTitle("Settings")
    }
    
    // MARK: - Header
    private var settingsHeader: some View {
        // Header content removed since navigation title now handles this
        EmptyView()
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        SystemSettingsSection(title: "General", icon: "gear") {
            VStack(spacing: 16) {
                if features.supportsHotkeys {
                    SystemSettingsRow {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Activation Hotkey")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))

                                Text("Press and hold to start dictation")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            }

                            Spacer()

                            HotkeyRecorderView(hotkey: $selectedHotkey)
                        }
                    }
                }

                // Auto Start
                SystemSettingsRow {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Start at Login")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Text("Launch AltType automatically when you log in")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autoStart)
                            .toggleStyle(SwitchToggleStyle(tint: Color.appPrimary(from: paletteManager)))
                            .onChange(of: autoStart) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "AutoStart")
                            }
                    }
                }
                
                // Minimize to Menu Bar
                SystemSettingsRow {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Minimize to Menu Bar")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Text("Hide the app window and show only the menu bar icon")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $minimizeToMenuBar)
                            .toggleStyle(SwitchToggleStyle(tint: Color.appPrimary(from: paletteManager)))
                            .onChange(of: minimizeToMenuBar) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "MinimizeToMenuBar")
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Speech Section
    private var speechSection: some View {
        SystemSettingsSection(title: "Speech Recognition", icon: "waveform") {
            VStack(spacing: 16) {
                if features.supportsWhisperKit {
                    SystemSettingsRow(isButton: true) {
                        Button(action: { showingEngineSheet = true }) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Recognition Engine")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.appOnSurface(from: paletteManager))

                                    Text(speechEngineSettings.enginePreference.displayName)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color.appAccent(from: paletteManager))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.4))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                }
                
                // WhisperKit Model (conditional)
                if speechEngineSettings.enginePreference == .whisperKit {
                    SystemSettingsRow(isButton: true) {
                        Button(action: { showingModelSheet = true }) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("WhisperKit Model")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                                    
                                    Text(speechEngineSettings.whisperModelPreference.displayName + " • " + speechEngineSettings.whisperModelPreference.sizeInfo)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color.appAccent(from: paletteManager))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.4))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: speechEngineSettings.enginePreference == .whisperKit)
                }
                
                // Language Selection
                SystemSettingsRow(isButton: true) {
                    Button(action: { showingLanguageSheet = true }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Language")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                                
                                Text(selectedLanguage)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appAccent(from: paletteManager))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
                
                if features.supportsHotkeys {
                    SystemSettingsRow {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Sound Feedback")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))

                                Text("Play sounds when starting and stopping dictation")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            }

                            Spacer()

                            Toggle("", isOn: $speechEngineSettings.enableSounds)
                                .toggleStyle(SwitchToggleStyle(tint: Color.appPrimary(from: paletteManager)))
                        }
                    }
                }
                
                // Silence Timeout
                SystemSettingsRow {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Silence Timeout")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                                
                                Text("Automatically stop listening after silence")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text("\(Int(speechEngineSettings.silenceTimeout))s")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.appAccent(from: paletteManager))
                        }
                        
                        Slider(value: $speechEngineSettings.silenceTimeout, in: 5...60, step: 1)
                            .tint(Color.appPrimary(from: paletteManager))
                    }
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        SystemSettingsSection(title: "Appearance", icon: "paintbrush") {
            VStack(spacing: 16) {
                // Theme & Color Selection
                SystemSettingsRow(isButton: true) {
                    Button(action: { showingAppearanceSheet = true }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Theme & Colors")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                                
                                Text("\(appearanceSettings.preferredMode.displayName) • \(paletteManager.selectedPalette.displayName)")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appAccent(from: paletteManager))
                            }
                            
                            Spacer()
                            
                            // Color Preview Dots
                            HStack(spacing: 4) {
                                let paletteColors = paletteManager.selectedPalette.createPalette()
                                
                                ForEach(0..<3) { index in
                                    let color = [paletteColors.primary.light, paletteColors.secondary.light, paletteColors.accent.light][index]
                                    Circle()
                                        .fill(Color(color))
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        SystemSettingsSection(title: "Privacy & Security", icon: "lock.shield") {
            VStack(spacing: 16) {
                // Privacy Info
                SystemSettingsRow {
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.appSuccess(from: paletteManager))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("On-Device Processing")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Text("All speech recognition happens locally. No data leaves your device.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        }
                        
                        Spacer()
                    }
                }
                
                // Dynamic Engine-Specific Permissions
                EngineSpecificPermissionsView(
                    selectedEngine: speechEngineSettings.enginePreference.rawValue,
                    permissionManager: permissionManager
                )
            }
        }
    }
    
    // MARK: - Storage Section
    private var storageSection: some View {
        SystemSettingsSection(title: "Storage", icon: "internaldrive") {
            VStack(spacing: 16) {
                // Storage Usage
                SystemSettingsRow(isButton: true) {
                    Button(action: { showingStorageSheet = true }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Downloaded Models")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                                
                                Text(formatBytes(speechEngineManager.modelManager.getDownloadedModelsSize()))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appAccent(from: paletteManager))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    // MARK: - Advanced Section
    private var advancedSection: some View {
        SystemSettingsSection(title: "Advanced", icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                // Reset Settings
                SystemSettingsRow(isButton: true) {
                    Button(action: { showingResetConfirmation = true }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Reset to Defaults")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.appError(from: paletteManager))
                                
                                Text("Reset all settings to their default values")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func resetToDefaults() {
        selectedHotkey = "Option+Space"
        speechEngineSettings.enableSounds = true
        speechEngineSettings.silenceTimeout = 15.0
        speechEngineSettings.enginePreference = .auto
        speechEngineSettings.whisperModelPreference = .base
        selectedLanguage = "English (US)"
        autoStart = false
        minimizeToMenuBar = true
        appearanceSettings.preferredMode = .system
        
        // Save to UserDefaults
        UserDefaults.standard.set(selectedHotkey, forKey: "GlobalHotkey")
        UserDefaults.standard.set(49, forKey: "GlobalHotkeyKeyCode")
        UserDefaults.standard.set(NSEvent.ModifierFlags.option.rawValue, forKey: "GlobalHotkeyModifiers")
        UserDefaults.standard.set(selectedLanguage, forKey: "SelectedLanguage")
        UserDefaults.standard.set(autoStart, forKey: "AutoStart")
        UserDefaults.standard.set(minimizeToMenuBar, forKey: "MinimizeToMenuBar")
        UserDefaults.standard.set(AppearanceMode.system.rawValue, forKey: "appearance_mode")
    }
}

// // #Preview {
//     ImprovedSettingsMainView(permissionManager: PermissionManager.shared)
//         .environmentObject(AppearanceSettings())
//         .environmentObject(PaletteManager())
//         .environmentObject(PermissionManager())
//         .environmentObject(SpeechEngineSettings())
//         .environmentObject(SpeechEngineManager())
//         .frame(width: 800, height: 600)
// }