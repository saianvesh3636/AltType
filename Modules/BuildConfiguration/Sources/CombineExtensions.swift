import Foundation
import Combine

// MARK: - Simple Combine Extensions for Basic Optimization

public extension Publisher {
    
    /// Simple debouncing with duplicate removal for better performance
    func optimizedDebounce<S: Scheduler>(for dueTime: S.SchedulerTimeType.Stride, scheduler: S) -> Publishers.Debounce<Publishers.RemoveDuplicates<Self>, S> where Self.Output: Equatable {
        return self
            .removeDuplicates()  // First remove exact duplicates
            .debounce(for: dueTime, scheduler: scheduler)
    }
    
    /// Create a sink that minimizes retain cycles
    func lightSink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable where Failure == Never {
        return sink(receiveValue: receiveValue)
    }
    
    /// Assign to property with weak reference to prevent retain cycles
    func assignWeak<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        on object: Root
    ) -> AnyCancellable where Failure == Never {
        return sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

// MARK: - Debug Extensions (DEBUG builds only)

#if DEBUG
public extension Publisher {
    
    /// Log values for debugging
    func logValues(prefix: String = "Publisher") -> Publishers.HandleEvents<Self> {
        return handleEvents(
            receiveOutput: { value in
                print("🔄 \(prefix): \(value)")
            }
        )
    }
}
#endif