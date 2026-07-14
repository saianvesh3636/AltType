import SwiftUI
import AppKit
import Carbon
import AppServices
import SpeechKit


struct HomeView: View {
    @ObservedObject var appCoordinator: AppCoordinator
    @Binding var isListening: Bool
    @EnvironmentObject var transcriptionStore: TranscriptionStore
    @Environment(\.hotkeySettings) var hotkeySettings
    @Environment(\.features) var features
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    @EnvironmentObject var paletteManager: PaletteManager
    @Environment(\.colorScheme) var systemColorScheme
    
    @State private var isTransitioning = false
    @State private var showSuccessFeedback = false
    @State private var successMessage = ""
    @State private var lastTranscriptionCount = 0
    
    // Performance: Track if app is in foreground to optimize animations
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 32) { // 8pt grid: 32 = 8 * 4
                    headerSection
                    mainControlCard
                    recentActivitySection

                    Spacer(minLength: 32) // 8pt grid: 32 = 8 * 4
                }
                .padding(.top, 20) // Add top padding for navigation bar spacing
            }
            .background(Color.appBackground(from: paletteManager))
            .overlay(successToastOverlay)
            .onAppear { setupView() }
            .onChange(of: appCoordinator.state) { oldState, newState in
                handleStateChange(newState)
            }

        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        // Header content removed since navigation title now handles this
        EmptyView()
    }
    
    @ViewBuilder 
    private var mainControlCard: some View {
        VStack(spacing: 24) { // 8pt grid: 24 = 8 * 3
                    // Status Display - Enhanced with permission handling
                    VStack(spacing: 16) { // 8pt grid: 16 = 8 * 2
                        // Status indicator - clickable when permissions needed
                        statusIndicatorButton
                        
                        VStack(spacing: 8) { // 8pt grid
                            Text(statusTitle)
                                .font(.system(.title2, design: .default, weight: .semibold))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statusTitle)
                                .id("status-title-\(statusTitle)")
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            
                            Text(statusSubtitle)
                                .font(.system(.subheadline, design: .default, weight: .regular))
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: statusSubtitle)
                                .id("status-subtitle-\(statusSubtitle.hashValue)")
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Live Transcription removed - now handled in Recent Activity with edit capability
                    
                    // Primary Action - Streamlined following Apple Design Award patterns
                    VStack(spacing: 16) { // 8pt grid: 16 = 8 * 2
                        // Main CTA Button - Task-focused design with hover effects
                        Button(action: toggleListening) {
                            HStack(spacing: 12) { // 8pt grid: 12 = 8 * 1.5
                                Group {
                                    if isTransitioning {
                                        Image(systemName: reduceMotion ? "hourglass" : "arrow.triangle.2.circlepath")
                                            .font(.system(size: 20, weight: .semibold))
                                            .rotationEffect(.degrees(isTransitioning && !reduceMotion ? 360 : 0))
                                            .animation(!reduceMotion ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: isTransitioning)
                                    } else {
                                        Image(systemName: isListening ? "stop.fill" : "mic.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .symbolEffect(.bounce, options: .nonRepeating, value: isListening)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.2), value: isTransitioning)
                                
                                Text(isTransitioning ? "Processing..." : (isListening ? "Stop Listening" : "Start Listening"))
                                    .font(.system(.title2, design: .default, weight: .semibold))
                                    .animation(.easeInOut(duration: 0.2), value: isTransitioning)
                            }
                            .foregroundColor(Color.appOnPrimary(from: paletteManager))
                            .frame(maxWidth: 280) // Constrain width for better proportions
                            .padding(.horizontal, 40) // 8pt grid: 40 = 8 * 5
                            .padding(.vertical, 20) // 8pt grid: 20 = 8 * 2.5
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isListening ? Color.appError(from: paletteManager).gradient : Color.appPrimary(from: paletteManager).gradient)
                                    .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.15), radius: 6, x: 0, y: 3)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isListening)
                            )
                        }
                        .buttonStyle(HoverableButtonStyle())
                        .disabled(!canToggle)
                        .scaleEffect(isListening ? 1.05 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isListening)
                        
                        // Secondary Actions - Only show when relevant
                        if !transcriptionStore.transcriptionHistory.isEmpty {
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    transcriptionStore.clearHistory()
                                }
                                
                                // Show success feedback
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    successMessage = "History cleared!"
                                    showSuccessFeedback = true
                                }
                                
                                // Hide success feedback after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showSuccessFeedback = false
                                    }
                                }
                            }) {
                                HStack(spacing: 8) { // 8pt grid
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Clear History")
                                        .font(.system(.callout, design: .default, weight: .medium))
                                }
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                                .padding(.horizontal, 16) // 8pt grid: 16 = 8 * 2
                                .padding(.vertical, 8) // 8pt grid
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appSurface(from: paletteManager))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.appOnSurface(from: paletteManager).opacity(0.2), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(SubtleHoverButtonStyle())
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        if let hotkeySettings = hotkeySettings, features.supportsHotkeys {
                            HStack(spacing: 8) {
                                Image(systemName: "keyboard")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))

                                Text("Press")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))

                                Text(hotkeySettings.displayName)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.appSecondary(from: paletteManager).opacity(0.3))
                                    )
                                    .foregroundColor(Color.appOnSurface(from: paletteManager))

                                Text("to toggle globally")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
                            }
                            .padding(.top, 8)
                        }
                    }
        }
        .padding(32) // 8pt grid: 32 = 8 * 4
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface(from: paletteManager))
                .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 32) // 8pt grid: 32 = 8 * 4
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        if !transcriptionStore.transcriptionHistory.isEmpty {
            RecentActivityCard(transcriptionHistory: transcriptionStore.transcriptionHistory)
                .padding(.horizontal, 32) // 8pt grid: 32 = 8 * 4
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: transcriptionStore.transcriptionHistory.count)
        }
    }
    
    @ViewBuilder
    private var successToastOverlay: some View {
        VStack {
            if showSuccessFeedback {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.appSuccess(from: paletteManager))
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(successMessage)
                        .font(.system(.callout, design: .default, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appSurface(from: paletteManager))
                        .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.1), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.appSuccess(from: paletteManager).opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Functions
    private func setupView() {
        // Initialize with current transcription count to prevent showing "Text inserted" on app launch
        lastTranscriptionCount = transcriptionStore.transcriptionHistory.count
    }
    
    private func handleStateChange(_ newState: AppState) {
        updateListeningState(newState)
        
        // Handle successful transcription feedback - only show when new text was actually transcribed
        if case .idle = newState {
            let currentTranscriptionCount = transcriptionStore.transcriptionHistory.count
            if currentTranscriptionCount > lastTranscriptionCount {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    successMessage = "Text inserted"
                    showSuccessFeedback = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSuccessFeedback = false
                    }
                }
            }
            lastTranscriptionCount = currentTranscriptionCount
        }
    }
    
    private func updateListeningState(_ state: AppState) {
        switch state {
        case .listening:
            isListening = true
            isTransitioning = false
        case .idle, .error:
            isListening = false
            isTransitioning = false
        }
    }
    
    
    
    
    // Removed colorTheme dependency - now using new semantic color system
    
    @ViewBuilder
    private var statusIndicatorButton: some View {
        Button(action: {
            if case .error(let error) = appCoordinator.state {
                handlePermissionError(error)
            }
        }) {
            ZStack {
                statusIndicatorCircles
                statusIndicatorIcon
                errorOverlayIcon
            }
        }
        .buttonStyle(HoverableButtonStyle())
        .disabled(canToggle)
    }
    
    @ViewBuilder
    private var statusIndicatorCircles: some View {
        // Subtle outer glow for listening state only
        if isListening && scenePhase == .active && !reduceMotion {
            Circle()
                .fill(statusColor.opacity(0.1))
                .frame(width: 65, height: 65)
                .scaleEffect(1.05)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isListening)
                .transition(.scale.combined(with: .opacity))
        }
        
        Circle()
            .fill(statusColor.opacity(0.08))
            .frame(width: 60, height: 60)
            .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.1), radius: 3, x: 0, y: 1)
        
        Circle()
            .stroke(statusColor, lineWidth: 1.5)
            .frame(width: 50, height: 50)
            .scaleEffect(isListening && scenePhase == .active && !reduceMotion ? 1.02 : 1.0)
            .animation(isListening && !reduceMotion && scenePhase == .active ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: isListening)
    }
    
    @ViewBuilder
    private var statusIndicatorIcon: some View {
        Image(systemName: statusIcon)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(statusColor)
            .symbolEffect(.variableColor.iterative, isActive: isListening)
            .symbolEffect(.pulse, options: .repeating, isActive: isTransitioning)
            .scaleEffect(isListening ? 1.02 : 1.0)
            .animation(isListening ? .easeInOut(duration: 0.3) : .none, value: isListening)
    }
    
    @ViewBuilder
    private var errorOverlayIcon: some View {
        if case .error = appCoordinator.state {
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "gear.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appError(from: paletteManager))
                        .background(Circle().fill(Color.appBackground(from: paletteManager)).frame(width: 14, height: 14))
                }
                Spacer()
            }
            .frame(width: 60, height: 60)
        }
    }
    
    private var statusColor: Color {
        switch appCoordinator.state {
        case .idle: return Color.appSuccess(from: paletteManager)
        case .listening: return Color.appAccent(from: paletteManager)
        case .error: return Color.appError(from: paletteManager)
        }
    }
    
    private var statusIcon: String {
        switch appCoordinator.state {
        case .idle: return "mic.fill"
        case .listening: return "waveform"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusTitle: String {
        switch appCoordinator.state {
        case .idle: return "Ready to Listen"
        case .listening: return "Listening..."
        case .error(let error): 
            switch error {
            case .microphonePermissionDenied:
                return "Microphone Permission Needed"
            case .accessibilityPermissionDenied:
                return "Accessibility Access Needed"
            default:
                return "Error"
            }
        }
    }
    
    private var statusSubtitle: String {
        switch appCoordinator.state {
        case .idle:
            if let hotkeySettings = hotkeySettings, AppServices.AppConfiguration.current.features.supportsHotkeys {
                return "Click the button or press \(hotkeySettings.displayName) to start"
            } else {
                return "Click the button to start"
            }
        case .listening: return "Speak now, your voice will be transcribed"
        case .error(let error):
            switch error {
            case .microphonePermissionDenied:
                return "Tap here to open microphone settings"
            case .accessibilityPermissionDenied:
                return "Tap here to open accessibility settings"
            default:
                return error.localizedDescription
            }
        }
    }
    
    private var canToggle: Bool {
        switch appCoordinator.state {
        case .idle, .listening: return true
        case .error: return false
        }
    }
    
    private var isErrorState: Bool {
        if case .error = appCoordinator.state {
            return true
        }
        return false
    }
    
    
    
    private func toggleListening() {
        // Check if we're in an error state
        if case .error(let error) = appCoordinator.state {
            handlePermissionError(error)
            return
        }
        
        // Show loading animation
        withAnimation(.easeInOut(duration: 0.2)) {
            isTransitioning = true
        }
        
        switch appCoordinator.state {
        case .idle:
            appCoordinator.startListening()
        case .listening:
            appCoordinator.stopListening()
        case .error:
            break
        }
        
        // Reset transition state after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isTransitioning = false
            }
        }
    }
    
    private func handlePermissionError(_ error: AppError) {
        // Delegate to AppCoordinator which already has the complete permission handling logic
        appCoordinator.handlePermissionError(error)
    }
    
    
}



struct RecentActivityCard: View {
    let transcriptionHistory: [TranscriptionEntry]
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            recentActivityList
        }
        .padding(24)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private var headerView: some View {
        Text("Recent Activity")
            .font(.system(.headline, design: .default, weight: .semibold))
            .foregroundColor(Color.appOnSurface(from: paletteManager))
    }
    
    @ViewBuilder
    private var recentActivityList: some View {
        LazyVStack(spacing: 16) {
            ForEach(transcriptionHistory.prefix(3)) { entry in
                activityRow(for: entry)
            }
        }
    }
    
    @ViewBuilder
    private func activityRow(for entry: TranscriptionEntry) -> some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.appAccent(from: paletteManager))
                .frame(width: 4, height: 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.text)
                    .font(.system(.body, design: .default, weight: .regular))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(entry.formattedTime)
                    .font(.system(.caption, design: .default, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            }
            
            Spacer()
            
            Button(action: { copyToClipboard(entry.text) }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(.caption, design: .default, weight: .medium))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .padding(8)
            }
            .buttonStyle(IconHoverButtonStyle())
            .help("Copy to clipboard")
        }
        .padding(16)
        .background(entryBackground)
        .overlay(entryBorder)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.appSurface(from: paletteManager))
            .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var entryBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.appSurface(from: paletteManager))
            .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var entryBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 0.5)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// // #Preview {
//     let store = TranscriptionStore()
//     let hotkeySettings = HotkeySettings()
//     let permissionManager = PermissionManager()
//     let speechEngineManager = SpeechEngineManager()
//     let speechEngineSettings = SpeechEngineSettings()
//     let tierManager = TierManager.shared
//     let paletteManager = PaletteManager()
//     let appearanceSettings = AppearanceSettings()
//     
//     HomeView(
//         appCoordinator: AppCoordinator(
//             statusItem: nil, 
//             transcriptionStore: store, 
//             hotkeySettings: hotkeySettings, 
//             permissionManager: permissionManager,
//             speechEngineManager: speechEngineManager,
//             speechEngineSettings: speechEngineSettings,
//             tierManager: tierManager
//         ),
//         isListening: .constant(false),
//         showAccountOverlay: .constant(false),
//         openSubscriptionTab: nil
//     )
//     .environmentObject(store)
//     .environmentObject(hotkeySettings)
//     .environmentObject(permissionManager)
//     .environmentObject(speechEngineManager)
//     .environmentObject(tierManager)
//     .environmentObject(paletteManager)
//     .environmentObject(appearanceSettings)
//     .frame(width: 800, height: 600)
// }

// MARK: - Enhanced Button Styles

struct HoverableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovering && !reduceMotion ? 1.02 : 1.0))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .shadow(
                color: configuration.isPressed ? Color.black.opacity(0.1) : Color.black.opacity(0.15),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
    }
}

struct SubtleHoverButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : (isHovering && !reduceMotion ? 1.01 : 1.0))
            .opacity(configuration.isPressed ? 0.8 : (isHovering ? 0.9 : 1.0))
            .background(
                // Material-inspired subtle background glow on hover
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.white.opacity(0.1) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
    }
}


struct TextHoverButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : (isHovering ? 0.8 : 1.0))
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.white.opacity(0.05) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
    }
}

// MARK: - Material-Inspired Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovering && !reduceMotion ? 1.02 : 1.0))
            .background(
                ZStack {
                    // Glass background with blur effect
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? 
                              Color.white.opacity(0.1) : 
                              Color.black.opacity(0.05))
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(isHovering ? 0.2 : 0.1),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border highlight
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(
                    color: configuration.isPressed ? 
                           Color.black.opacity(0.1) : 
                           Color.black.opacity(0.2),
                    radius: configuration.isPressed ? 5 : 10,
                    x: 0,
                    y: configuration.isPressed ? 2 : 5
                )
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.3), value: isHovering)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHovering = hovering
                }
            }
    }
}


