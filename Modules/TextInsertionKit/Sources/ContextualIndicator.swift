@preconcurrency import SwiftUI
@preconcurrency import AppKit
@preconcurrency import ApplicationServices

// Define the accessibility attribute constants
fileprivate let kAXFrameAttribute = "AXFrame" as CFString

@MainActor
public class ContextualIndicator: NSObject {
    private var window: NSWindow?
    private var hostingView: NSHostingView<StaticIndicatorView>?
    
    // Static state indication - no animations, no timers
    private var currentState: IndicatorState = .ready
    private var isVisible: Bool = false
    
    // State representation without energy-consuming animations
    public enum IndicatorState {
        case ready      // Green indicator
        case listening  // Orange indicator
        case error      // Red indicator
    }
    
    public override init() {
        super.init()
        setupWindow()
    }
    
    deinit {
        // Simple cleanup - no timers or observers to clean up
        let windowToClose = window
        window = nil
        hostingView = nil
        
        Task { @MainActor in
            windowToClose?.close()
        }
    }
    
    private func setupWindow() {
        let indicatorView = StaticIndicatorView(state: currentState)
        hostingView = NSHostingView(rootView: indicatorView)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 20, height: 20),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window?.contentView = hostingView
        window?.level = .floating
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.ignoresMouseEvents = true
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.isReleasedWhenClosed = false
    }
    
    public func show(near element: AXUIElement) {
        guard let window = window else { return }
        
        var frameValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXFrameAttribute as CFString,
            &frameValue
        )
        
        guard result == .success,
              let frameValue = frameValue else {
            return
        }
        
        var rect = CGRect.zero
        let success = AXValueGetValue(frameValue as! AXValue, .cgRect, &rect)
        
        guard success else { return }
        
        let indicatorX = rect.maxX + 10
        let indicatorY = rect.midY - 10
        
        window.setFrameOrigin(NSPoint(x: indicatorX, y: indicatorY))
        window.orderFront(nil)
        
        isVisible = true
        updateIndicatorState(.listening) // Show orange when appearing
    }
    
    public func hide() {
        isVisible = false
        window?.orderOut(nil)
    }
    
    /// Update indicator state without animations - just color changes
    public func setState(_ newState: IndicatorState) {
        currentState = newState
        updateIndicatorState(newState)
    }
    
    /// Set to ready state (green)
    public func setReady() {
        setState(.ready)
    }
    
    /// Set to listening state (orange)  
    public func setListening() {
        setState(.listening)
    }
    
    /// Set to error state (red)
    public func setError() {
        setState(.error)
    }
    
    /// Update the indicator state immediately - no animations, no timers
    private func updateIndicatorState(_ state: IndicatorState) {
        guard let hostingView = hostingView else { return }
        
        // Simply update the view with new state - no animation, no energy consumption
        let newView = StaticIndicatorView(state: state)
        hostingView.rootView = newView
        
        currentState = state
    }
}

// MARK: - Static Indicator View (No Animations)

struct StaticIndicatorView: View {
    let state: ContextualIndicator.IndicatorState
    
    var body: some View {
        Circle()
            .fill(indicatorColor)
            .frame(width: 12, height: 12)
            // No animations, no timers, no energy consumption
            // Just static color indication as requested
    }
    
    private var indicatorColor: Color {
        switch state {
        case .ready:
            return .green       // Green when ready
        case .listening:
            return .orange      // Orange when listening
        case .error:
            return .red         // Red when error
        }
    }
}