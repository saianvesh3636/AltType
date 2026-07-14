import Foundation
import AppServices
import AVFoundation
@preconcurrency import Combine

#if os(macOS)
@preconcurrency import ApplicationServices
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Reactive Permission Monitoring

@MainActor
class PermissionMonitor {
    private var cancellables = Set<AnyCancellable>()
    private var lastMicrophoneState: PermissionState = .unknown
    private var lastAccessibilityState: PermissionState = .unknown

    // Thermal state awareness for energy optimization
    private var thermalStateObserver: NSObjectProtocol?
    private var currentThermalState: ProcessInfo.ThermalState = .nominal

    var onPermissionChange: ((PermissionState, PermissionState) -> Void)?
    
    func startMonitoring() {
        setupThermalStateMonitoring()
        
        #if os(macOS)
        // Monitor app activation events to check permissions reactively with thermal-aware debouncing
        NotificationCenter.default
            .publisher(for: NSApplication.didBecomeActiveNotification)
            .debounce(for: .milliseconds(getThermalAwareDebounce(base: 500)), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkPermissionsIfAppropriate()
                }
            }
            .store(in: &cancellables)
        
        // Also monitor app un-hide events (when user returns from System Preferences) with thermal-aware debouncing
        NotificationCenter.default
            .publisher(for: NSApplication.didUnhideNotification)
            .debounce(for: .milliseconds(getThermalAwareDebounce(base: 500)), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkPermissionsIfAppropriate()
                }
            }
            .store(in: &cancellables)
        
        // Monitor workspace notifications for System Preferences changes with thermal-aware aggressive debouncing
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .debounce(for: .seconds(getThermalAwareDebounceSeconds(base: 1.0)), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    // Skip during critical thermal pressure
                    guard self.currentThermalState != .critical else { return }
                    
                    // Thermal-aware delay
                    let delay = self.getThermalAwareDelay()
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    self.checkPermissionsIfAppropriate()
                }
            }
            .store(in: &cancellables)
        
        #elseif os(iOS)
        // Monitor app activation events on iOS with thermal-aware debouncing
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .debounce(for: .milliseconds(getThermalAwareDebounce(base: 500)), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkPermissionsIfAppropriate()
                }
            }
            .store(in: &cancellables)
        #endif
        
        // Initial permission check
        checkPermissions()
    }
    
    func stopMonitoring() {
        cancellables.removeAll()
        
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
            thermalStateObserver = nil
        }
    }
    
    private func checkPermissions() {
        let micState = getCurrentMicrophoneState()
        let accState = getCurrentAccessibilityState()

        // Only trigger callback if state actually changed (avoid unnecessary UI updates)
        if micState != lastMicrophoneState || accState != lastAccessibilityState {
            lastMicrophoneState = micState
            lastAccessibilityState = accState
            onPermissionChange?(micState, accState)
        }
    }
    
    /// Check permissions with thermal state awareness
    private func checkPermissionsIfAppropriate() {
        // Skip permission checks during critical thermal pressure to conserve energy
        guard currentThermalState != .critical else { return }
        checkPermissions()
    }
    
    // MARK: - Thermal State Management
    
    private func setupThermalStateMonitoring() {
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleThermalStateChange()
            }
        }
        currentThermalState = ProcessInfo.processInfo.thermalState
    }
    
    private func handleThermalStateChange() {
        currentThermalState = ProcessInfo.processInfo.thermalState
    }
    
    private func getThermalAwareDebounce(base: Int) -> Int {
        switch currentThermalState {
        case .nominal: return base
        case .fair: return Int(Double(base) * 1.5)
        case .serious: return base * 3
        case .critical: return base * 5
        @unknown default: return base
        }
    }
    
    private func getThermalAwareDebounceSeconds(base: Double) -> Double {
        switch currentThermalState {
        case .nominal: return base
        case .fair: return base * 1.5
        case .serious: return base * 3.0
        case .critical: return base * 5.0
        @unknown default: return base
        }
    }
    
    private func getThermalAwareDelay() -> Double {
        switch currentThermalState {
        case .nominal: return 0.5
        case .fair: return 1.0
        case .serious: return 2.0
        case .critical: return 5.0
        @unknown default: return 0.5
        }
    }
    
    // MARK: - Current Permission State Checking
    
    func getCurrentMicrophoneState() -> PermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    func getCurrentAccessibilityState() -> PermissionState {
        #if os(macOS)
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: false]
        let isGranted = AXIsProcessTrustedWithOptions(options)
        return isGranted ? .granted : .denied
        #elseif os(iOS)
        return .unknown
        #else
        return .unknown
        #endif
    }

    // Note: getCurrentInputMonitoringState() removed - full app uses Accessibility permission instead
}

// MARK: - Permission Request Utilities

class PermissionRequestStrategies {
    
    // MARK: - Microphone Permission Request
    
    static func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Accessibility Permission Request
    
    static func requestAccessibilityPermission() -> Bool {
        #if os(macOS)
        // For accessibility, we can only check and guide user to system settings
        // The system doesn't provide a programmatic way to request this permission
        // Force fresh check using options with prompt: false
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: false]
        return AXIsProcessTrustedWithOptions(options)
        #elseif os(iOS)
        // iOS accessibility permissions are handled differently
        return false
        #else
        return false
        #endif
    }
    
    // MARK: - System Settings Navigation
    
    static func openSystemSettings(for permissionType: PermissionType) {
        guard let url = URL(string: permissionType.systemSettingsURL) else { return }
        
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
    
    // MARK: - Request Throttling (Modern Swift 6 Actor-Based Approach)
    
    private static let requestThrottleInterval: TimeInterval = 5.0
    
    // Use actor for thread-safe state management (modern Swift 6 approach)
    private actor RequestThrottleManager {
        static let shared = RequestThrottleManager()
        
        private var lastMicrophoneRequest: Date?
        private var lastAccessibilityRequest: Date?

        private init() {}

        func canRequestMicrophone() -> Bool {
            guard let lastRequest = lastMicrophoneRequest else { return true }
            return Date().timeIntervalSince(lastRequest) > requestThrottleInterval
        }

        func canRequestAccessibility() -> Bool {
            guard let lastRequest = lastAccessibilityRequest else { return true }
            return Date().timeIntervalSince(lastRequest) > requestThrottleInterval
        }

        func recordMicrophoneRequest() {
            lastMicrophoneRequest = Date()
        }

        func recordAccessibilityRequest() {
            lastAccessibilityRequest = Date()
        }
    }

    static func canRequestMicrophone() async -> Bool {
        await RequestThrottleManager.shared.canRequestMicrophone()
    }

    static func canRequestAccessibility() async -> Bool {
        await RequestThrottleManager.shared.canRequestAccessibility()
    }
    
    static func recordMicrophoneRequest() async {
        await RequestThrottleManager.shared.recordMicrophoneRequest()
    }

    static func recordAccessibilityRequest() async {
        await RequestThrottleManager.shared.recordAccessibilityRequest()
    }
}