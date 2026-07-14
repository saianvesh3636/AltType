import SwiftUI
import AppKit
import Combine
import AppServices
import SpeechKit

struct ContentView: View {
    @EnvironmentObject var navigationHandler: NavigationHandler
    @State private var selectedTab: SidebarItem = .home
    @EnvironmentObject var transcriptionStore: TranscriptionStore
    @Environment(\.hotkeySettings) var hotkeySettings // Custom environment value (protocol-based)
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var paletteManager: PaletteManager
    @EnvironmentObject var speechEngineSettings: SpeechEngineSettings
    @EnvironmentObject var speechEngineManager: SpeechEngineManager
    @StateObject private var appearanceSettings = AppearanceSettings()
    @State private var isListening = false
    @Environment(\.colorScheme) var systemColorScheme
    @State private var showOnboarding = false
    @State private var onboardingCoordinator: OnboardingCoordinator?
    @State private var onboardingCompleted = false
    @State private var hasCheckedOnboarding = false
    @Environment(\.features) var features

    let permissionManager: any PermissionServiceProtocol

    var body: some View {
        Group {
            if showOnboarding, let coordinator = onboardingCoordinator {
                OnboardingView(coordinator: coordinator)
                    .environmentObject(paletteManager)
                    .environmentObject(speechEngineManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground(from: paletteManager))
            } else {
                ZStack {
                    NavigationSplitView {
                        SidebarView(
                            selectedTab: $selectedTab
                        )
                        .toolbar {
                            // Empty toolbar for sidebar
                        }
                    } detail: {
                        mainContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.appBackground(from: paletteManager))
                            .environmentObject(appearanceSettings)
                            .preferredColorScheme(appearanceSettings.preferredMode == .system ? nil :
                                                (appearanceSettings.preferredMode == .dark ? .dark : .light))
                    }
                    .navigationSplitViewStyle(.automatic)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
                    .toolbarBackground(.visible, for: .windowToolbar)
                }
            }
        }
        .environment(\.appColors, AppColors(
            primary: Color.appPrimary(from: paletteManager),
            secondary: Color.appSecondary(from: paletteManager),
            warning: Color.appWarning(from: paletteManager),
            error: Color.appError(from: paletteManager)
        ))
        .task {
            // Run onboarding check only once at app launch
            if !hasCheckedOnboarding {
                hasCheckedOnboarding = true
                checkIfOnboardingNeeded()
            }
        }
        .onAppear {
            // Signal user intent when main window appears (but not during onboarding)
            let isOnboardingComplete = UserDefaults.standard.bool(forKey: "OnboardingCompleted")
            if isOnboardingComplete {
                appCoordinator.signalUserIntent(source: "Main window opened")
            } else {
                print("⏸️ [ContentView.onAppear] Onboarding not complete - skipping user intent signal")
            }
            updateListeningState(appCoordinator.state)
        }
        .onChange(of: appCoordinator.state) { _, newState in
            updateListeningState(newState)
        }
        .onChange(of: navigationHandler.navigationRequest) { _, newTab in
            if let newTab = newTab {
                // Signal user intent on tab navigation
                appCoordinator.signalUserIntent(source: "Tab navigation to \(newTab)")
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = newTab
                }
                // Reset the navigation request
                navigationHandler.navigationRequest = nil
            }
        }
        .onChange(of: onboardingCompleted) { _, completed in
            if completed {
                withAnimation(.easeInOut) {
                    showOnboarding = false
                }
                // Complete post-onboarding setup (register hotkey, etc.)
                appCoordinator.completePostOnboardingSetup()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToSettings"))) { _ in
            navigationHandler.navigateToSettings()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .home:
            HomeView(
                appCoordinator: appCoordinator,
                isListening: $isListening
            )
            .id("home")
        case .history:
            HistoryView()
                .id("history")
        case .settings:
            ImprovedSettingsMainView(permissionManager: permissionManager)
                .environmentObject(appearanceSettings)
                .id("settings")
                .onAppear {
                    appCoordinator.signalUserIntent(source: "Settings accessed")
                }
        case .help:
            HelpView()
                .id("help")
        }
    }

    private func updateListeningState(_ state: AppState) {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch state {
            case .listening:
                isListening = true
            case .idle, .error:
                isListening = false
            }
        }
    }
    
    private func checkIfOnboardingNeeded() {
        let isOnboardingCompletedInDefaults = UserDefaults.standard.bool(forKey: "OnboardingCompleted")
        
        if !isOnboardingCompletedInDefaults {
            // Create onboarding coordinator with completion handler
            onboardingCoordinator = OnboardingCoordinator(permissionManager: permissionManager) {
                // When onboarding completes, update our state
                DispatchQueue.main.async {
                    onboardingCompleted = true
                }
            }

            showOnboarding = true
        }
    }
}

@MainActor
class NavigationHandler: ObservableObject {
    @Published var navigationRequest: SidebarItem?
    
    init() {}
    
    func navigateToSettings(section: String? = nil) {
        navigationRequest = .settings
        if let section = section {
            print("Navigating to settings section: \(section)")
        }
    }
    
    func navigateToHelp() {
        navigationRequest = .help
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case history = "History"
    case settings = "Settings"
    case help = "Help"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "clock.fill"
        case .settings: return "gear"
        case .help: return "questionmark.circle"
        }
    }
}


// // #Preview {
//     ContentView(permissionManager: PermissionManager.shared)
//         .frame(width: 1000, height: 700)
// }
