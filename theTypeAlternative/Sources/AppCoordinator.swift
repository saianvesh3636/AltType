import Foundation
import AppKit
import Combine
import AppServices
import SpeechKit
import AVFoundation
import os.log

import BuildConfiguration

// MARK: - Clean DI Architecture
// No Combine extensions needed - using direct delegate calls

enum AppState: Equatable {
    case idle
    case listening
    case error(AppError)
}

enum AppError: LocalizedError, Equatable, Sendable {
    case microphonePermissionDenied
    case accessibilityPermissionDenied
    case speechRecognizerUnavailable
    case noActiveTextField

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access denied. Click to fix."
        case .accessibilityPermissionDenied:
            return "Accessibility permission denied. Click to fix."
        case .speechRecognizerUnavailable:
            return "On-device recognizer unavailable."
        case .noActiveTextField:
            return "No active text field found."
        }
    }

    static func from(_ permissionError: PermissionError) -> AppError {
        switch permissionError.type {
        case .microphone:
            return .microphonePermissionDenied
        case .accessibility:
            return .accessibilityPermissionDenied
        }
    }
}

@MainActor
class AppCoordinator: ObservableObject, SpeechActionDelegate, SoundFeedbackDelegate, TextInsertionDelegate {
    @Published var state: AppState = .idle

    // MARK: - Dependencies
    private let transcriptionStore: TranscriptionStore
    private let hotkeySettings: any HotkeySettingsProtocol // Protocol-based DI

    // Public access to permission manager for UI components
    let permissionManager: any PermissionServiceProtocol

    private let speechService: SpeechService
    private let speechEngineManager: SpeechEngineManager

    // MARK: - Public Environment Objects
    let speechEngineSettings: SpeechEngineSettings

    // MARK: - Private Properties
    private var statusItem: NSStatusItem?
    private var hotkeyManager: (any HotkeyServiceProtocol)?
    #if DEBUG
    public let textInserter: any TextInsertionServiceProtocol
    #else
    private let textInserter: any TextInsertionServiceProtocol
    #endif
    private var cancellables = Set<AnyCancellable>()

    // Recording overlay
    private var recordingOverlay: NSWindow?



    @MainActor init(statusItem: NSStatusItem?, transcriptionStore: TranscriptionStore, hotkeySettings: any HotkeySettingsProtocol, permissionManager: any PermissionServiceProtocol, speechEngineManager: SpeechEngineManager, speechEngineSettings: SpeechEngineSettings) {
        Logger.lifecycle("AppCoordinator init starting...")
        self.statusItem = statusItem
        self.transcriptionStore = transcriptionStore
        self.hotkeySettings = hotkeySettings
        self.permissionManager = permissionManager
        self.speechEngineManager = speechEngineManager
        self.speechEngineSettings = speechEngineSettings

        Logger.debug("Creating text insertion service via DI...")
        self.textInserter = AppServices.AppConfiguration.current.createTextInsertionService()

        // Create SpeechRecognizer with shared speechEngineManager
        Logger.debug("Creating SpeechRecognizer with shared speechEngineManager...")
        let speechRecognizer = SpeechRecognizer(speechEngineManager: self.speechEngineManager)

        Logger.debug("Creating SpeechService with dependencies...")
        self.speechService = SpeechService(
            transcriptionStore: transcriptionStore,
            speechRecognizer: speechRecognizer,
            textInserter: textInserter,
            speechEngineManager: self.speechEngineManager,
            textInsertionDelegate: nil  // Will set after initialization
        )

        // Set text insertion delegate after initialization
        Logger.debug("Setting text insertion delegate...")
        speechService.setTextInsertionDelegate(self)

        Logger.debug("Setting up managers...")
        setupManagers()

        Logger.debug("Setting up state observation...")
        observeState()
        Logger.debug("Setting up hotkey observation...")
        observeHotkeySettings()
        Logger.debug("Setting up reactive permission monitoring...")
        observePermissionState()
        Logger.debug("Binding speech engine settings...")
        speechEngineManager.bindToSettings(speechEngineSettings)
        Logger.success("AppCoordinator init complete (reactive permission architecture)")
    }
    
    func start() {
        Logger.lifecycle("AppCoordinator starting...")
        SpeechLogger.shared.printSpeechSummary()
        permissionManager.startMonitoring()

        let isOnboardingComplete = UserDefaults.standard.bool(forKey: "OnboardingCompleted")

        if isOnboardingComplete {
            if AppServices.AppConfiguration.current.features.requiresAccessibility {
                if permissionManager.hasAccessibilityPermission {
                    registerHotkey()
                } else {
                    showPermissionErrorIslandOnStartup()
                }
            }
        }

        setupAppActivationMonitoring()
        updateUI(for: state)
        Logger.success("AppCoordinator started successfully")
    }
    
    /// Complete post-onboarding setup - called after user completes onboarding flow
    public func completePostOnboardingSetup() {
        Logger.lifecycle("Completing post-onboarding setup...")
        signalUserIntent(source: "Onboarding completed")

        if AppServices.AppConfiguration.current.features.requiresAccessibility {
            if permissionManager.hasAccessibilityPermission {
                registerHotkey()
            } else {
                showPermissionErrorIslandOnStartup()
            }
        }

        Logger.success("Post-onboarding setup complete")
    }

    private func setupManagers() {
        Logger.debug("Creating hotkey service via DI...")
        hotkeyManager = AppServices.AppConfiguration.current.createHotkeyService()

        // Set up clean DI architecture - HotkeyManager directly calls delegates
        hotkeyManager?.speechActionDelegate = self
        hotkeyManager?.soundFeedbackDelegate = self
        Logger.success("Hotkey service delegates configured")

        // Connect HotkeyManager state to textInserter reactive pipeline
        setupTextInserterReactiveIntegration()

        Logger.success("All managers created successfully")
    }
    
    /// Integrate HotkeyManager state changes with UniversalTextInserter reactive architecture
    private func setupTextInserterReactiveIntegration() {
        guard let hotkeyManager = hotkeyManager else { return }
        
        Logger.debug("Setting up reactive text inserter integration...")

        // Connect hotkey state to text inserter's reactive pipeline
        hotkeyManager.hotkeyStatePublisher
            .map(\.isPressed)
            .removeDuplicates()
            .sink { [weak self] isPressed in
                self?.textInserter.signalHotkeyState(isPressed)
            }
            .store(in: &cancellables)

        // Connect manager state transitions to text inserter warmup lifecycle
        hotkeyManager.managerStatePublisher
            .removeDuplicates()
            .sink { [weak self] managerState in
                self?.textInserter.signalManagerState(managerState)
            }
            .store(in: &cancellables)
        
        Logger.success("Reactive text inserter integration configured")
    }
    
    // MARK: - SpeechActionDelegate Implementation
    
    func startSpeechRecording() {
        Logger.speech("SpeechActionDelegate: Start recording requested")
        
        // Only start if we're not already listening
        guard case .idle = state else {
            Logger.warning("Ignoring start request - already in state: \(state)")
            return
        }
        
        startListening()
    }
    
    func stopSpeechRecording() {
        Logger.speech("SpeechActionDelegate: Stop recording requested")
        
        // Only stop if we're currently listening
        guard case .listening = state else {
            Logger.warning("Ignoring stop request - not in listening state: \(state)")
            return
        }
        
        stopListening()
    }
    
    // MARK: - SoundFeedbackDelegate Implementation

    func playStartSound() {
        playFeedbackSound(named: "Pop", volume: 0.35)
    }

    func playStopSound() {
        playFeedbackSound(named: "Purr", volume: 0.3)
    }
    
    private func setupAppActivationMonitoring() {
        // Monitor when app becomes active after user returns from Settings
        // This is the recommended approach per Apple's guidelines
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                // Only recheck if we're in an error state (user might have granted permission in Settings)
                if case .error = self?.state {
                    Logger.debug("App became active - refreshing permission states after potential Settings visit...")
                    self?.permissionManager.refreshPermissionStates()
                }
            }
        }

        Logger.debug("App activation monitoring setup for Settings return")
    }
    
    private func observeState() {
        $state
            .removeDuplicates() // Only trigger UI updates when state actually changes - immediate response
            .sink { [weak self] newState in
                self?.updateUI(for: newState)
            }
            .store(in: &cancellables)
    }
    
    // REMOVED: observeSpeechService() - now using clean DI architecture with delegate pattern
    
    private func observeHotkeySettings() {
        // Observe hotkey changes with deduplication (immediate registration for better UX)
        // Note: For lite version, NoOpHotkeyService ignores these changes
        hotkeySettings.requiredKeysPublisher
            .removeDuplicates() // Only trigger when hotkey combination actually changes
            .sink { [weak self] requiredKeys in
                self?.updateHotkey(requiredKeys: requiredKeys)
            }
            .store(in: &cancellables)
    }
    
    private func observePermissionState() {
        permissionManager.overallStatePublisher
            .removeDuplicates()
            .sink { [weak self] permissionState in
                self?.handlePermissionStateChange(permissionState)
                self?.updateErrorIslandVisibility(for: permissionState)
            }
            .store(in: &cancellables)
    }
    
    private func updateHotkey(requiredKeys: Set<UInt16>) {
        hotkeyManager?.registerHotkey(requiredKeys)
    }
    
    private func handlePermissionStateChange(_ state: OverallPermissionState) {
        Logger.debug("Permission state changed to: \(state)")

        switch state {
        case .ready:
            updateAppState(to: .idle, hasPermissions: true)
            Logger.success("All permissions granted")

        case .needsMicrophone, .needsBoth:
            updateAppState(to: .error(.microphonePermissionDenied), hasPermissions: false)
            logPermissionIssue(for: state)

        case .needsAccessibility:
            updateAppState(to: .error(.accessibilityPermissionDenied), hasPermissions: false)
            Logger.warning("Input Monitoring permission needed")

        case .error(let permissionError):
            updateAppState(to: .error(AppError.from(permissionError)), hasPermissions: false)
            Logger.error("Permission error: \(permissionError)")

        case .checking:
            Logger.debug("Checking permissions...")
        }
    }
    
    private func updateErrorIslandVisibility(for state: OverallPermissionState) {
        // Don't show permission island during onboarding - onboarding flow handles permissions
        let isOnboardingComplete = UserDefaults.standard.bool(forKey: "OnboardingCompleted")
        guard isOnboardingComplete else {
            Logger.debug("Skipping permission island - onboarding in progress")
            return
        }

        switch state {
        case .ready:
            // Hide error island when all permissions are granted (but only if not actively listening)
            if self.state != .listening {
                hideRecordingOverlay()
                Logger.debug("Hiding error island - permissions granted")
            }

        case .needsMicrophone, .needsAccessibility, .needsBoth, .error:
            // Show error island when permissions are missing (regardless of app state)
            showPermissionErrorIsland()

        case .checking:
            // Don't change island visibility during permission checks
            break
        }
    }
    
    
    // MARK: - Helper Methods for Cleaner Code
    
    private func updateAppState(to newState: AppState, hasPermissions: Bool) {
        self.state = newState
        updateHotkeyManagerPermissions(hasPermissions: hasPermissions)
    }
    
    private func logPermissionIssue(for state: OverallPermissionState) {
        let message = state == .needsBoth ? 
            "Both microphone and accessibility permissions needed" : 
            "Microphone permission needed"
        Logger.warning(message)
    }
    
    private func updateHotkeyManagerPermissions(hasPermissions: Bool) {
        let currentPermissionState = hotkeyManager?.isRegistrationEnabled ?? false
        
        // Only update if permission state actually changed
        if currentPermissionState != hasPermissions {
            hotkeyManager?.setPermissionState(hasPermissions: hasPermissions)
            
            // Re-register hotkey when permissions are granted
            if hasPermissions {
                Logger.debug("Permissions granted - re-registering hotkey")
                registerHotkey()
            }
            
            Logger.debug("Hotkey registration \(hasPermissions ? "enabled" : "disabled")")
        } else {
            Logger.debug("Permission state unchanged - skipping hotkey update")
        }
    }
    
    // MARK: - Session-Based Energy Management
    
    /// Signal user intent to use the app - enables energy-efficient hotkey monitoring
    func signalUserIntent(source: String) {
        Logger.debug("User intent signal from: \(source)")
        hotkeyManager?.signalUserIntent(source: source)
    }
    
    @MainActor
    private func updateUI(for state: AppState) {
        guard let button = statusItem?.button else { return }

        // Get current hotkey for display
        let currentHotkey = hotkeySettings.displayName
        let supportsHotkeys = AppServices.AppConfiguration.current.features.supportsHotkeys

        switch state {
        case .idle:
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
            button.toolTip = supportsHotkeys ? "Ready - Press \(currentHotkey) to dictate" : "Ready - Click menu to dictate"

        case .listening:
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
            button.toolTip = supportsHotkeys ? "Recording - Press \(currentHotkey) to stop" : "Recording - Click menu to stop"

        case .error(let error):
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
            button.toolTip = error.localizedDescription
        }

        updateStatusMenu()
    }
    
    
    private func updateStatusMenu() {
        guard let statusItem = statusItem else {
            Logger.error("StatusItem is nil, cannot update menu")
            return
        }
        
        // Create a simple test menu
        let menu = NSMenu()
        
        // Add basic menu items that should always work
        let titleItem = NSMenuItem(title: "AltType", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add state info
        let stateText: String
        switch state {
        case .idle: stateText = "✅ Ready to dictate"
        case .listening: stateText = "🎤 Recording..."
        case .error(let error): stateText = "❌ \(error.localizedDescription)"
        }
        
        let stateItem = NSMenuItem(title: stateText, action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(stateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add test button to verify menu works
        let testItem = NSMenuItem(title: "🧪 Test Click", action: #selector(testMenuClick), keyEquivalent: "")
        testItem.target = self
        menu.addItem(testItem)
        
        // Add start/stop recording button
        let recordingButtonText = state == .listening ? "⏹ Stop Recording" : "🎤 Start Recording"
        let recordingItem = NSMenuItem(title: recordingButtonText, action: #selector(toggleRecordingFromMenu), keyEquivalent: "")
        recordingItem.target = self
        recordingItem.isEnabled = state != .error(AppError.microphonePermissionDenied) && state != .error(AppError.accessibilityPermissionDenied)
        menu.addItem(recordingItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add quit option
        let quitItem = NSMenuItem(title: "Quit AltType", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    private func addStatusSection(to menu: NSMenu, hotkey: String) {
        switch state {
        case .idle:
            let statusItem = NSMenuItem(title: "✅ Ready to dictate", action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)
            
            let instructionItem = NSMenuItem(title: "Press \(hotkey) or click below to start", action: nil, keyEquivalent: "")
            instructionItem.isEnabled = false
            menu.addItem(instructionItem)
            
        case .listening:
            let statusItem = NSMenuItem(title: "🎤 Recording...", action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)
            
            let instructionItem = NSMenuItem(title: "Release \(hotkey) or click below to stop", action: nil, keyEquivalent: "")
            instructionItem.isEnabled = false
            menu.addItem(instructionItem)
            
        case .error(let error):
            let errorItem = NSMenuItem(title: "❌ \(error.localizedDescription)", action: #selector(handleErrorClick), keyEquivalent: "")
            errorItem.target = self
            menu.addItem(errorItem)
        }
    }
    
    private func addPrimaryControls(to menu: NSMenu) {
        let startItem = NSMenuItem(title: "🎤 Start Recording", action: #selector(menuStartRecording), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)
    }
    
    private func addEngineSelection(to menu: NSMenu) {
        let engineSubmenu = NSMenu(title: "Speech Engine")
        let currentPreference = speechEngineSettings.enginePreference
        
        // Auto selection
        let autoItem = NSMenuItem(title: "✨ Automatic", action: #selector(selectAutoEngine), keyEquivalent: "")
        autoItem.target = self
        autoItem.state = currentPreference == .auto ? .on : .off
        engineSubmenu.addItem(autoItem)
        
        // Apple Speech
        let appleItem = NSMenuItem(title: "🗣️ System Speech", action: #selector(selectAppleSpeech), keyEquivalent: "")
        appleItem.target = self
        appleItem.state = currentPreference == .appleSpeech ? .on : .off
        engineSubmenu.addItem(appleItem)
        
        // WhisperKit
        let whisperItem = NSMenuItem(title: "🧠 WhisperKit", action: #selector(selectWhisperKit), keyEquivalent: "")
        whisperItem.target = self
        whisperItem.state = currentPreference == .whisperKit ? .on : .off
        engineSubmenu.addItem(whisperItem)
        
        let engineMenuItem = NSMenuItem(title: "Speech Engine (\(currentPreference.displayName))", action: nil, keyEquivalent: "")
        engineMenuItem.submenu = engineSubmenu
        menu.addItem(engineMenuItem)
    }
    
    private func addRecentTranscriptions(to menu: NSMenu) {
        let recentSubmenu = NSMenu(title: "Recent Transcriptions")
        
        let recentTranscriptions = Array(transcriptionStore.transcriptionHistory.prefix(5))
        
        for (index, transcription) in recentTranscriptions.enumerated() {
            let truncatedText = String(transcription.text.prefix(50)) + (transcription.text.count > 50 ? "..." : "")
            let menuItem = NSMenuItem(title: "\(index + 1). \(truncatedText)", action: #selector(copyTranscription(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = transcription.text
            recentSubmenu.addItem(menuItem)
        }
        
        if !recentTranscriptions.isEmpty {
            recentSubmenu.addItem(NSMenuItem.separator())
            let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearTranscriptionHistory), keyEquivalent: "")
            clearItem.target = self
            recentSubmenu.addItem(clearItem)
        }
        
        let recentMenuItem = NSMenuItem(title: "Recent Transcriptions", action: nil, keyEquivalent: "")
        recentMenuItem.submenu = recentSubmenu
        menu.addItem(recentMenuItem)
    }
    
    private func addQuickSettings(to menu: NSMenu) {
        let settingsSubmenu = NSMenu(title: "Settings")

        // Sound toggle
        let soundsEnabled = UserDefaults.standard.object(forKey: "EnableSounds") as? Bool ?? true
        let soundItem = NSMenuItem(title: soundsEnabled ? "🔊 Disable Sounds" : "🔇 Enable Sounds",
                                 action: #selector(toggleSounds), keyEquivalent: "")
        soundItem.target = self
        settingsSubmenu.addItem(soundItem)

        // Hotkey display (only if variant supports hotkeys)
        if AppServices.AppConfiguration.current.features.supportsHotkeys {
            let hotkeyItem = NSMenuItem(title: "⌨️ Hotkey: \(hotkeySettings.displayName)", action: nil, keyEquivalent: "")
            hotkeyItem.isEnabled = false
            settingsSubmenu.addItem(hotkeyItem)
        }

        settingsSubmenu.addItem(NSMenuItem.separator())

        let openSettingsItem = NSMenuItem(title: "Open Settings...", action: #selector(openSettings), keyEquivalent: ",")
        openSettingsItem.target = self
        settingsSubmenu.addItem(openSettingsItem)

        let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsMenuItem.submenu = settingsSubmenu
        menu.addItem(settingsMenuItem)
    }
    
    private func addActionItems(to menu: NSMenu) {
        let aboutItem = NSMenuItem(title: "About AltType", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        let quitItem = NSMenuItem(title: "Quit AltType", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    func handlePermissionError(_ error: AppError) {
        switch error {
        case .microphonePermissionDenied:
            Task {
                let granted = await permissionManager.requestMicrophone()
                if !granted {
                    permissionManager.openSystemSettings(for: .microphone)
                }
            }
        case .accessibilityPermissionDenied:
            permissionManager.openSystemSettings(for: .accessibility)
        default:
            cleanupListeningResources()
            state = .idle
        }
    }
    
    @objc private func handleErrorClick() {
        if case .error(let error) = state {
            handlePermissionError(error)
        }
    }
    
    // MARK: - Menu Action Methods
    
    @objc private func menuStartRecording() {
        startListening()
    }
    
    @objc private func selectAppleSpeech() {
        speechEngineSettings.enginePreference = .appleSpeech
        Logger.debug("Menu: Selected Apple Speech engine")
    }
    
    @objc private func selectWhisperKit() {
        speechEngineSettings.enginePreference = .whisperKit
        Logger.debug("Menu: Selected WhisperKit engine")
    }
    
    @objc private func selectAutoEngine() {
        speechEngineSettings.enginePreference = .auto
        Logger.debug("Menu: Selected Automatic engine")
    }
    
    @objc private func copyTranscription(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        Logger.debug("Menu: Copied transcription to clipboard")
    }
    
    @objc private func clearTranscriptionHistory() {
        transcriptionStore.clearHistory()
        Logger.debug("Menu: Cleared transcription history")
    }
    
    @objc private func toggleSounds() {
        let currentValue = UserDefaults.standard.object(forKey: "EnableSounds") as? Bool ?? true
        UserDefaults.standard.set(!currentValue, forKey: "EnableSounds")
        Logger.debug("Menu: Toggled sounds to \(!currentValue)")
    }
    
    @objc private func openSettings() {
        // This is called from NSMenu items - we need to post a notification
        // since we don't have direct access to NavigationHandler here
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToSettings"),
            object: nil
        )
        
        // Bring main window to front
        bringMainWindowToFront()
        Logger.debug("Menu: Opening settings via notification")
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "AltType"
        alert.informativeText = "Transform speech to text instantly\n\nA privacy-first voice-to-text application with fully on-device processing."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func testMenuClick() {
        let alert = NSAlert()
        alert.messageText = "Menu Bar Test"
        alert.informativeText = "Menu bar click is working!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func toggleRecordingFromMenu() {
        Logger.debug("Toggle recording from menu bar")
        toggleListening()
    }

    @objc private func quit() {
        // Clean up resources before quitting
        cleanupListeningResources()
        NSApplication.shared.terminate(nil)
    }
    
    /// Centralized cleanup for listening-related resources
    private func cleanupListeningResources() {
        hideRecordingOverlay()
        // Processing unit cleanup is handled in stopListening method
    }
    
    // REMOVED: checkPermissions() - now handled reactively by observePermissionState()
    // All permission state changes are managed by PermissionKit.PermissionManager
    
    private func registerHotkey() {
        // Lite variant doesn't need hotkeys — skip entirely
        guard AppServices.AppConfiguration.current.features.supportsHotkeys else {
            Logger.hotkey("Skipping hotkey registration — not supported in this variant")
            return
        }

        Logger.hotkey("Registering push-to-talk hotkey...")

        guard let hotkeyManager = hotkeyManager else {
            Logger.error("No hotkeyManager available for registration")
            return
        }

        let hasAccessibility = permissionManager.hasAccessibilityPermission
        hotkeyManager.setPermissionState(hasPermissions: hasAccessibility)

        // Use current settings from HotkeySettings (optimized)
        let requiredKeys = hotkeySettings.requiredKeys

        Logger.hotkey("Using required keys: \(requiredKeys)")

        // Ensure Function key (179) is included if it's the default
        if requiredKeys.isEmpty {
            Logger.warning("Empty hotkey set detected, using default Function key")
            hotkeyManager.registerHotkey([179]) // Function key
        } else {
            // Register with the optimized set-based system
            hotkeyManager.registerHotkey(requiredKeys)
        }

        Logger.success("Push-to-talk hotkey registered with keys: \(requiredKeys.isEmpty ? [179] : requiredKeys)")
    }
    
    private func toggleListening() {
        switch state {
        case .idle:
            startListening()
        case .listening:
            stopListening()
        case .error:
            // Try to recover by returning to idle state
            state = .idle
        }
    }
    
    // Public methods for external control
    public func startListening() {
        Logger.speech("StartListening called - current state: \(state)")
        
        // Only start listening if we're in idle state (reactive system ensures correct permissions)
        guard state == .idle else {
            Logger.warning("Cannot start listening - current state: \(state)")
            return
        }
        
        // Check permissions first - show island for permission errors
        if !permissionManager.hasAllPermissions {
            Logger.warning("Permissions missing - showing permission error island")
            showRecordingOverlay() // Use existing island UI, it will show permission error state
            return
        }
        
        // Check if onboarding is completed before allowing transcription
        guard UserDefaults.standard.bool(forKey: "OnboardingCompleted") else {
            Logger.warning("Transcription denied - onboarding not completed")
            return
        }

        // Set state to listening first to prevent race conditions
        state = .listening

        Logger.speech("Starting speech service...")
        speechService.startListening()
        showHUD(message: "Listening...")
        // Sound feedback is handled by hotkey press/release events

        // Show recording overlay
        showRecordingOverlay()

        Logger.success("Listening started successfully")
    }
    
    public func stopListening() {
        Logger.speech("StopListening called - current state: \(state)")
        
        // Only stop if we're actually listening
        guard state == .listening else {
            Logger.warning("Not in listening state, ignoring stop request")
            return
        }
        
        // Use defer to ensure cleanup always happens, even if speech service throws
        defer {
            
            // Use centralized cleanup for consistency
            cleanupListeningResources()
            showHUD(message: "Stopped")
            Logger.success("Listening stopped successfully")
        }
        
        // Set state to idle immediately to prevent multiple stop calls
        state = .idle
        
        Logger.debug("Stopping speech service...")
        speechService.stopListening()
        
        // No session ending needed in simplified approach
        
        // Sound feedback is handled by hotkey press/release events
    }
    
    
    private func showHUD(message: String) {
        // TODO: Implement HUD display
        Logger.debug("HUD: \(message)")
    }
    
    private func playFeedbackSound(named name: String, volume: Float) {
        // Check if sound feedback is enabled
        let soundsEnabled = UserDefaults.standard.object(forKey: "EnableSounds") as? Bool ?? true
        guard soundsEnabled else { return }

        // Copy so overlapping start/stop cues don't cut each other off
        guard let sound = NSSound(named: name)?.copy() as? NSSound else { return }
        sound.volume = volume
        sound.play()
    }
    
    private func showRecordingOverlay() {
        // Create overlay window if it doesn't exist
        if recordingOverlay == nil {
            let overlay = RecordingOverlayWindow(permissionManager: permissionManager)
            recordingOverlay = overlay
        }
        
        guard let overlay = recordingOverlay else { return }

        // Top of screen, just below the menu bar / notch.
        // Horizontal centering uses the FULL screen frame, not visibleFrame:
        // visibleFrame subtracts a side-mounted Dock, which shifts its midX
        // away from the physical center where the notch sits.
        if let screen = NSScreen.main {
            let overlayWidth: CGFloat = 200
            let overlayHeight: CGFloat = 50
            let overlayFrame = NSRect(
                x: screen.frame.midX - (overlayWidth / 2),
                y: screen.visibleFrame.maxY - 60,
                width: overlayWidth,
                height: overlayHeight
            )
            overlay.setFrame(overlayFrame, display: true)
        }

        overlay.orderFrontRegardless()
        overlay.level = .statusBar
    }
    
    private func hideRecordingOverlay() {
        recordingOverlay?.orderOut(nil)
    }
    
    private func showPermissionErrorIsland() {
        // Show the overlay and keep it visible until permissions are granted
        showRecordingOverlay()
        Logger.debug("Permission error island shown reactively")
    }
    
    private func showPermissionErrorIslandOnStartup() {
        // Don't show permission island during onboarding - onboarding flow handles permissions
        let isOnboardingComplete = UserDefaults.standard.bool(forKey: "OnboardingCompleted")
        guard isOnboardingComplete else {
            Logger.debug("Skipping permission island on startup - onboarding in progress")
            return
        }

        // Show the overlay and keep it visible until permissions are granted
        showPermissionErrorIsland()
    }
    
    
    private func bringMainWindowToFront() {
        if let mainWindow = NSApp.windows.first(where: { $0.title == "AltType" }) {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Text Insertion

extension AppCoordinator {
    
    /// Insert transcribed text into the active application
    func insertTranscribedText(_ text: String) {
        Logger.textInsertion("📍 AppCoordinator.insertTranscribedText() called with: '\(text)'")
        Logger.textInsertion("📤 About to call textInserter.insertText()")
        textInserter.insertText(text, isFinal: true)
        Logger.textInsertion("✅ textInserter.insertText() call completed")
    }

    // MARK: - System Event Handling (Energy Efficient)
    
    /// Handle system wake events for smart energy management
    func handleSystemWake() {
        Logger.debug("System wake detected")
        hotkeyManager?.handleSystemWake()
    }
}
