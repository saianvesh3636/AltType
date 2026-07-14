import Foundation
@preconcurrency import AppKit
@preconcurrency import ObjectiveC
import os.lock

/// Thread-safe storage for notification observers to handle deinit properly
@preconcurrency
final class ObserverStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var observers: [NSObjectProtocol] = []
    
    func store(_ observer: NSObjectProtocol) {
        lock.withLock {
            observers.append(observer)
        }
    }
    
    func removeAll() {
        lock.withLock {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers.removeAll()
        }
    }
    
    deinit {
        removeAll()
    }
}

/// Centralized energy management system for theTypeAlternative
/// Monitors thermal state, app state, and provides energy-conscious configuration
@MainActor
public final class EnergyManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var currentThermalState: ProcessInfo.ThermalState = .nominal
    @Published public private(set) var isAppActive: Bool = true
    @Published public private(set) var shouldReduceActivity: Bool = false
    @Published public private(set) var recommendedQoS: QualityOfService = .userInitiated
    
    // MARK: - Singleton
    
    public static let shared = EnergyManager()
    
    // MARK: - Private Properties
    
    // Store observers separately to handle concurrency properly
    private var thermalStateObserver: NSObjectProtocol?
    private var appActiveObserver: NSObjectProtocol?
    private var appInactiveObserver: NSObjectProtocol?
    private var hasBeenCleaned = false
    
    // Store observer tokens for nonisolated access
    nonisolated private let observerStorage = ObserverStorage()
    
    // MARK: - Initialization
    
    private init() {
        currentThermalState = ProcessInfo.processInfo.thermalState
        setupMonitoring()
        updateEnergyState()
    }
    
    deinit {
        // Clean up observers via thread-safe storage
        observerStorage.removeAll()
    }
    
    // MARK: - Public Interface
    
    /// Check if high-frequency operations should be throttled
    public var shouldThrottleHighFrequencyOperations: Bool {
        return shouldReduceActivity || currentThermalState == .serious || currentThermalState == .critical
    }
    
    /// Check if background tasks should be postponed
    public var shouldPostponeBackgroundTasks: Bool {
        return currentThermalState == .critical || !isAppActive
    }
    
    /// Get recommended frame rate for animations based on current state
    public var recommendedAnimationFPS: Double {
        switch currentThermalState {
        case .nominal:
            return isAppActive ? 15.0 : 5.0
        case .fair:
            return isAppActive ? 10.0 : 3.0
        case .serious:
            return isAppActive ? 5.0 : 1.0
        case .critical:
            return 0.0 // Stop all animations
        @unknown default:
            return 5.0
        }
    }
    
    /// Get recommended timer tolerance for coalescing
    /// Uses higher tolerance values to significantly reduce wake frequency
    public func recommendedTimerTolerance(for interval: TimeInterval) -> TimeInterval {
        let baseToleranceRatio: Double
        
        switch currentThermalState {
        case .nominal:
            baseToleranceRatio = 0.5  // Increased from 0.1 to 0.5 (50% tolerance)
        case .fair:
            baseToleranceRatio = 0.75 // Increased from 0.25 to 0.75 (75% tolerance)
        case .serious:
            baseToleranceRatio = 0.9  // Increased from 0.5 to 0.9 (90% tolerance)
        case .critical:
            baseToleranceRatio = 1.0  // 100% tolerance (same as before)
        @unknown default:
            baseToleranceRatio = 0.5  // Increased default tolerance
        }
        
        // Apply a minimum tolerance floor to ensure timers never fire too frequently
        let minimumTolerance: TimeInterval = 0.1 // 100ms minimum tolerance
        
        // Return the larger of the calculated tolerance or minimum tolerance
        return max(interval * baseToleranceRatio, minimumTolerance)
    }
    
    // MARK: - Private Implementation
    
    private func setupMonitoring() {
        // Monitor thermal state changes
        let thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleThermalStateChange()
            }
        }
        thermalStateObserver = thermalObserver
        observerStorage.store(thermalObserver)
        
        // Monitor app activation state
        let activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAppActive = true
                self?.updateEnergyState()
                Logger.performance("App became active - energy state updated")
            }
        }
        appActiveObserver = activeObserver
        observerStorage.store(activeObserver)
        
        let inactiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAppActive = false
                self?.updateEnergyState()
                Logger.performance("App resigned active - reducing energy usage")
            }
        }
        appInactiveObserver = inactiveObserver
        observerStorage.store(inactiveObserver)
    }
    
    private func handleThermalStateChange() {
        let newState = ProcessInfo.processInfo.thermalState
        let oldState = currentThermalState
        
        currentThermalState = newState
        updateEnergyState()
        
        Logger.performance("Thermal state changed from \(oldState) to \(newState)")
        
        // Log thermal pressure events
        switch newState {
        case .serious:
            Logger.warning("Thermal pressure detected - reducing system activity")
        case .critical:
            Logger.warning("Critical thermal pressure - minimizing all activities")
        case .fair:
            Logger.performance("Moderate thermal pressure - applying light throttling")
        case .nominal:
            if oldState != .nominal {
                Logger.success("Thermal pressure relieved - resuming normal operation")
            }
        @unknown default:
            Logger.warning("Unknown thermal state: \(newState)")
        }
    }
    
    private func updateEnergyState() {
        // Determine if we should reduce activity
        let thermalPressure = currentThermalState != .nominal
        shouldReduceActivity = !isAppActive || thermalPressure
        
        // Update recommended QoS based on current state
        if currentThermalState == .critical {
            recommendedQoS = .background
        } else if currentThermalState == .serious || !isAppActive {
            recommendedQoS = .utility
        } else if currentThermalState == .fair {
            recommendedQoS = .userInitiated
        } else {
            recommendedQoS = .userInitiated
        }
    }
    
    /// Clean up resources properly on the main actor
    /// This should be called before the object is deallocated
    public func cleanupResources() {
        guard !hasBeenCleaned else { return }
        hasBeenCleaned = true
        
        // Clean up observers via thread-safe storage
        observerStorage.removeAll()
        
        // Clean up local references
        thermalStateObserver = nil
        appActiveObserver = nil
        appInactiveObserver = nil
        
        Logger.performance("EnergyManager resources cleaned up")
    }
    
    @available(*, deprecated, message: "Use cleanupResources() instead")
    private func cleanup() {
        // Legacy method - kept for compatibility but deprecated
        cleanupResources()
    }
}

// MARK: - Energy-Aware Timer Factory

public extension EnergyManager {
    
    /// Create an energy-aware timer that adjusts its behavior based on thermal state
    /// Uses a more efficient approach with manual RunLoop adding and high tolerance
    func createEnergyAwareTimer(
        interval: TimeInterval,
        repeats: Bool = true,
        block: @escaping @Sendable (Timer) -> Void
    ) -> Timer {
        // Calculate a high tolerance value to allow system to coalesce timer events
        // This significantly reduces wake counts
        let tolerance = recommendedTimerTolerance(for: interval)
        
        // Create timer without scheduling it
        let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
        
        // Set high tolerance to reduce energy impact
        timer.tolerance = tolerance
        
        // Add to RunLoop in common modes (more efficient than scheduledTimer)
        RunLoop.main.add(timer, forMode: .common)
        
        return timer
    }
    
    /// Create an energy-aware background activity scheduler
    func createBackgroundActivity(
        identifier: String,
        interval: TimeInterval,
        block: @escaping @Sendable (NSBackgroundActivityScheduler.CompletionHandler) -> Void
    ) -> NSBackgroundActivityScheduler {
        let scheduler = NSBackgroundActivityScheduler(identifier: identifier)
        scheduler.interval = interval
        scheduler.tolerance = recommendedTimerTolerance(for: interval)
        scheduler.qualityOfService = recommendedQoS
        scheduler.repeats = true
        scheduler.schedule(block)
        return scheduler
    }
}

// MARK: - Energy Monitoring Protocol

/// Protocol for objects that want to respond to energy state changes
@MainActor
public protocol EnergyAware: AnyObject {
    func energyStateDidChange(_ manager: EnergyManager)
}

// Simplified energy monitoring without complex actor system
public extension EnergyManager {
    // Remove energy-aware objects tracking for now to avoid concurrency complexity
    // This can be re-implemented later if needed with a simpler approach
}

// MARK: - Supporting Types

// Simplified implementation without energy-aware objects tracking
// This avoids complex concurrency issues while maintaining core functionality

// MARK: - Quality of Service Extensions

public extension QualityOfService {
    var description: String {
        switch self {
        case .userInteractive: return "userInteractive"
        case .userInitiated: return "userInitiated"
        case .default: return "default"
        case .utility: return "utility"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}