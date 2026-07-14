# CPU Usage Analysis & Debugging Guide

## 🚨 Current CPU Usage Issue Analysis

Based on your screenshot showing 29% CPU usage with 135% high spikes, here's what's likely causing the excessive CPU consumption:

### 🎯 **Most Likely Culprit: CGEventTap Processing**

The **HotkeyKit's event processing system** is the primary suspect for CPU spikes:

1. **CGEventTap Callback**: Every keyboard event (keyDown, keyUp, flagsChanged) triggers the event callback
2. **High Event Rate**: Modern macOS generates hundreds of events per second during normal typing
3. **Complex Processing**: Each event goes through hotkey validation, state management, and Combine pipelines

### 🔍 **Debugging Methods**

#### **Method 1: Console.app Logging**
1. Open **Console.app**
2. Filter for `com.thetypealternative` or `🎹 HOTKEY`
3. Watch for excessive log entries during CPU spikes
4. Look for patterns in event processing frequency

#### **Method 2: Activity Monitor Deep Dive**
1. Open **Activity Monitor** → Select your app
2. Click **"Sample Process"** during CPU spikes
3. Look for hottest call stacks:
   - `CGEventTapCallBack` functions
   - `handleFullMode` / `handleDormantMode`
   - SwiftUI update cycles

#### **Method 3: Instruments Profiling**
```bash
# Profile CPU usage for 30 seconds
instruments -t "Time Profiler" -D trace_output.trace /path/to/AltType.app
```

#### **Method 4: Built-in Debug Menu**
The app now includes a **Performance Monitoring** section in the debug menu:
- Shows current CPU usage warnings
- Provides debugging tips and console log guidance
- Helps identify when spikes occur

### 🔧 **Quick Fixes to Try**

#### **1. Enable Dormant Mode (Most Important)**
Make sure the app enters dormant mode when idle:
- Check if `managerState` switches to `.dormant` after inactivity
- Dormant mode should reduce event processing by 85-90%

#### **2. Reduce Event Processing**
Look for these optimization opportunities:
```swift
// In HotkeyManager.swift, ensure these fast exits work:
guard !manager.requiredKeysSet.isEmpty else {
    return Unmanaged.passRetained(event) // Should exit immediately
}
```

#### **3. Check for Runaway Combine Publishers**
Look for excessive `@Published` property updates or timer-based operations.

#### **4. Verify Event Tap State**
Ensure event taps are properly disabled when not needed:
```swift
// Should disable event processing when not listening
disableEventTap() // This should stop most CPU usage
```

### 📊 **Performance Targets**

- **Idle State**: < 1% CPU usage
- **Dormant Mode**: < 3% CPU usage  
- **Active Listening**: < 10% CPU usage
- **Event Processing**: < 0.1ms per event

### ⚡ **Immediate Actions**

1. **Check Current State**: Run the app and verify it enters dormant mode
2. **Monitor Console**: Watch for excessive "🎹 HOTKEY" log entries
3. **Sample During Spikes**: Use Activity Monitor's "Sample Process" when CPU spikes
4. **Test Event Tap**: Disable hotkey registration to see if CPU drops

### 🎯 **Root Cause Investigation Steps**

1. **Confirm Event Tap Frequency**:
   ```bash
   # Check system event rate
   sudo dtrace -n 'provider:kernel { @[probename] = count(); }'
   ```

2. **Profile Specific Functions**:
   - `handleFullMode` vs `handleDormantMode` CPU time
   - SwiftUI update cycles from state changes
   - Combine pipeline overhead

3. **Compare States**:
   - CPU usage with hotkey disabled vs enabled
   - Dormant vs primed vs dictating mode differences

### 💡 **Expected Resolution**

The smart dormant system should automatically resolve most CPU issues by:
- Switching to minimal event processing during idle periods
- Reducing wake-ups from ~30/sec to ~3-5/sec
- Maintaining hotkey responsiveness with 90% less CPU usage

If CPU usage remains high after these checks, the issue may be elsewhere (SwiftUI updates, background services, or other event processing systems).