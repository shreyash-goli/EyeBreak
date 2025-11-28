//
//  EyeBreakApp.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI
import AppKit

@main
struct GlanceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar apps don't use WindowGroup
        Settings {
            EmptyView()
        }
    }
}

/// AppDelegate to manage the menu bar item
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var timerManager: TimerManager?
    private var windowManager: WindowManager?
    private var notificationManager: NotificationManager?
    
    // MARK: - Deinitialization
    
    deinit {
        Swift.print("🗑️ AppDelegate deinit - cleaning up all managers")
        cleanup()
    }
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Swift.print("🚀 App launching...")
        
        // Initialize managers
        timerManager = TimerManager(debugMode: false)
        windowManager = WindowManager()
        notificationManager = NotificationManager()
        Swift.print("✅ Managers initialized")
        
        // Connect timer callbacks to window manager
        setupTimerCallbacks()
        
        timerManager?.start()
        
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        Swift.print("✅ Status item created: \(statusItem != nil)")
        
        if let button = statusItem?.button {
            Swift.print("✅ Status bar button obtained")
            
            // Use SF Symbol for eye icon, with fallback to text
            if let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Glance") {
                button.image = image
                Swift.print("✅ SF Symbol image set")
            } else {
                // Fallback: use text if SF Symbol fails
                button.title = "👁️"
                Swift.print("⚠️ Using emoji fallback (SF Symbol not available)")
            }
            
            button.action = #selector(togglePopover)
            button.target = self
            Swift.print("✅ Button configured with image and action")
        } else {
            Swift.print("❌ ERROR: Could not get status bar button!")
        }
        
        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 260, height: 450)
        popover?.behavior = .transient
        Swift.print("✅ Popover created")
        
        if let timerManager = timerManager, let windowManager = windowManager {
            popover?.contentViewController = NSHostingController(
                rootView: StatusBarView(
                    timerManager: timerManager,
                    windowManager: windowManager
                )
            )
            Swift.print("✅ Popover content view configured")
        }
        
        // Start the timer
        timerManager?.start()
        
        Swift.print("🎯 Glance app launched successfully!")
        Swift.print("📍 Check your menu bar on the RIGHT side for the eye icon")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Swift.print("👋 App terminating - cleaning up")
        cleanup()
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    // MARK: - Timer Callbacks
    
    private func setupTimerCallbacks() {
        // When timer completes, show overlay (no ESC dismissal)
        timerManager?.onBreakStarted = { [weak self] in
            Task { @MainActor [weak self] in
                Swift.print("🚨 Break started - showing overlay")
                self?.windowManager?.show(allowDismissal: false)
            }
        }
        
        // When break ends, hide overlay and reset timer
        timerManager?.onBreakEnded = {
            Task { @MainActor in
                Swift.print("✅ Break ended callback (no action needed - window already hidden)")
            }
        }
        
        // Send notification 30 seconds before break
        timerManager?.onBreakWarning = { [weak self] in
            Task { @MainActor [weak self] in
                Swift.print("⚠️ Sending break warning notification")
                self?.notificationManager?.sendBreakWarning()
            }
        }
        
        // When break overlay completes (after 20 seconds), tell timer
        windowManager?.onBreakCompleted = { [weak self] in
            Task { @MainActor [weak self] in
                Swift.print("✅ Break overlay completed - resetting timer")
                self?.timerManager?.breakCompleted()
            }
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        Swift.print("🧹 AppDelegate cleanup started")
        
        timerManager?.stop()
        timerManager = nil
        
        // Call cleanup instead of hide for proper termination
        windowManager?.cleanup()
        windowManager = nil
        
        notificationManager = nil
        
        if let popover = popover {
            popover.performClose(nil)
            popover.contentViewController = nil
            self.popover = nil
        }
        
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        Swift.print("🧹 AppDelegate cleanup completed")
    }
}
