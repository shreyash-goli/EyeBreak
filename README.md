# EyeBreak

A macOS menu bar app that implements the **20-20-20 rule** to reduce eye strain: every 20 minutes, take a 20-second break to look at something 20 feet away.

## What I Built

### 1. Timer Management with State Machine
**ObservableObject Pattern for Reactive State** ([ManagersTimerManager.swift](EyeBreak/ManagersTimerManager.swift))

- **States**: `.running` → `.onBreak` → `.paused` (3-state FSM)
- **Timer Logic**: 20-minute work intervals with 20-second mandatory breaks
- **Debug Mode**: 5-second timer for development/testing
- **1-Hour Pause**: Ability to pause all breaks for focused work sessions
- **Warning System**: 30-second notification before break starts

**Key Implementation**:
```swift
@MainActor
final class TimerManager: ObservableObject {
    @Published private(set) var state: BreakState = .running
    @Published private(set) var timeRemaining: TimeInterval = 0

    // Callbacks for cross-manager communication
    var onBreakStarted: (() -> Void)?
    var onBreakEnded: (() -> Void)?
    var onBreakWarning: (() -> Void)?
}
```

### 2. Fullscreen Break Overlay
**Immersive Break Experience** ([ViewsBreakOverlay.swift](EyeBreak/ViewsBreakOverlay.swift))

- **Fullscreen Window**: Black semi-transparent overlay covering all screens
- **Countdown Timer**: Visual 20-second countdown (updates every second)
- **Auto-dismiss**: Automatically closes after countdown completes
- **Mandatory Mode**: No ESC dismissal during actual breaks (enforced break)
- **Test Mode**: ESC dismissal allowed when triggered manually

**CountdownManager Pattern**:
- Separate `CountdownManager` class handles countdown logic
- Decoupled from main timer (break overlay can run independently)
- Completion callback triggers window cleanup

### 3. Window Management
**Level-Based Window Hierarchy** ([ManagersWindowManager.swift](EyeBreak/ManagersWindowManager.swift))

- **NSPanel with High Window Level**: `.screenSaver + 1` to appear above all apps
- **Multi-screen Support**: Spans all displays using `.fullscreen` style mask
- **Key Event Handling**: Custom responder chain for ESC key capture
- **Proper Cleanup**: Invalidates observers, removes from screen, deallocates properly

**Challenge Solved**: macOS windows don't normally capture global keys
```swift
// Custom NSPanel subclass to intercept ESC key
class FullscreenBreakPanel: NSPanel {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            NotificationCenter.default.post(
                name: .escKeyPressed,
                object: nil
            )
        }
    }
}
```

### 4. Menu Bar Integration
**NSStatusItem with Popover UI** ([EyeBreakApp.swift](EyeBreak/EyeBreakApp.swift))

- **SF Symbol Icon**: Uses `eye.fill` system icon (native macOS 11+ appearance)
- **Popover UI**: Custom SwiftUI view with timer status and controls
- **AppDelegate Pattern**: Manages menu bar lifecycle (not SwiftUI WindowGroup)

**Status Bar View Features**:
- Real-time countdown display
- Play/Pause/Reset controls
- Debug mode toggle (5-second timer)
- Test break button
- 1-hour pause button
- Keyboard shortcuts (⌘P pause, ⌘R reset, ⌘Q quit)

### 5. System Notifications
**UserNotifications Framework** ([ManagersNotificationManager.swift](ManagersNotificationManager.swift))

- **30-Second Warning**: Notification appears before break starts
- **Permission Handling**: Requests authorization on first launch
- **Silent Delivery**: No sound (visual notification only)

## How Components Interact

### Architecture Flow

```
┌──────────────────────────────────────────────────────────┐
│  AppDelegate (App Lifecycle)                             │
│  - Creates StatusBarItem with eye icon                   │
│  - Initializes all managers                              │
│  - Sets up callback chains                               │
└───────┬────────────────────────────────────────────┬─────┘
        │                                            │
        ▼                                            ▼
┌───────────────────┐                    ┌──────────────────┐
│  StatusBarView    │                    │  TimerManager    │
│  (SwiftUI)        │◄───observes────────│  (@MainActor)    │
│                   │                    │                  │
│  - Shows timer    │                    │  States:         │
│  - Control buttons│                    │  • running       │
│  - Debug toggle   │                    │  • onBreak       │
└───────────────────┘                    │  • paused        │
                                         │                  │
                                         │  Callbacks:      │
                                         │  • onBreakStarted│
                                         │  • onBreakWarning│
                                         │  • onBreakEnded  │
                                         └────┬─────┬───────┘
                                              │     │
                        ┌─────────────────────┘     └────────────┐
                        ▼                                         ▼
            ┌───────────────────────┐              ┌──────────────────────┐
            │  WindowManager        │              │  NotificationManager │
            │                       │              │                      │
            │  show(allowDismissal) │              │  sendBreakWarning()  │
            │     ↓                 │              │                      │
            │  Creates NSPanel      │              │  UserNotifications   │
            │  with BreakOverlay    │              │  framework           │
            │     ↓                 │              └──────────────────────┘
            │  Fullscreen overlay   │
            │  with countdown       │
            │     ↓                 │
            │  onBreakCompleted     │
            │     ↓                 │
            │  Calls timer.         │
            │  breakCompleted()     │
            └───────────────────────┘
```

### Callback Chain (Critical Design Pattern)

```swift
// In AppDelegate.setupTimerCallbacks():

1. TimerManager.onBreakStarted → WindowManager.show(allowDismissal: false)
   // Timer hits 0 → Show mandatory fullscreen overlay

2. TimerManager.onBreakWarning → NotificationManager.sendBreakWarning()
   // 30s before break → Show system notification

3. WindowManager.onBreakCompleted → TimerManager.breakCompleted()
   // Countdown hits 0 → Reset timer, hide window

4. TimerManager.onBreakEnded → (cleanup callback)
   // Break officially ended → Log completion
```

**Why Callbacks Instead of Combine?**
- Simpler for one-way events (no need for bidirectional binding)
- Explicit control flow (easier to debug)
- Avoids retain cycles with `[weak self]`

## What I Learned

### SwiftUI + AppKit Integration

1. **Menu Bar Apps Don't Use WindowGroup**:
   - Traditional SwiftUI apps use `WindowGroup`, but menu bar apps use `Settings { EmptyView() }`
   - All UI managed through `NSStatusItem` and `NSPopover`
   - `@NSApplicationDelegateAdaptor` bridges SwiftUI app to AppDelegate pattern

2. **@MainActor Concurrency**:
   - All UI updates must happen on main thread in Swift 6
   - `@MainActor` annotation ensures thread safety
   - `Task { @MainActor in ... }` for async main thread dispatch

3. **ObservableObject vs. @Observable**:
   - Used `ObservableObject` with `@Published` (pre-Observation framework)
   - Multiple views can observe same manager via `@ObservedObject`
   - Changes automatically trigger SwiftUI view updates

### macOS Window Management

1. **Window Levels Hierarchy**:
   ```swift
   .normalWindow            // Default app windows
   .popUpMenu               // Context menus
   .screenSaver             // Screen saver
   .screenSaver + 1         // Our break overlay (above everything)
   ```

2. **NSPanel vs NSWindow**:
   - `NSPanel`: Utility window that floats above normal windows
   - `.nonactivatingPanel`: Doesn't steal focus from other apps
   - `.fullscreen` style mask: Spans all screens without menu bar

3. **Key Event Capture**:
   - Normal windows don't receive global key events
   - Override `keyDown(with:)` in custom NSPanel subclass
   - Use `NotificationCenter` to bridge AppKit events → SwiftUI

### Timer Patterns in Swift

1. **Timer.scheduledTimer Issues**:
   - Default timer doesn't run when menu is open (runloop mode)
   - Solution: `RunLoop.current.add(timer, forMode: .common)`
   - Always invalidate old timer before creating new one (prevent duplicates)

2. **Weak Self in Closures**:
   ```swift
   timer = Timer.scheduledTimer(...) { [weak self] _ in
       Task { @MainActor [weak self] in
           self?.tick()  // Prevents retain cycle
       }
   }
   ```

3. **State Machine for Timer States**:
   - Prevents invalid transitions (can't go from `.paused` to `.onBreak`)
   - Easier to reason about than boolean flags
   - Guards in `tick()` prevent logic errors

### Memory Management

1. **Deinit Logging**:
   - Added `deinit { print("🗑️ Cleaning up") }` to all managers
   - Ensures proper cleanup when app quits
   - Catches retain cycles during development

2. **Cleanup Patterns**:
   ```swift
   func cleanup() {
       timer?.invalidate()
       timer = nil
       window?.orderOut(nil)
       window = nil
   }
   ```

3. **NotificationCenter Observers**:
   - Must remove observers in deinit/cleanup
   - Weak references prevent observer leaks
   - Used for ESC key event propagation

### User Experience Design

1. **20-20-20 Rule Implementation**:
   - Work: 20 minutes (1200 seconds)
   - Break: 20 seconds (mandatory, fullscreen)
   - Distance: Remind to look 20 feet away

2. **Progressive Disclosure**:
   - Menu bar: Minimal (just icon)
   - Popover: Compact controls (260px wide)
   - Break overlay: Fullscreen immersive

3. **Escape Hatch for Testing**:
   - Manual test break allows ESC dismissal
   - Actual timer breaks are mandatory (no escape)
   - Debug mode uses 5s timer for rapid iteration

### SwiftUI Patterns

1. **@StateObject vs @ObservedObject**:
   - `@StateObject`: View owns the object lifecycle
   - `@ObservedObject`: Object owned elsewhere, view just observes
   - Used `@ObservedObject` since AppDelegate owns managers

2. **Computed Properties for Derived State**:
   ```swift
   var timeRemainingFormatted: String {
       let minutes = Int(timeRemaining) / 60
       let seconds = Int(timeRemaining) % 60
       return String(format: "%02d:%02d", minutes, seconds)
   }
   ```

3. **Binding Wrappers**:
   ```swift
   Toggle("Debug Mode", isOn: Binding(
       get: { timerManager.debugMode },
       set: { timerManager.debugMode = $0 }
   ))
   ```

## Tech Stack

- **SwiftUI**: Declarative UI framework
- **AppKit**: Menu bar (`NSStatusItem`), window management (`NSPanel`)
- **Combine**: Reactive `@Published` properties
- **UserNotifications**: System notification framework
- **Swift Concurrency**: `@MainActor`, `Task`, `async/await`

## Features

- **20-20-20 Timer**: 20 minutes work, 20 seconds break
- **Menu Bar UI**: Always accessible, minimal footprint
- **Fullscreen Breaks**: Immersive countdown overlay
- **System Notifications**: 30-second warning before break
- **1-Hour Pause**: Temporary disable for focused sessions
- **Debug Mode**: 5-second timer for testing
- **Keyboard Shortcuts**: ⌘P (pause), ⌘R (reset), ⌘Q (quit)
- **Mandatory Breaks**: No dismissal during actual breaks (enforces health habit)
