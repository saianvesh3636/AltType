import Foundation
import Combine

// MARK: - Permission Service Protocol

/// Protocol for permission management
@MainActor
public protocol PermissionServiceProtocol: ObservableObject {
    // MARK: - Published State
    var microphoneState: PermissionState { get }
    var accessibilityState: PermissionState { get }
    var overallState: OverallPermissionState { get }

    // MARK: - State Publishers (for Combine observation)
    var overallStatePublisher: AnyPublisher<OverallPermissionState, Never> { get }

    // MARK: - Computed Properties
    var hasAllPermissions: Bool { get }
    var needsPermissions: Bool { get }
    var hasMicrophonePermission: Bool { get }
    var hasAccessibilityPermission: Bool { get }

    // MARK: - Request Methods
    func requestAllPermissions() async -> Bool
    func requestMicrophone() async -> Bool
    func requestAccessibility() async -> Bool

    // MARK: - Monitoring
    func startMonitoring()
    func stopMonitoring()
    func refreshPermissionStates()

    // MARK: - System Settings
    func openSystemSettings(for permission: PermissionType)
}
