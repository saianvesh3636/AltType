import Foundation

// MARK: - App Configuration

/// Dependency injection container for app services
public final class AppConfiguration: @unchecked Sendable {
    // MARK: - Singleton

    /// Current app configuration (set at launch)
    public nonisolated(unsafe) static var current: AppConfiguration!

    // MARK: - Properties

    /// Feature set for this configuration
    public let features: FeatureSet

    /// Factory for creating hotkey service
    private let _createHotkeyService: @MainActor @Sendable () -> any HotkeyServiceProtocol

    /// Factory for creating permission service
    private let _createPermissionService: @MainActor @Sendable () -> any PermissionServiceProtocol

    /// Factory for creating text insertion service
    private let _createTextInsertionService: @MainActor @Sendable () -> any TextInsertionServiceProtocol

    // Note: Speech service is NOT included in configuration
    // SpeechService is an app-level coordinator that requires additional
    // dependencies (transcriptionStore, etc.). It is created at the app level
    // and conforms to SpeechServiceProtocol

    // MARK: - Initialization

    public init(
        features: FeatureSet,
        createHotkeyService: @escaping @MainActor @Sendable () -> any HotkeyServiceProtocol,
        createPermissionService: @escaping @MainActor @Sendable () -> any PermissionServiceProtocol,
        createTextInsertionService: @escaping @MainActor @Sendable () -> any TextInsertionServiceProtocol
    ) {
        self.features = features
        self._createHotkeyService = createHotkeyService
        self._createPermissionService = createPermissionService
        self._createTextInsertionService = createTextInsertionService
    }

    // MARK: - Factory Methods

    @MainActor
    public func createHotkeyService() -> any HotkeyServiceProtocol {
        _createHotkeyService()
    }

    @MainActor
    public func createPermissionService() -> any PermissionServiceProtocol {
        _createPermissionService()
    }

    @MainActor
    public func createTextInsertionService() -> any TextInsertionServiceProtocol {
        _createTextInsertionService()
    }
}
