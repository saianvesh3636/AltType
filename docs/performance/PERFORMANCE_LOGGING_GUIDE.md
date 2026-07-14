# Performance Logging Guide for AltType App

## Overview
Added comprehensive performance logging to identify the root causes of copy-paste delays based on the performance issues identified in the logs.

## Logging Categories Added

### 1. Tier State Management (`TierManager.swift`)
**Logger:** `com.thetypealternative.performance.TierStateChanges`

**Key Metrics:**
- Subscription observer setup time
- Tier change processing time (breakdown by operation)
- updateTierState() execution time including:
  - updateUsageState() timing
  - featureGuard.updateTier() timing
  - speechEngineSelector.updateTier() timing
  - NotificationCenter.post timing

**Expected Issues:** Infinite loops between tier state changes, excessive observer triggering

### 2. Subscription Validation (`SubscriptionManager.swift`) 
**Logger:** `com.thetypealternative.performance.SubscriptionValidation`

**Key Metrics:**
- Transaction listener processing time
- Transaction verification timing
- Status update timing
- Transaction finishing timing
- Subscription status observer processing

**Expected Issues:** Continuous subscription validation failures, excessive transaction processing

### 3. Clipboard Operations (`UniversalTextInserter.swift`)
**Logger:** `com.thetypealternative.performance.ClipboardOperations`

**Key Metrics:**
- Total paste operation time
- Clipboard clear timing
- Clipboard set timing  
- Cmd+V simulation timing
- Clipboard restore timing (for small text)
- Breakdown by text size (small vs large)

**Expected Issues:** Slow clipboard operations, restore task delays, excessive clipboard manipulation

### 4. Speech Engine Switching (`SpeechEngineManager.swift`)
**Logger:** `com.thetypealternative.performance.SpeechEngineSwitch`

**Key Metrics:**
- Engine recreation total time
- Model preparation timing
- Engine clearing timing
- Engine creation timing
- Engine assignment timing
- Observer notification timing

**Expected Issues:** Frequent engine recreation, infinite switching between 'apple' and 'apple_speech'

### 5. AppCoordinator Cascading Updates (`AppCoordinator.swift`)
**Logger:** `com.thetypealternative.performance.AppCoordinator`

**Key Metrics:**
- Tier change observer setup
- Tier change handling breakdown:
  - Speech engine restriction updates
  - UI updates
- Total cascading update time

**Expected Issues:** Cascading updates causing event loop saturation

## How to Test and Capture Logs

### 1. Build the App
```bash
cd /Users/anvesh/Developer/Projects/TheTypeAlternative
# Build the project (assuming you have Xcode command line tools)
xcodebuild -scheme "theTypeAlternative" build
```

### 2. Run with Console Logging
```bash
# Option 1: Run from Xcode and view console
# Option 2: Use Console.app to filter by subsystem
```

### 3. Filter Logs by Performance Categories
In Console.app, filter by:
- Subsystem: `com.thetypealternative.performance`
- Categories:
  - `TierStateChanges`
  - `SubscriptionValidation` 
  - `ClipboardOperations`
  - `SpeechEngineSwitch`
  - `AppCoordinator`

### 4. Reproduce the Issue
1. Trigger copy-paste operations that were causing delays
2. Monitor the performance logs in real-time
3. Look for:
   - Operations taking >10ms
   - Repeated/infinite operations 
   - Unexpected cascading updates

## Key Log Patterns to Watch For

### 1. Infinite Tier State Loop
```
🎯 Tier objectWillChange triggered
🔄 Starting tier state change handler - tier: trial
🎤 speechEngineSelector.updateTier took: XXXms
🎯 Tier objectWillChange triggered  <- IMMEDIATE REPEAT = LOOP
```

### 2. Excessive Subscription Validation
```
💳 New transaction update received
📊 Total transaction processing: XXXms
💳 New transaction update received  <- TOO FREQUENT
```

### 3. Slow Clipboard Operations
```
📋 Starting clipboard paste for text length: XX
🧹 Small text clipboard clear: XXXms  <- HIGH TIME
📝 Small text clipboard set: XXXms     <- HIGH TIME
⌨️ Cmd+V simulation: XXXms            <- HIGH TIME
```

### 4. Speech Engine Thrashing
```
🔄 Starting engine recreation - preference: apple
🏁 Total engine recreation: XXXms
🔄 Starting engine recreation - preference: apple_speech  <- IMMEDIATE SWITCH
```

## Expected Findings

Based on the original logs, expect to find:
1. **Tier state infinite loop** - Repeated tier changes between apple/apple_speech
2. **Subscription validation storm** - Continuous "No active account" validation attempts
3. **Clipboard operation delays** - Each paste taking significantly longer than the 6-7ms baseline
4. **Cascading update chains** - Single tier change triggering multiple downstream updates

## Performance Baselines

- **Clipboard operations:** Should be <10ms total
- **Tier state changes:** Should be <5ms unless triggering major changes
- **Subscription validation:** Should not occur more than once every few seconds
- **Engine recreation:** Should only happen on user settings changes, not continuously

## Next Steps After Testing

1. **Identify the specific bottleneck** from the logs
2. **Implement targeted fixes** (debouncing, caching, loop breaking)
3. **Add circuit breakers** to prevent infinite loops
4. **Optimize the slowest operations** identified in logs