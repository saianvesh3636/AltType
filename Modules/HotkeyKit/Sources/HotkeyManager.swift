import Foundation
import AppKit
import CoreGraphics
import Carbon
@preconcurrency import ApplicationServices
import SwiftUI
@preconcurrency import Combine
import AppServices
import BuildConfiguration

// MARK: - Minimal Debug Logging
#if DEBUG
private func debugLog(_ message: String) {
    // Only log in debug builds, no timer overhead
    print("🎹 HOTKEY: \(message)")
}
#else
private func debugLog(_ message: String) {}
#endif

// MARK: - Energy-Optimized Hotkey Manager with Session Lifecycle

/// Monitors global keyboard events using CGEventTap with Accessibility permission.
/// Uses `.defaultTap` for full event access (modify and observe).
@MainActor
public final class HotkeyManager: ObservableObject, HotkeyServiceProtocol {
    
    // MARK: - Published State (Minimal for performance)
    @Published public private(set) var hotkeyState: HotkeyState = .idle
    @Published public private(set) var managerState: HotkeyManagerState = .dormant

    // MARK: - Permission-Aware Registration State
    @Published public private(set) var isRegistrationEnabled: Bool = false

    // MARK: - Publisher Access (for protocol conformance)
    public var hotkeyStatePublisher: Published<HotkeyState>.Publisher { $hotkeyState }
    public var managerStatePublisher: Published<HotkeyManagerState>.Publisher { $managerState }
    
    // MARK: - Optimized Storage
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    /// Currently registered hotkey combo (nil = no hotkey registered)
    private var registeredCombo: Set<UInt16>?
    
    /// Fast lookup set of required keys (optimized for contains() checks)
    private var requiredKeysSet: Set<UInt16> = []
    
    /// Currently pressed keys from our required set (minimal memory footprint)
    private var pressedRequiredKeys: Set<UInt16> = []
    
    /// State flag to avoid redundant state changes
    private var _isActive = false
    
    /// Track previous modifier state for proper press/release detection
    private var previousModifierState: Set<UInt16> = []
    
    // MARK: - Dependency Injection
    public weak var speechActionDelegate: SpeechActionDelegate?
    public weak var soundFeedbackDelegate: SoundFeedbackDelegate?
    
    // MARK: - Optimized Event Filtering  
    private let flagsSubject = PassthroughSubject<UInt64, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Minimal State Tracking
    private var lastFlagsValue: UInt64 = 0
    
    // MARK: - Simplified Session Management  
    private var dormancyCheckWorkItem: DispatchWorkItem?
    private var lastHotkeyTime: Date?
    private var lastUserIntentTime: Date?
    
    // MARK: - Initialization
    
    public init() {
        setupCombineEventFiltering()
        
        // Start in dormant state for maximum energy efficiency
        // Event tap will be created only when user shows intent to use the app
        managerState = .dormant
        
        // Check if we should start primed based on recent 15-minute activity
        let shouldStart = shouldStartPrimed()
        debugLog("Init: shouldStartPrimed = \(shouldStart)")
        if shouldStart {
            transitionToPrimedMode(reason: "Recent activity detected on init")
        }
        
        debugLog("HotkeyManager initialized in \(managerState) state")
    }
    
    // MARK: - Combine Event Filtering Setup
    
    private func setupCombineEventFiltering() {
        // Event processing is now handled directly in handleFlagsChanged for optimal performance
        // This eliminates the overhead of Combine publishers in the critical path
        debugLog("Event filtering optimized: direct processing without Combine overhead")
    }
    
    // MARK: - Session-Based State Management
    
    /// Transition to primed mode - creates event tap for hotkey detection
    public func transitionToPrimedMode(reason: String) {
        guard managerState == .dormant else {
            debugLog("Already in \(managerState) mode, ignoring transition request")
            return
        }
        
        debugLog("🔴 Transitioning to PRIMED mode: \(reason)")
        
        // Record user intent for 15-minute tracking
        lastUserIntentTime = Date()

        // Create event tap for hotkey monitoring (if not already created from smart dormant mode)
        // CRITICAL: Always attempt to create event tap when transitioning to primed mode
        // The setupEventTap() function will handle permission requests and trigger the dialog if needed
        debugLog("Attempting to setup event tap. isRegistrationEnabled: \(isRegistrationEnabled), eventTap exists: \(eventTap != nil)")
        if eventTap == nil {
            // Permission check and request is now inside setupEventTap
            // This will trigger the permission dialog if permission is not yet granted
            setupEventTap()
        }
        
        managerState = .primed
        debugLog("🔴 PRIMED: Full event processing active")
        
        // Schedule single dormancy check (not continuous timer)
        scheduleSingleDormancyCheck()
    }
    
    /// Transition to dormant mode - keeps event tap active but switches to minimal processing
    public func transitionToDormantMode(reason: String) {
        guard managerState != .dormant else {
            debugLog("Already in dormant mode, ignoring transition request")
            return
        }
        
        debugLog("🟡 Smart DORMANT mode: \(reason) - maintaining hotkey responsiveness")
        
        // Cancel any pending dormancy checks
        dormancyCheckWorkItem?.cancel()
        dormancyCheckWorkItem = nil
        
        // DON'T disable event tap - just change processing mode
        // The event tap will now use minimal processing via handleDormantMode()
        
        // Reset state for clean detection when reactivated
        pressedRequiredKeys.removeAll(keepingCapacity: true)
        _isActive = false
        lastFlagsValue = 0
        previousModifierState.removeAll()
        
        managerState = .dormant
        debugLog("🟡 DORMANT: Event tap active with minimal processing - hotkey still works")
    }
    
    /// Transition to dictating mode - event tap justified by active use
    public func transitionToDictatingMode() {
        // Ensure we're at least primed
        if managerState == .dormant {
            transitionToPrimedMode(reason: "Dictation session starting")
        }
        
        managerState = .dictating
        debugLog("Entered DICTATING mode")
    }
    
    /// End dictating session - return to primed mode
    public func endDictatingSession() {
        guard managerState == .dictating else { return }
        
        managerState = .primed
        debugLog("Exited DICTATING mode, returned to PRIMED")
        
        // Schedule dormancy check since we're no longer actively dictating
        scheduleSingleDormancyCheck()
    }
    
    // MARK: - Registration (Session-Aware)
    
    public func registerHotkey(_ keys: Set<UInt16>) {
        registeredCombo = keys
        requiredKeysSet = keys
        
        // Reset state when changing hotkeys
        pressedRequiredKeys.removeAll(keepingCapacity: true)
        updateHotkeyState(newState: false)

        // If we are already primed/dictating but event tap is missing, try to set it up now
        // This handles cases where permission/combo wasn't ready when we transitioned to primed mode
        if (managerState == .primed || managerState == .dictating) && eventTap == nil {
            debugLog("Registering hotkey while already in \(managerState) mode - setting up event tap now")
            setupEventTap()
        }
        
        // If we have keys registered and we're dormant, check for recent activity
        if !keys.isEmpty && managerState == .dormant && shouldStartPrimed() {
            transitionToPrimedMode(reason: "Hotkey registered with recent activity")
        }
    }
    
    public func clearHotkey() {
        registeredCombo = nil
        requiredKeysSet.removeAll(keepingCapacity: true)
        pressedRequiredKeys.removeAll(keepingCapacity: true)
        updateHotkeyState(newState: false)
        
        // No hotkey registered - safe to go dormant
        if managerState != .dormant {
            transitionToDormantMode(reason: "No hotkey registered")
        }
    }
    
    // MARK: - Session-Aware Event Handling
    
    private func setupEventTap() {
        // Check for Accessibility permission using AXIsProcessTrustedWithOptions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: false]
        let hasPermission = AXIsProcessTrustedWithOptions(options)
        debugLog("Checking Accessibility permission: \(hasPermission)")

        if !hasPermission {
            debugLog("Accessibility permission not yet granted, deferring event tap setup")
            return
        }

        // Ensure we don't set up duplicate event taps
        if eventTap != nil {
            debugLog("Event tap already exists, skipping setup")
            return
        }

        // Only create event tap if we're in a state that justifies wake-ups
        guard managerState == .primed || managerState == .dictating else {
            debugLog("Not creating event tap - in dormant state for energy savings")
            return
        }

        // Monitor keyDown, keyUp, and flagsChanged events
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.keyUp.rawValue) |
                       (1 << CGEventType.flagsChanged.rawValue)

        // Use .defaultTap for full Accessibility API access (can modify events if needed)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { 
                    return Unmanaged.passRetained(event) 
                }
                
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                
                // Ultra-fast early exit: check if we even have a hotkey registered
                guard !manager.requiredKeysSet.isEmpty else {
                    return Unmanaged.passRetained(event)
                }
                
                if manager.managerState == .dormant {
                    return manager.handleDormantMode(type: type, event: event)
                }
                
                return manager.handleFullMode(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            debugLog("Failed to create event tap - Accessibility permission required")
            return
        }
        
        self.eventTap = eventTap
        
        // Properly clean up any existing run loop source first to prevent leaks and multiple sources
        if let existingSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), existingSource, .commonModes)
            self.runLoopSource = nil
        }
        
        // Create and configure run loop source properly
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        self.runLoopSource = runLoopSource
        
        // Add to common modes in current run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Make sure the event tap is enabled
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        debugLog("Event tap created for \(managerState) state - \(managerState == .dictating ? "justified" : "time-limited") energy usage")
    }
    
    // MARK: - Optimized Key Event Processing
    
    /// Handle modifier key events (flagsChanged) - ultra-optimized path
    private func handleFlagsChanged(_ event: CGEvent) {
        let flagsValue = event.flags.rawValue
        
        // Single fast dedup check - no counters, no timing, no function calls
        guard flagsValue != lastFlagsValue else { return }
        lastFlagsValue = flagsValue
        
        // Inline critical path processing to avoid function call overhead
        let flags = CGEventFlags(rawValue: flagsValue)
        
        // Early exit optimization: if no required keys use modifiers, skip entirely
        let requiredModifierKeys = requiredKeysSet.intersection([58, 55, 56, 59, 179])
        guard !requiredModifierKeys.isEmpty else { return }
        
        // Pre-allocate set with exact capacity needed for performance
        var currentModifierState: Set<UInt16> = []
        currentModifierState.reserveCapacity(requiredModifierKeys.count)
        
        // Optimized flag checking - only check flags we actually need (branchless when possible)
        for keyCode in requiredModifierKeys {
            let shouldAdd = switch keyCode {
            case 58: flags.contains(.maskAlternate)    // Left Option
            case 55: flags.contains(.maskCommand)     // Left Command  
            case 56: flags.contains(.maskShift)       // Left Shift
            case 59: flags.contains(.maskControl)     // Left Control
            case 179: flags.contains(.maskSecondaryFn) // Function
            default: false
            }
            
            if shouldAdd {
                currentModifierState.insert(keyCode)
            }
        }
        
        // Optimization: Skip processing if state hasn't changed
        guard currentModifierState != previousModifierState else { return }
        
        // Calculate actual state changes (what changed since last time)
        let newlyPressed = currentModifierState.subtracting(previousModifierState)
        let newlyReleased = previousModifierState.subtracting(currentModifierState)
        
        // Handle state changes (optimized to avoid unnecessary calls)
        for keyCode in newlyPressed {
            handleKeyDown(keyCode)
        }
        
        for keyCode in newlyReleased {
            handleKeyUp(keyCode)
        }
        
        // Update state for next comparison
        previousModifierState = currentModifierState
    }
    
    // processFlagsChangeStateful function removed - logic inlined in handleFlagsChanged for better performance
    
    private func handleKeyDown(_ keyCode: UInt16) {
        // Early exit optimizations
        guard let requiredKeys = registeredCombo else { return }
        guard requiredKeys.contains(keyCode) else { return }
        guard !pressedRequiredKeys.contains(keyCode) else { return } // Filter key repeats
        
        // Add to pressed keys set
        pressedRequiredKeys.insert(keyCode)
        
        // Optimized check: only update state if we just completed the combo
        if !_isActive && pressedRequiredKeys.count == requiredKeys.count && pressedRequiredKeys == requiredKeys {
            debugLog("Combo completed")
            updateHotkeyState(newState: true)
        }
    }
    
    private func handleKeyUp(_ keyCode: UInt16) {
        // Early exit optimizations
        guard let requiredKeys = registeredCombo else { return }
        guard requiredKeys.contains(keyCode) else { return }
        
        // Remove from pressed keys set
        let wasPressed = pressedRequiredKeys.remove(keyCode) != nil
        
        // Optimized check: only update state if we were active and actually released a required key
        if _isActive && wasPressed {
            debugLog("Hotkey released")
            updateHotkeyState(newState: false)
        }
    }
    
    private func updateHotkeyState(newState: Bool) {
        guard _isActive != newState else { return }
        
        _isActive = newState
        
        // Record hotkey usage for session management
        if newState {
            recordHotkeyUsage()
        }
        
        // Record performance metrics (debug only)
        #if DEBUG
        if newState {
            debugLog("Hotkey pressed")
        } else {
            debugLog("Hotkey released")
        }
        #endif
        
        // Update @Published state - single allocation
        hotkeyState = HotkeyState(
            isPressed: newState,
            lastEvent: newState ? .pressed(Date()) : .released(Date())
        )
        
        // Handle session state transitions
        if newState {
            transitionToDictatingMode()
            soundFeedbackDelegate?.playStartSound()
            speechActionDelegate?.startSpeechRecording()
        } else {
            speechActionDelegate?.stopSpeechRecording()
            soundFeedbackDelegate?.playStopSound()
            endDictatingSession()
        }
    }
    
    // MARK: - Dual-Mode Event Processing
    
    /// Handle events in dormant mode - ultra-minimal processing for maximum energy savings
    private func handleDormantMode(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Ultra-fast path: Only process key down events and flagsChanged in dormant mode
        // Skip keyUp entirely to reduce wake-ups by ~30%
        switch type {
        case .keyDown:
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            
            // ULTRA-FAST FILTERING: Only care about our registered keys
            guard requiredKeysSet.contains(keyCode) else {
                return Unmanaged.passRetained(event)
            }
            
            // Potential hotkey detected - EMERGENCY ACTIVATION
            debugLog("🔴 DORMANT: Key \(keyCode) detected, emergency activation")
            emergencyActivation(detectedKey: keyCode)
            
            // Now process this event with full logic
            return handleFullMode(type: type, event: event)
            
        case .flagsChanged:
            // Check if any of our required keys are modifiers before processing
            let hasRequiredModifiers = requiredKeysSet.intersection([58, 55, 56, 59, 179]).isEmpty == false
            if hasRequiredModifiers {
                // Only process flags if we actually need them
                let flagsValue = event.flags.rawValue
                guard flagsValue != lastFlagsValue else { return Unmanaged.passRetained(event) }
                
                // Check if this could be our hotkey combination
                if flagsValue > 0 { // Some modifier is pressed
                    debugLog("🔴 DORMANT: Modifier detected, emergency activation")
                    emergencyActivation(detectedKey: 0) // 0 indicates modifier activation
                    return handleFullMode(type: type, event: event)
                }
            }
            return Unmanaged.passRetained(event)
            
        default:
            // Skip all other events in dormant mode
            return Unmanaged.passRetained(event)
        }
    }
    
    /// Handle events in full mode - optimized complete processing
    private func handleFullMode(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Optimized event type handling with switch for better performance
        switch type {
        case .flagsChanged:
            // Handle modifier key events (Option, Command, Shift, Control, Fn)
            handleFlagsChanged(event)
            
        case .keyDown, .keyUp:
            // Handle regular key events - combined path for efficiency
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            
            // Ultra-fast path: skip events for keys we don't care about
            guard requiredKeysSet.contains(keyCode) else {
                return Unmanaged.passRetained(event)
            }
            
            // Branchless processing - use switch for better performance
            switch type {
            case .keyDown:
                handleKeyDown(keyCode)
            case .keyUp:
                handleKeyUp(keyCode)
            default:
                break
            }
            
        default:
            // All other events pass through unprocessed
            break
        }
        
        // Let the event pass through to the system (don't consume)
        return Unmanaged.passRetained(event)
    }
    
    /// Emergency activation when hotkey detected in dormant mode - optimized for speed
    private func emergencyActivation(detectedKey: UInt16) {
        // Ultra-fast state transition - no allocations
        managerState = .primed
        
        // Reset hotkey state for clean detection - optimized for speed
        pressedRequiredKeys.removeAll(keepingCapacity: true)
        _isActive = false
        lastFlagsValue = 0
        previousModifierState.removeAll(keepingCapacity: true)
        
        debugLog("🔴 EMERGENCY: Activated full processing for key \(detectedKey == 0 ? "modifier" : String(detectedKey))")
        
        // Record usage for intelligent dormancy
        recordHotkeyUsage()
        
        // Stay primed longer since user is actively using
        scheduleSingleDormancyCheck()
    }
    
    // MARK: - Permission Integration Methods
    
    /// Enable automatic hotkey registration/unregistration based on external permission state
    public func setPermissionState(hasPermissions: Bool) {
        isRegistrationEnabled = hasPermissions

        if hasPermissions {
            // Auto-register if we have stored combo
            if let combo = registeredCombo {
                debugLog("Auto-registering hotkey due to permission grant")

                // Create event tap if we're in primed or dictating state
                // Permission is now verified, so this should succeed
                if (managerState == .primed || managerState == .dictating) && eventTap == nil {
                    debugLog("Creating event tap for \(managerState) state")
                    setupEventTap()
                }

                registerHotkey(combo)
                debugLog("Successfully registered hotkey with keys: \(combo)")
            }
        } else {
            // Permission check indicates we don't have permission yet
            // Try to create event tap anyway - this will trigger the permission dialog
            debugLog("Permission not yet granted - will attempt to trigger permission dialog on next primed transition")

            // Don't go dormant - let the normal flow request permission
            if let combo = registeredCombo {
                registerHotkey(combo)
            }
        }
    }
    
    // MARK: - Enhanced Registration Methods
    
    public func registerHotkeyIfEnabled(_ keys: Set<UInt16>) {
        registeredCombo = keys
        requiredKeysSet = keys

        // Only actually register if we have permissions
        if isRegistrationEnabled && checkAccessibilityPermission() {
            // Existing registration logic...
            pressedRequiredKeys.removeAll(keepingCapacity: true)
            updateHotkeyState(newState: false)
        } else {
            debugLog("Hotkey registration deferred - waiting for permissions")
        }
    }
    
    public func unregisterHotkey() {
        registeredCombo = nil
        requiredKeysSet.removeAll(keepingCapacity: true)
        pressedRequiredKeys.removeAll(keepingCapacity: true)
        updateHotkeyState(newState: false)
        disableEventTap()
    }
    
    // MARK: - Utility Methods

    /// Check Accessibility permission status
    public func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    public func disableEventTap() {
        // First disable the tap to stop processing events
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            debugLog("Event tap disabled - eliminating all wake-ups")
        }
        
        // Properly remove run loop source and clean up resources
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            debugLog("Run loop source removed")
        }
        
        // Clear references
        eventTap = nil
        runLoopSource = nil
        
        // Note: Don't clear hotkey registration or Combine subscriptions
        // We want to preserve hotkey config for when we go primed again
        
        debugLog("Event tap resources cleaned up - zero energy wake-ups achieved")
    }
    
    // MARK: - Intelligent Session Management (Timer-Free)
    
    /// Record hotkey usage for 15-minute session tracking
    private func recordHotkeyUsage() {
        lastHotkeyTime = Date()
        debugLog("Hotkey used - session will stay primed for 15 minutes")
    }
    
    /// Check if we should start in primed mode based on recent 15-minute activity
    private func shouldStartPrimed() -> Bool {
        // Check if hotkey was used in last 15 minutes
        if let lastHotkey = lastHotkeyTime {
            let fifteenMinutesAgo = Date().addingTimeInterval(-15 * 60)
            if lastHotkey > fifteenMinutesAgo {
                debugLog("Recent hotkey usage (15 min) - should start primed")
                return true
            }
        }
        
        // Check if user showed intent in last 15 minutes
        if let lastIntent = lastUserIntentTime {
            let fifteenMinutesAgo = Date().addingTimeInterval(-15 * 60)
            if lastIntent > fifteenMinutesAgo {
                debugLog("Recent user intent (15 min) - should start primed")
                return true
            }
        }
        
        debugLog("No recent activity (15 min) - starting dormant")
        return false
    }
    
    /// Check if we should remain primed based on 15-minute activity window
    private func shouldRemainPrimed() -> Bool {
        // Always remain primed during active dictation
        if managerState == .dictating {
            return true
        }
        
        // Check if hotkey was used in last 15 minutes
        if let lastHotkey = lastHotkeyTime {
            let fifteenMinutesAgo = Date().addingTimeInterval(-15 * 60)
            if lastHotkey > fifteenMinutesAgo {
                debugLog("Recent hotkey usage (15 min) - remaining primed")
                return true
            }
        }
        
        // Check if user showed intent in last 15 minutes  
        if let lastIntent = lastUserIntentTime {
            let fifteenMinutesAgo = Date().addingTimeInterval(-15 * 60)
            if lastIntent > fifteenMinutesAgo {
                debugLog("Recent user intent (15 min) - remaining primed")
                return true
            }
        }
        
        debugLog("No activity in last 15 minutes - transitioning to dormant")
        return false
    }
    
    /// Schedule a single dormancy check (not continuous timer)
    private func scheduleSingleDormancyCheck() {
        // Cancel any existing check
        dormancyCheckWorkItem?.cancel()
        
        // Create new work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                if !self.shouldRemainPrimed() {
                    self.transitionToDormantMode(reason: "Inactivity detected")
                } else {
                    // Schedule next check if still active
                    self.scheduleSingleDormancyCheck()
                }
            }
        }
        
        dormancyCheckWorkItem = workItem
        
        // Schedule check for 15 minutes from now (not continuous)
        DispatchQueue.main.asyncAfter(deadline: .now() + 900, execute: workItem)
        debugLog("Scheduled single dormancy check for 15 minutes")
    }
    
    // MARK: - Public Intent Signals (No Timer Needed)
    
    /// Call this when user shows intent to use the app (menu bar click, etc.)
    public func signalUserIntent(source: String) {
        lastUserIntentTime = Date()
        
        if managerState == .dormant {
            transitionToPrimedMode(reason: "User intent: \(source)")
        } else {
            debugLog("User intent signal from \(source) - already in \(managerState) state")
        }
    }
    
    /// Call this when system wakes from sleep
    public func handleSystemWake() {
        // System wake might indicate user is about to use the computer
        if shouldStartPrimed() {
            signalUserIntent(source: "System wake")
        }
    }
    
    /// Get current usage statistics for debugging
    public func getUsageStats() -> HotkeyManagerState {
        return managerState
    }
}