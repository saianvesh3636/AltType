import Foundation

// MARK: - Insertion Result

/// Result of a text insertion attempt
public struct InsertionResult: Sendable {
    public let success: Bool
    public let method: String
    public let error: Error?

    public init(success: Bool, method: String, error: Error? = nil) {
        self.success = success
        self.method = method
        self.error = error
    }
}

// MARK: - Text Insertion Error

/// Text insertion errors
public enum TextInsertionError: LocalizedError, Sendable {
    case allStrategiesFailed
    case noFocusedElement
    case unsupportedApplication
    case strategyFailed(String)

    public var errorDescription: String? {
        switch self {
        case .allStrategiesFailed:
            return "All text insertion strategies failed"
        case .noFocusedElement:
            return "No focused element found"
        case .unsupportedApplication:
            return "Application does not support text insertion"
        case .strategyFailed(let name):
            return "Strategy '\(name)' failed"
        }
    }
}
