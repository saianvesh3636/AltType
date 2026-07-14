import Foundation

// MARK: - Text Insertion Service Protocol

/// Protocol for text insertion service
@MainActor
public protocol TextInsertionServiceProtocol: ObservableObject {
    // MARK: - Published State
    var isInserting: Bool { get }
    var lastInsertionResult: InsertionResult? { get }

    // MARK: - Insertion
    func insertText(_ text: String, isFinal: Bool)

    // MARK: - Reactive Integration
    func signalHotkeyState(_ isPressed: Bool)
    func signalManagerState(_ managerState: HotkeyManagerState)
}
