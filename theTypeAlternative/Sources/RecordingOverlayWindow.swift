import SwiftUI
import AppKit
import AppServices

class RecordingOverlayWindow: NSWindow {

    init(permissionManager: any PermissionServiceProtocol) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 50),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent(permissionManager: permissionManager)
    }

    private func setupWindow() {
        backgroundColor = .clear
        isOpaque = false
        // Window-level shadow must stay off: on a transparent window macOS renders a
        // stale gray shadow rectangle behind the animated island. The SwiftUI view
        // draws its own shadow instead.
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        ignoresMouseEvents = false
    }

    private func setupContent(permissionManager: any PermissionServiceProtocol) {
        let hostingView = NSHostingView(rootView: RecordingOverlayView(permissionManager: permissionManager))
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        contentView = hostingView
    }
}

struct RecordingOverlayView: View {
    private let permissionManager: any PermissionServiceProtocol
    @State private var pulseAnimation = false
    @State private var overallState: OverallPermissionState = .checking

    init(permissionManager: any PermissionServiceProtocol) {
        self.permissionManager = permissionManager
    }

    private var islandState: IslandVisualState {
        switch overallState {
        case .needsMicrophone, .needsAccessibility, .needsBoth:
            return .permissionError
        case .ready:
            return .listening
        case .checking:
            return .checking
        case .error:
            return .permissionError
        }
    }
    
    private enum IslandVisualState {
        case listening
        case permissionError
        case checking
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                stateSpecificContent
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(backgroundColor)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
                .onTapGesture {
                    handleIslandTap()
                }
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(permissionManager.overallStatePublisher) { newState in
            overallState = newState
        }
        .onAppear {
            overallState = permissionManager.overallState
        }
    }
    
    // MARK: - State-Specific Content
    
    @ViewBuilder
    private var stateSpecificContent: some View {
        switch islandState {
        case .listening:
            listeningContent
        case .permissionError:
            permissionErrorContent
        case .checking:
            checkingContent
        }
    }
    
    private var listeningContent: some View {
        // Current audio visualization bars
        HStack(spacing: 3) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 3, height: CGFloat.random(in: 4...10))
                    .animation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true).delay(Double(index) * 0.05), value: pulseAnimation)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var permissionErrorContent: some View {
        HStack(spacing: 8) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            
            // Error message
            Text(permissionErrorMessage)
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
    }
    
    private var checkingContent: some View {
        HStack(spacing: 8) {
            // Loading indicator
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Checking...")
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .medium))
        }
    }
    
    // MARK: - Visual Properties
    
    private var backgroundColor: Color {
        switch islandState {
        case .permissionError:
            return Color.red.opacity(0.15)
        case .checking:
            return Color.orange.opacity(0.1)
        case .listening:
            return Color.black.opacity(0.8)  // Current design
        }
    }
    
    private var borderColor: Color {
        switch islandState {
        case .permissionError:
            return Color.red.opacity(0.8)
        case .checking:
            return Color.orange.opacity(0.6)
        case .listening:
            return Color.white.opacity(0.3)  // Current design
        }
    }
    
    private var borderWidth: CGFloat {
        switch islandState {
        case .permissionError:
            return 2  // Thicker border for attention
        case .checking:
            return 1.5
        case .listening:
            return 1  // Current design
        }
    }
    
    private var shadowColor: Color {
        switch islandState {
        case .permissionError:
            return Color.red.opacity(0.4)
        case .checking:
            return Color.orange.opacity(0.3)
        case .listening:
            return Color.black.opacity(0.3)  // Current design
        }
    }
    
    private var permissionErrorMessage: String {
        switch overallState {
        case .needsMicrophone:
            return "Mic needed"
        case .needsAccessibility:
            return "Input Monitoring needed"
        case .needsBoth:
            return "Permissions needed"
        default:
            return "Error"
        }
    }
    
    // MARK: - Interaction Handling
    
    private func handleIslandTap() {
        switch islandState {
        case .permissionError:
            handlePermissionError()
        case .listening, .checking:
            // No interaction for these states
            break
        }
    }
    
    private func handlePermissionError() {
        switch overallState {
        case .needsMicrophone:
            Task {
                let granted = await permissionManager.requestMicrophone()
                if !granted {
                    permissionManager.openSystemSettings(for: PermissionType.microphone)
                }
            }
        case .needsAccessibility:
            permissionManager.openSystemSettings(for: PermissionType.accessibility)
        case .needsBoth:
            Task {
                let micGranted = await permissionManager.requestMicrophone()
                if micGranted {
                    permissionManager.openSystemSettings(for: PermissionType.accessibility)
                } else {
                    permissionManager.openSystemSettings(for: PermissionType.microphone)
                }
            }
        default:
            break
        }
    }
}

// // #Preview {
//     RecordingOverlayView(permissionManager: PermissionManager.shared)
//         .frame(width: 200, height: 50)
//         .background(Color.gray.opacity(0.3))
// }
