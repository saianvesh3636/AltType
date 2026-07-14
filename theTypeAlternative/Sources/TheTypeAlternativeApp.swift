import SwiftUI
import AppKit
import AppServices
import SpeechKit
import BuildConfiguration
import FeatureFlags

@main
struct TheTypeAlternativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup("AltType") {
            ContentView(permissionManager: appDelegate.permissionManager)
                .environmentObject(appDelegate.transcriptionStore)
                .environment(\.hotkeySettings, appDelegate.hotkeySettings)
                .environment(\.features, AppServices.AppConfiguration.current.features)
                .environmentObject(appDelegate.appCoordinator)
                .environmentObject(appDelegate.paletteManager)
                .environmentObject(appDelegate.speechEngineSettings)
                .environmentObject(appDelegate.speechEngineManager)
                .environmentObject(appDelegate.debugConfiguration)
                .environmentObject(appDelegate.featureFlagManager)
                .environmentObject(appDelegate.navigationHandler)
                .tint(Color.appPrimary(from: appDelegate.paletteManager))
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 800)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                // Bring main window to front when app is activated
                if let mainWindow = NSApp.windows.first {
                    mainWindow.makeKeyAndOrderFront(nil)
                }
            }
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appDelegate.navigationHandler.navigateToSettings()
                    // Bring main window to front
                    if let mainWindow = NSApp.windows.first(where: { $0.title == "AltType" }) {
                        mainWindow.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                .keyboardShortcut(",")
            }
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    private weak var currentPopover: NSPopover?
    let transcriptionStore = TranscriptionStore() // Shared store instance
    let hotkeySettings: any HotkeySettingsProtocol // Protocol-based DI
    let permissionManager: any PermissionServiceProtocol // Protocol-based DI
    let paletteManager = PaletteManager() // Create a single instance for the app
    let speechEngineSettings = SpeechEngineSettings() // Shared speech engine settings
    let debugConfiguration = DebugConfiguration.shared // Debug configuration
    let featureFlagManager = FeatureFlagManager.shared // Feature flag manager
    let navigationHandler = NavigationHandler() // Navigation state management
    private(set) lazy var speechEngineManager: SpeechEngineManager = {
        SpeechEngineManager()
    }()
    private var _appCoordinator: AppCoordinator?
    var appCoordinator: AppCoordinator {
        if let coordinator = _appCoordinator {
            return coordinator
        }
        let coordinator = AppCoordinator(statusItem: statusItem, transcriptionStore: transcriptionStore, hotkeySettings: hotkeySettings, permissionManager: permissionManager, speechEngineManager: speechEngineManager, speechEngineSettings: speechEngineSettings)
        _appCoordinator = coordinator
        return coordinator
    }

    // MARK: - Initialization

    override init() {
        // CRITICAL: Initialize DI container FIRST before creating any services
        AppConfigurationBootstrap.initialize()

        // Protocol-based DI
        if AppServices.AppConfiguration.current.features.supportsHotkeys {
            self.hotkeySettings = HotkeySettings()
        } else {
            self.hotkeySettings = NoOpHotkeySettings()
        }

        // Protocol-based DI: PermissionManager (checks Microphone + Accessibility)
        self.permissionManager = AppServices.AppConfiguration.current.createPermissionService()

        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("📱 AltType launched")
        // Note: DI container already initialized in init()

        // Create status bar item for menu bar functionality
        setupStatusBar()

        // Setup the main app coordinator for global hotkeys - now that statusItem exists
        setupAppCoordinator()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when main window is closed - we're a menu bar app
        return false
    }
    
    // Window management moved to SwiftUI scene phase monitoring
    
    private func setupStatusBar() {
        print("📱 Setting up status bar item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
            button.toolTip = "AltType - Voice to Text"
            
            // Set up button action to test clicking
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            
            print("✅ Status bar button configured with image and action")
        } else {
            print("❌ Failed to get status bar button")
        }
        
        print("✅ Status bar item created: \(statusItem != nil ? "SUCCESS" : "FAILED")")
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        print("🎯 STATUS BAR BUTTON CLICKED!")
        
        // Toggle behavior: if popover is already showing, close it
        if let popover = currentPopover, popover.isShown {
            popover.close()
            currentPopover = nil
        } else {
            // Show SwiftUI menu bar view in a popover
            showSwiftUIMenuBar(from: sender)
        }
        
        print("SwiftUI menu shown from status bar click")
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        currentPopover = nil
        print("📱 Popover closed and cleaned up")
    }
    
    // MARK: - Application Delegate Methods for Popover Management
    
    func applicationWillResignActive(_ notification: Notification) {
        // Close popover when app loses focus (additional safety net)
        if let popover = currentPopover, popover.isShown {
            popover.close()
            print("📱 Popover closed due to app losing focus")
        }
    }
    
    private func showSwiftUIMenuBar(from button: NSStatusBarButton) {
        // Dismiss any existing popover first
        currentPopover?.close()
        
        // Create a new popover for the menu content
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 500)
        popover.behavior = .transient  // Automatically closes when clicking outside
        popover.animates = true
        
        // Store reference to current popover for proper management
        currentPopover = popover
        
        // Create the SwiftUI view with all required environment objects
        let menuBarView = MenuBarView()
            .environmentObject(appCoordinator)
            .environmentObject(paletteManager)
            .environment(\.hotkeySettings, hotkeySettings) // Custom environment value
            .environmentObject(navigationHandler)
        
        // Create the hosting controller
        let hostingController = NSHostingController(rootView: menuBarView)
        popover.contentViewController = hostingController
        
        // Set up popover delegate for proper cleanup
        popover.delegate = self
        
        // CRITICAL: Activate the app first for proper dismissal behavior
        NSApp.activate(ignoringOtherApps: true)
        
        // Show the popover
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // CRITICAL: Make the popover window key for transient behavior to work
        popover.contentViewController?.view.window?.makeKey()
    }
    
    // Legacy NSMenu implementation - now replaced by SwiftUI
    // Keeping for reference but no longer used
    private func createStatusMenuLegacy() -> NSMenu {
        // This method is now replaced by showSwiftUIMenuBar
        // Keeping for potential fallback scenarios
        return NSMenu()
    }
    
    
    // MARK: - Legacy Menu Actions (kept for compatibility)
    
    @objc private func openSettings() {
        navigateToSettings()
    }
    
    @objc private func openHotkeySettings() {
        navigateToSettings(specificSection: "hotkey")
    }
    
    @objc private func openHelpDoc() {
        navigateToHelp()
    }
    
    private func navigateToSettings(specificSection: String? = nil) {
        // Navigate using NavigationHandler
        navigationHandler.navigateToSettings(section: specificSection)
        
        // Bring main window to front
        bringMainWindowToFront()
        print("Menu: Navigating to settings\(specificSection != nil ? " (\(specificSection!))" : "")")
    }
    
    private func navigateToHelp() {
        // Navigate using NavigationHandler
        navigationHandler.navigateToHelp()
        
        // Bring main window to front
        bringMainWindowToFront()
        print("Menu: Navigating to help")
    }
    
    private func bringMainWindowToFront() {
        if let mainWindow = NSApp.windows.first(where: { $0.title == "AltType" }) {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "AltType"
        alert.informativeText = "Transform speech to text instantly\n\nA privacy-first voice-to-text application with fully on-device processing."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        print("Quitting app from menu")
        NSApplication.shared.terminate(nil)
    }
    
    
    private func setupAppCoordinator() {
        print("📱 Setting up AppCoordinator...")
        // AppCoordinator is created lazily, just start it
        print("📱 Starting AppCoordinator...")

        // Check if onboarding is complete before signaling user intent
        // During onboarding, we don't want to trigger hotkey registration yet
        let isOnboardingComplete = UserDefaults.standard.bool(forKey: "OnboardingCompleted")

        if isOnboardingComplete {
            // Signal user intent - user explicitly launched the app
            appCoordinator.signalUserIntent(source: "App launched by user")
        } else {
            print("⏸️ Onboarding not complete - skipping user intent signal to prevent premature permission requests")
        }

        appCoordinator.start()

        // Setup system wake monitoring for energy optimization
        setupSystemWakeMonitoring()

        print("📱 AppCoordinator setup complete")
    }

    private func setupSystemWakeMonitoring() {
        // Monitor system wake events for smart energy management
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🌅 System wake detected - signaling potential user activity")
            Task { @MainActor in
                self?.appCoordinator.handleSystemWake()
            }
        }
        print("🌅 System wake monitoring enabled")
    }
}
