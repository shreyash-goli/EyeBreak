# EyeBreak

A macOS menu bar app that helps prevent eye strain by reminding you to take regular breaks.

## Features

- **Menu Bar Integration**: Lives in your menu bar for easy access
- **Automatic Break Reminders**: Enforces regular eye breaks using the 20-20-20 rule
- **Full-Screen Overlay**: During breaks, displays a full-screen overlay to ensure you rest your eyes
- **Break Warnings**: Sends notifications 30 seconds before a break starts
- **Timer Management**: Automatically tracks your work time and break intervals
- **Clean UI**: Simple, intuitive interface built with SwiftUI

## How It Works

1. The app runs quietly in your menu bar (look for the eye icon 👁️)
2. Click the icon to view your current timer status
3. When it's time for a break, you'll receive a notification warning
4. A full-screen overlay will appear to guide you through your break
5. After the break completes, the timer resets and you can continue working

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later (for building from source)

## Installation

### Building from Source

1. Clone this repository
2. Open `EyeBreak.xcodeproj` in Xcode
3. Build and run the project (⌘R)

## Usage

- **View Timer**: Click the eye icon in the menu bar
- **During Break**: Follow the on-screen instructions during break time
- **Quit App**: Right-click the menu bar icon and select "Quit"

## Project Structure

- `EyeBreakApp.swift` - Main app entry point and AppDelegate
- `TimerManager.swift` - Handles break timing logic
- `WindowManager.swift` - Manages the full-screen break overlay
- `NotificationManager.swift` - Handles system notifications
- `StatusBarView.swift` - UI for the menu bar popover

## Technologies

- **SwiftUI** - Modern UI framework
- **AppKit** - macOS menu bar integration
- **UserNotifications** - Break warning notifications
- **Swift Concurrency** - Async/await for smooth operation
---

**Note**: Remember to take regular breaks from your screen! Your eyes will thank you. 👁️✨
