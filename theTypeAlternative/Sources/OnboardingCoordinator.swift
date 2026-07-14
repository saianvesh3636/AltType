import Foundation
import AVFoundation
import AppKit
import SwiftUI
import AppServices
@preconcurrency import ApplicationServices

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case microphone = 1
    case accessibility = 2
    case complete = 3

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to AltType"
        case .microphone:
            return "Microphone"
        case .accessibility:
            return "Accessibility Access"
        case .complete:
            return "You're All Set!"
        }
    }

    var description: String {
        switch self {
        case .welcome:
            return "AltType brings voice-to-text transcription to any app on your computer. Let's set up the required permissions to get started."
        case .microphone:
            return "AltType uses your microphone to transcribe speech into text. All processing happens on-device — your voice data never leaves your computer."
        case .accessibility:
            return "Accessibility permission allows AltType to insert transcribed text into other applications and capture the global hotkey (fn) that starts dictation."
        case .complete:
            return ""  // Description shown in custom complete content
        }
    }

    var buttonTitle: String {
        switch self {
        case .welcome:
            return "Get Started"
        case .microphone:
            return "Continue"
        case .accessibility:
            return "Continue"
        case .complete:
            return "Start Using AltType"
        }
    }
}

struct OnboardingPermissionState: Equatable, Sendable {
    let microphoneGranted: Bool
    let accessibilityGranted: Bool

    static let none = OnboardingPermissionState(microphoneGranted: false, accessibilityGranted: false)

    var allGranted: Bool {
        microphoneGranted && accessibilityGranted
    }
}

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var permissionState: OnboardingPermissionState = .none
    @Published var isProcessing = false

    private let onComplete: () -> Void
    private let permissionManager: any PermissionServiceProtocol

    init(permissionManager: any PermissionServiceProtocol, onComplete: @escaping () -> Void) {
        self.permissionManager = permissionManager
        self.onComplete = onComplete
        checkExistingPermissions()
    }

    // MARK: - Visible Steps

    /// Returns the steps that will actually be shown
    var visibleSteps: [OnboardingStep] {
        var steps: [OnboardingStep] = [.welcome, .microphone]

        if AppServices.AppConfiguration.current.features.requiresAccessibility {
            steps.append(.accessibility)
        }

        steps.append(.complete)
        return steps
    }

    /// Returns the index of the current step within visible steps
    var visibleStepIndex: Int {
        visibleSteps.firstIndex(of: currentStep) ?? 0
    }

    // Scene phase monitoring replaces notification-based lifecycle handling

    func nextStep() {
        guard !isProcessing else { return }

        switch currentStep {
        case .welcome:
            currentStep = .microphone

        case .microphone:
            if permissionState.microphoneGranted {
                advanceFromMicrophone()
            } else {
                requestMicrophonePermission()
            }

        case .accessibility:
            if permissionState.accessibilityGranted {
                advanceFromAccessibility()
            } else {
                requestAccessibilityPermission()
            }

        case .complete:
            completeOnboarding()
        }
    }

    /// Advance past the microphone step to the next applicable step
    private func advanceFromMicrophone() {
        if AppServices.AppConfiguration.current.features.requiresAccessibility {
            currentStep = .accessibility
        } else {
            currentStep = .complete
        }
    }

    /// Advance past the accessibility step to the next applicable step
    private func advanceFromAccessibility() {
        currentStep = .complete
    }

    private func checkExistingPermissions() {
        let micGranted = permissionManager.hasMicrophonePermission
        let accGranted = AppServices.AppConfiguration.current.features.requiresAccessibility ?
            permissionManager.hasAccessibilityPermission : true
        permissionState = OnboardingPermissionState(microphoneGranted: micGranted, accessibilityGranted: accGranted)

        if !permissionState.microphoneGranted {
            currentStep = .microphone
        } else if !permissionState.accessibilityGranted && AppServices.AppConfiguration.current.features.requiresAccessibility {
            currentStep = .accessibility
        } else {
            currentStep = .complete
        }
    }


    private func requestMicrophonePermission() {
        guard !isProcessing else { return }

        isProcessing = true
        Task { @MainActor in
            let granted = await permissionManager.requestMicrophone()
            self.isProcessing = false
            self.permissionState = OnboardingPermissionState(microphoneGranted: granted, accessibilityGranted: self.permissionState.accessibilityGranted)

            // Always advance — whether granted or denied
            self.advanceFromMicrophone()
        }
    }

    private func requestAccessibilityPermission() {
        guard !isProcessing else { return }

        if permissionManager.hasAccessibilityPermission {
            permissionState = OnboardingPermissionState(microphoneGranted: permissionState.microphoneGranted, accessibilityGranted: true)
            advanceFromAccessibility()
            return
        }

        isProcessing = true
        Task { @MainActor in
            let granted = await permissionManager.requestAccessibility()
            self.isProcessing = false
            self.permissionState = OnboardingPermissionState(microphoneGranted: self.permissionState.microphoneGranted, accessibilityGranted: granted)

            // Always advance — whether granted or denied
            self.advanceFromAccessibility()
        }
    }

    func handleAppBecameActive() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task { @MainActor in
                self.recheckAllPermissions()
            }
        }
    }

    private func recheckAllPermissions() {
        let previousState = permissionState
        permissionManager.refreshPermissionStates()
        let micGranted = permissionManager.hasMicrophonePermission
        let accGranted = AppServices.AppConfiguration.current.features.requiresAccessibility ?
            permissionManager.hasAccessibilityPermission : true
        permissionState = OnboardingPermissionState(microphoneGranted: micGranted, accessibilityGranted: accGranted)

        if !previousState.microphoneGranted && permissionState.microphoneGranted {
            if isProcessing && currentStep == .microphone {
                isProcessing = false
                advanceFromMicrophone()
            }
        }

        if !previousState.accessibilityGranted && permissionState.accessibilityGranted {
            if isProcessing && currentStep == .accessibility {
                isProcessing = false
                advanceFromAccessibility()
            }
        }

        if isProcessing {
            if currentStep == .microphone && permissionState.microphoneGranted {
                isProcessing = false
                advanceFromMicrophone()
            } else if currentStep == .accessibility && permissionState.accessibilityGranted {
                isProcessing = false
                advanceFromAccessibility()
            }
        }

        if currentStep == .welcome {
            if permissionState.allGranted {
                currentStep = .complete
            } else if permissionState.microphoneGranted {
                if AppServices.AppConfiguration.current.features.requiresAccessibility {
                    currentStep = .accessibility
                } else {
                    currentStep = .complete
                }
            } else {
                currentStep = .microphone
            }
        }
    }

    private func showSettingsAlert(for permission:OnboardingPermissionType) {
        let alert = NSAlert()
        alert.messageText = permission == .microphone ? "Microphone Permission" : "Accessibility Permission"
        alert.informativeText = permission == .microphone ?
            "AltType needs microphone access for speech-to-text. You can enable it in System Settings, or skip this step for now." :
            "AltType needs Accessibility access to continue. You can enable it in System Settings."
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "I'll Do It Later")

        // Make the alert dismissible by clicking outside
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    let urlString = permission == .microphone ?
                        "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone" :
                        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        } else {
            // Fallback to modal if no window is available
            if alert.runModal() == .alertFirstButtonReturn {
                let urlString = permission == .microphone ?
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone" :
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "OnboardingCompleted")

        onComplete()
    }

    func canProceed() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .microphone:
            return true // Always allow — will request permission or advance
        case .accessibility:
            return true // Always allow — will request permission or advance
        case .complete:
            return true
        }
    }
}

enum OnboardingPermissionType {
    case microphone
    case accessibility
}
