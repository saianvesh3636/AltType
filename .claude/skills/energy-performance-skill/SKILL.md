---
name: energy-performance-skill
description: Energy optimization and performance monitoring. Use when working with battery impact, CPU usage optimization, memory management, or performance targets. Covers EnergyManager, performance metrics, and optimization strategies.
---

# Energy & Performance - Optimization

## Overview

Performance targets and energy optimization strategies.

**Location**: `theTypeAlternative/Sources/EnergyManager.swift`

## Performance Targets

### CPU Usage
- **Idle**: < 5%
- **Primed Mode**: 2-5%
- **Dormant Mode**: < 1%
- **Active Transcription**: < 80%

### Memory Usage
- **Idle**: < 50MB
- **Active**: < 200MB

### Battery Impact
- **Dormant Mode**: 85-90% reduction in wake-ups vs. always-on

## EnergyManager

```swift
public final class EnergyManager {
    func monitorResourceUsage() {
        // CPU usage
        let cpuUsage = getCPUUsage()
        if cpuUsage > 80 && !isTranscribing {
            Logger.warning("High CPU usage while idle: \(cpuUsage)%")
        }

        // Memory usage
        let memoryUsage = getMemoryUsage()
        if memoryUsage > 200_000_000 { // 200MB
            Logger.warning("High memory usage: \(memoryUsage / 1_000_000)MB")
        }
    }
}
```

## Optimization Strategies

### 1. Smart Dormant Mode (HotkeyKit)
- 85-90% reduction in event processing
- See hotkeykit-skill for details

### 2. Efficient Event Filtering
```swift
// Early exit for irrelevant events
guard type == .keyDown else { return Unmanaged.passRetained(event) }

// O(1) set lookup
guard requiredKeysSet.contains(keyCode) else {
    return Unmanaged.passRetained(event)
}
```

### 3. Reactive Programming Optimization
```swift
// Avoid redundant updates
usageTracker.$wordsUsedThisWeek
    .removeDuplicates()  // ✅ Only react to actual changes
    .sink { wordCount in
        updateUI(wordCount)
    }
```

### 4. Lazy Loading
```swift
// Only load WhisperKit models when needed
lazy var whisperEngine: WhisperEngine? = {
    guard tierManager.isPro else { return nil }
    return WhisperEngine(modelSize: .base)
}()
```

## Monitoring

```swift
func getCPUUsage() -> Double {
    var threads = thread_act_array_t(bitPattern: 0)
    var threadCount = mach_msg_type_number_t(0)

    let result = task_threads(mach_task_self_, &threads, &threadCount)
    guard result == KERN_SUCCESS else { return 0 }

    var totalCPU: Double = 0
    for i in 0..<Int(threadCount) {
        var info = thread_basic_info()
        var infoCount = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)

        let infoResult = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                thread_info(threads![i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
            }
        }

        if infoResult == KERN_SUCCESS {
            if info.flags & TH_FLAGS_IDLE == 0 {
                totalCPU += (Double(info.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
            }
        }
    }

    return totalCPU
}
```

## Related Skills
- **hotkeykit-skill**: Smart dormant optimization
- **development-standards-skill**: Performance best practices
