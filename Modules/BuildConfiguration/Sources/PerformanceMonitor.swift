import Foundation
import os.log

/// Simple performance monitoring for debug builds only
@MainActor
public final class PerformanceMonitor: ObservableObject {
    
    public static let shared = PerformanceMonitor()
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentCPUUsage: Double = 0.0
    @Published public private(set) var memoryUsage: UInt64 = 0
    @Published public private(set) var isMonitoringActive: Bool = false
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.thetypealternative.performance", category: "PerformanceMonitor")
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Start simple performance monitoring (debug only)
    public func startMonitoring() {
        #if DEBUG
        guard !isMonitoringActive else { return }
        isMonitoringActive = true
        logger.debug("Performance monitoring started")
        #endif
    }

    /// Stop performance monitoring
    public func stopMonitoring() {
        #if DEBUG
        guard isMonitoringActive else { return }
        isMonitoringActive = false
        logger.debug("Performance monitoring stopped")
        #endif
    }

    /// Log a simple performance metric
    public func logEvent(_ event: String, duration: TimeInterval) {
        #if DEBUG
        if duration > 0.1 {  // Only log slow operations
            logger.debug("Performance: \(event) took \(String(format: "%.1f", duration * 1000))ms")
        }
        #endif
    }
    
    /// Get basic system info (lightweight)
    public func getBasicSystemInfo() -> String {
        let info = ProcessInfo.processInfo
        return "Memory: \(info.physicalMemory / 1024 / 1024)MB, CPU: \(info.processorCount) cores"
    }
}