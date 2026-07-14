import SwiftUI
import AppKit
import AppServices

@MainActor
class OnboardingWindow: NSWindow {
    private var onboardingCoordinator: OnboardingCoordinator?
    private let permissionManager: any PermissionServiceProtocol

    init(permissionManager: any PermissionServiceProtocol) {
        self.permissionManager = permissionManager
        print("🪟 Creating onboarding window...")
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        print("⚙️ Setting up onboarding window...")
        setupWindow()
        print("✅ Onboarding window setup complete")
    }
    
    private func setupWindow() {
        print("🛠️ Setting window title and properties...")
        title = "Welcome to AltType"
        isReleasedWhenClosed = false
        center()
        
        print("🎯 Creating onboarding coordinator...")
        onboardingCoordinator = OnboardingCoordinator(permissionManager: permissionManager) { [weak self] in
            print("✅ Onboarding completion callback called")
            self?.close()
        }
        
        print("🎨 Creating SwiftUI hosting view...")
        let onboardingView = OnboardingView(coordinator: onboardingCoordinator!)
        print("🏗️ Creating NSHostingView...")
        contentView = NSHostingView(rootView: onboardingView)
        print("✅ NSHostingView set as content view")
    }
    
    func show() {
        print("👁️ Showing onboarding window...")
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        print("🚀 Onboarding window should now be visible")
    }
}