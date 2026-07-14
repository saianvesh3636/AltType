import SwiftUI
import AppServices
import SpeechKit

struct OnboardingView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var paletteManager: PaletteManager
    @EnvironmentObject var speechEngineManager: SpeechEngineManager
    @State private var appBecameActiveObserver: NSObjectProtocol?

    init(coordinator: OnboardingCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator - shows only the visible steps
            HStack {
                ForEach(0..<coordinator.visibleSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= coordinator.visibleStepIndex ? Color.appAccent(from: paletteManager) : Color.appOnSurface(from: paletteManager).opacity(0.3))
                        .frame(width: 12, height: 12)

                    if index < coordinator.visibleSteps.count - 1 {
                        Rectangle()
                            .fill(index < coordinator.visibleStepIndex ? Color.appAccent(from: paletteManager) : Color.appOnSurface(from: paletteManager).opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal, 80)
            .padding(.top, 40)

            Spacer()

            // Main content
            VStack(spacing: 30) {
                stepContent
            }
            .padding(.horizontal, 60)

            Spacer()

            // Bottom action area
            VStack(spacing: 20) {
                actionButton

                if coordinator.currentStep != .welcome && coordinator.currentStep != .complete {
                    statusText
                }

                // Show helpful text when waiting for accessibility permission
                if coordinator.isProcessing && coordinator.currentStep == .accessibility {
                    Text("Enable the permission in System Settings, then return to this window")
                        .font(.caption)
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground(from: paletteManager))
    }

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 20) {
            stepIcon

            VStack(spacing: 12) {
                Text(coordinator.currentStep.title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appOnBackground(from: paletteManager))
                    .multilineTextAlignment(.center)

                Text(coordinator.currentStep.description)
                    .font(.body)
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }

            // Special content for complete step
            if coordinator.currentStep == .complete {
                completeStepContent
            }
        }
        .onAppear {
            // Use NSApplication notification instead of scene phase for reliable macOS detection
            appBecameActiveObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak coordinator] _ in
                Task { @MainActor in
                    coordinator?.handleAppBecameActive()
                }
            }
        }
        .onDisappear {
            // Clean up notification observer
            if let observer = appBecameActiveObserver {
                NotificationCenter.default.removeObserver(observer)
                appBecameActiveObserver = nil
            }
        }
    }

    @ViewBuilder
    private var stepIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 80, height: 80)

            Image(systemName: iconName)
                .font(.system(size: 35))
                .foregroundColor(iconForegroundColor)
        }
    }

    private var iconName: String {
        switch coordinator.currentStep {
        case .welcome:
            return "waveform"
        case .microphone:
            return "mic.fill"
        case .accessibility:
            return "hand.raised.fill"
        case .complete:
            return "checkmark"
        }
    }

    private var iconBackgroundColor: Color {
        switch coordinator.currentStep {
        case .welcome:
            return Color.appPrimary(from: paletteManager).opacity(0.1)
        case .microphone:
            return coordinator.permissionState.microphoneGranted ? Color.appSuccess(from: paletteManager).opacity(0.1) : Color.appSecondary(from: paletteManager).opacity(0.1)
        case .accessibility:
            return coordinator.permissionState.accessibilityGranted ? Color.appSuccess(from: paletteManager).opacity(0.1) : Color.appSecondary(from: paletteManager).opacity(0.1)
        case .complete:
            return Color.appSuccess(from: paletteManager).opacity(0.1)
        }
    }

    private var iconForegroundColor: Color {
        switch coordinator.currentStep {
        case .welcome:
            return Color.appPrimary(from: paletteManager)
        case .microphone:
            return coordinator.permissionState.microphoneGranted ? Color.appSuccess(from: paletteManager) : Color.appSecondary(from: paletteManager)
        case .accessibility:
            return coordinator.permissionState.accessibilityGranted ? Color.appSuccess(from: paletteManager) : Color.appSecondary(from: paletteManager)
        case .complete:
            return Color.appSuccess(from: paletteManager)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        Button(action: {
            coordinator.nextStep()
        }) {
            HStack {
                if coordinator.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(Color.appOnPrimary(from: paletteManager))
                }

                Text(coordinator.isProcessing ? "Please wait..." : coordinator.currentStep.buttonTitle)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appOnPrimary(from: paletteManager))
            }
            .frame(maxWidth: 300)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(coordinator.isProcessing)
    }

    @ViewBuilder
    private var statusText: some View {
        HStack {
            Image(systemName: permissionStatusIcon)
                .foregroundColor(permissionStatusColor)

            Text(permissionStatusText)
                .font(.caption)
                .foregroundColor(permissionStatusColor)
        }
    }

    private var permissionStatusIcon: String {
        switch coordinator.currentStep {
        case .microphone:
            return coordinator.permissionState.microphoneGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        case .accessibility:
            return coordinator.permissionState.accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        default:
            return "info.circle.fill"
        }
    }

    private var permissionStatusColor: Color {
        switch coordinator.currentStep {
        case .microphone:
            return coordinator.permissionState.microphoneGranted ? Color.appSuccess(from: paletteManager) : Color.appSecondary(from: paletteManager)
        case .accessibility:
            return coordinator.permissionState.accessibilityGranted ? Color.appSuccess(from: paletteManager) : Color.appSecondary(from: paletteManager)
        default:
            return Color.appPrimary(from: paletteManager)
        }
    }

    private var permissionStatusText: String {
        switch coordinator.currentStep {
        case .microphone:
            return coordinator.permissionState.microphoneGranted ? "Microphone enabled" : "Microphone permission needed for voice transcription"
        case .accessibility:
            return coordinator.permissionState.accessibilityGranted ? "Accessibility enabled" : "Accessibility permission needed"
        default:
            return ""
        }
    }

    @ViewBuilder
    private var completeStepContent: some View {
        VStack(spacing: 32) {
            // Hotkey instruction
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 24))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))

                    Text("Press")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))

                    Text("fn")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.appOnPrimary(from: paletteManager))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appPrimary(from: paletteManager))
                        )

                    Text("to start/stop dictation")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSurface(from: paletteManager))
                )
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "mic.fill",
                    title: "Voice-to-Text Anywhere",
                    description: "Dictate in any app on your computer — no switching required"
                )

                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Private & On-Device",
                    description: "Your voice never leaves your device — all processing is local"
                )

                FeatureRow(
                    icon: "bolt.fill",
                    title: "Fast & Accurate",
                    description: "Real-time transcription with high accuracy using advanced models"
                )

                FeatureRow(
                    icon: "app.connected.to.app.below.fill",
                    title: "Works Everywhere",
                    description: "Use in any app with text fields across your computer"
                )
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: 600)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @EnvironmentObject var paletteManager: PaletteManager

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.appPrimary(from: paletteManager))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.appOnBackground(from: paletteManager))

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
