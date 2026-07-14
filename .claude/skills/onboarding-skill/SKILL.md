---
name: onboarding-skill
description: First-time user experience and setup flow. Use when working with app onboarding, permission requests, feature introduction, or initial setup. Covers OnboardingCoordinator, OnboardingWindow, and permission flow integration.
---

# Onboarding - First-Time User Experience

## Overview

Guided onboarding flow for new users with permission requests and feature introduction.

**Location**: `theTypeAlternative/Sources/`

**Key Components**:
- `OnboardingCoordinator.swift` - Flow orchestration
- `OnboardingWindow.swift` - UI presentation

## Onboarding Flow

```swift
enum OnboardingStep {
    case welcome
    case microphonePermission
    case accessibilityPermission
    case hotkeySetup
    case complete
}

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    private let permissionManager = PermissionManager()

    func advance() async {
        switch currentStep {
        case .welcome:
            currentStep = .microphonePermission

        case .microphonePermission:
            let granted = await permissionManager.requestMicrophonePermission()
            if granted {
                currentStep = .accessibilityPermission
            }

        case .accessibilityPermission:
            permissionManager.requestAccessibilityPermission()
            // User must manually approve - check periodically
            startAccessibilityCheck()

        case .hotkeySetup:
            currentStep = .complete

        case .complete:
            completeOnboarding()
        }
    }
}
```

## Permission Flow Integration

```swift
struct OnboardingWindow: View {
    @StateObject private var coordinator = OnboardingCoordinator()

    var body: some View {
        VStack {
            switch coordinator.currentStep {
            case .welcome:
                WelcomeView()
            case .microphonePermission:
                MicrophonePermissionView()
            case .accessibilityPermission:
                AccessibilityPermissionView()
            case .hotkeySetup:
                HotkeySetupView()
            case .complete:
                CompletionView()
            }

            Button("Continue") {
                Task {
                    await coordinator.advance()
                }
            }
        }
        .frame(width: 600, height: 400)
    }
}
```

## Related Skills
- **permissionkit-skill**: Permission requests
- **hotkeykit-skill**: Hotkey setup
