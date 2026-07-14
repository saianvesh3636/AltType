import Foundation
@preconcurrency import Combine
import AppServices
import AVFoundation

#if os(macOS)
@preconcurrency import ApplicationServices
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Reactive Permission Manager

@MainActor
public final class PermissionManager: ObservableObject, PermissionServiceProtocol {
    
    // MARK: - Singleton
    public static let shared = PermissionManager()
    
    // MARK: - Published State (Single Source of Truth)
    @Published public private(set) var microphoneState: PermissionState = .unknown
    @Published public private(set) var accessibilityState: PermissionState = .unknown
    @Published public private(set) var overallState: OverallPermissionState = .checking

    // MARK: - State Publishers (for protocol conformance)
    public var overallStatePublisher: AnyPublisher<OverallPermissionState, Never> {
        $overallState.eraseToAnyPublisher()
    }

    // MARK: - Computed Properties
    public var hasAllPermissions: Bool {
        microphoneState == .granted && accessibilityState == .granted
    }

    public var needsPermissions: Bool {
        microphoneState != .granted || accessibilityState != .granted
    }

    public var hasMicrophonePermission: Bool {
        microphoneState == .granted
    }

    public var hasAccessibilityPermission: Bool {
        accessibilityState == .granted
    }

    // MARK: - Engine-Specific Permission Requirements
    
    /// Check if all permissions are granted for a specific speech engine
    public func hasPermissionsFor(engine: String) -> Bool {
        let basicPermissions = microphoneState == .granted && accessibilityState == .granted

        switch engine.lowercased() {
        case "apple", "applespeech":
            // Apple Speech on macOS only requires microphone + accessibility
            return basicPermissions
        case "whisper", "whisperkit":
            // WhisperKit only requires microphone + accessibility
            return basicPermissions
        case "auto":
            // Auto mode: both engines have same requirements
            return basicPermissions
        default:
            return basicPermissions
        }
    }

    /// Get missing permissions for a specific speech engine
    public func getMissingPermissionsFor(engine: String) -> [PermissionType] {
        var missing: [PermissionType] = []

        // Always need microphone and accessibility
        if microphoneState != .granted {
            missing.append(.microphone)
        }
        if accessibilityState != .granted {
            missing.append(.accessibility)
        }

        return missing
    }
    
    // MARK: - Internal Implementation
    private var permissionMonitor: PermissionMonitor
    private var cancellables = Set<AnyCancellable>()
    private var isRequestingMicrophone = false
    private var isRequestingAccessibility = false
    
    // MARK: - Initialization
    
    public init() {
        self.permissionMonitor = PermissionMonitor()
        setupPermissionMonitoring()
        refreshPermissionStates()
    }
    
    // MARK: - Permission Monitoring Setup
    
    private func setupPermissionMonitoring() {
        permissionMonitor.onPermissionChange = { [weak self] micState, accState in
            Task { @MainActor in
                self?.updatePermissionStates(microphone: micState, accessibility: accState)
            }
        }

        // Set up reactive overall state computation
        Publishers.CombineLatest($microphoneState, $accessibilityState)
            .map { [weak self] micState, accState in
                self?.computeOverallState(microphone: micState, accessibility: accState) ?? .checking
            }
            .removeDuplicates()
            .assign(to: \.overallState, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    public func requestAllPermissions() async -> Bool {
        let micResult = await requestMicrophone()
        let accResult = await requestAccessibility()
        return micResult && accResult
    }
    
    public func requestMicrophone() async -> Bool {
        guard !isRequestingMicrophone else { return false }
        guard await PermissionRequestStrategies.canRequestMicrophone() else { return false }
        
        isRequestingMicrophone = true
        microphoneState = .requesting
        await PermissionRequestStrategies.recordMicrophoneRequest()
        
        let result = await PermissionRequestStrategies.requestMicrophonePermission()
        
        isRequestingMicrophone = false
        
        // Refresh state after request
        refreshPermissionStates()
        
        return result
    }
    
    public func requestAccessibility() async -> Bool {
        guard !isRequestingAccessibility else { return false }
        guard await PermissionRequestStrategies.canRequestAccessibility() else { return false }

        isRequestingAccessibility = true
        accessibilityState = .requesting
        await PermissionRequestStrategies.recordAccessibilityRequest()

        // For accessibility, we can only guide user to system settings
        PermissionRequestStrategies.openSystemSettings(for: .accessibility)

        isRequestingAccessibility = false

        // Check if permission was granted after a short delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        refreshPermissionStates()

        return hasAccessibilityPermission
    }
    
    public func openSystemSettings(for permission: PermissionType) {
        PermissionRequestStrategies.openSystemSettings(for: permission)
    }
    
    public func startMonitoring() {
        permissionMonitor.startMonitoring()
    }
    
    public func stopMonitoring() {
        permissionMonitor.stopMonitoring()
    }
    
    public func refreshPermissionStates() {
        let micState = permissionMonitor.getCurrentMicrophoneState()
        let accState = permissionMonitor.getCurrentAccessibilityState()
        updatePermissionStates(microphone: micState, accessibility: accState)
    }

    // MARK: - Private State Management

    private func updatePermissionStates(microphone: PermissionState, accessibility: PermissionState) {
        // Only update if states actually changed to avoid unnecessary UI updates
        if microphoneState != microphone {
            microphoneState = microphone
        }

        if accessibilityState != accessibility {
            accessibilityState = accessibility
        }
    }

    private func computeOverallState(microphone: PermissionState, accessibility: PermissionState) -> OverallPermissionState {
        // Handle requesting states
        if microphone == .requesting || accessibility == .requesting {
            return .checking
        }

        // Check for granted permissions
        let micGranted = microphone == .granted
        let accGranted = accessibility == .granted

        if micGranted && accGranted {
            return .ready
        }

        // Determine what's needed
        if !micGranted && !accGranted {
            return .needsBoth
        } else if !micGranted {
            return .needsMicrophone
        } else if !accGranted {
            return .needsAccessibility
        }

        // This shouldn't happen, but fallback to checking
        return .checking
    }

    // MARK: - Cleanup
    
    deinit {
        // Note: Can't call stopMonitoring() from deinit due to @MainActor isolation
        // The monitoring will be cleaned up automatically when the object is deallocated
    }
}

// MARK: - Backward Compatibility (Static Methods)

extension PermissionManager {
    
    /// Legacy static method for backward compatibility during migration
    public static func checkMicrophonePermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .authorized
    }
    
    /// Legacy static method for backward compatibility during migration
    public static func checkAccessibilityPermission() -> Bool {
        #if os(macOS)
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: false]
        return AXIsProcessTrustedWithOptions(options)
        #else
        return false
        #endif
    }

    /// Legacy static method for backward compatibility during migration
    public static func requestMicrophonePermission(completion: @escaping @Sendable (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
    }

    /// Legacy static method for backward compatibility during migration
    public static func requestAccessibilityPermission() {
        #if os(macOS)
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        let url = URL(string: "App-prefs:Privacy&path=ACCESSIBILITY")!
        UIApplication.shared.open(url)
        #endif
    }
}
