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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App launching...")
        
        // Initialize the timer manager
        timerManager = TimerManager(debugMode: false)
        print("✅ Timer manager initialized")
        timerManager?.start()
        
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("✅ Status item created: \(statusItem != nil)")
        
        if let button = statusItem?.button {
            print("✅ Status bar button obtained")
            
            // Use SF Symbol for eye icon, with fallback to text
            if let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Glance") {
                button.image = image
                print("✅ SF Symbol image set")
            } else {
                // Fallback: use text if SF Symbol fails
                button.title = "👁️"
                print("⚠️ Using emoji fallback (SF Symbol not available)")
            }
            
            button.action = #selector(togglePopover)
            button.target = self
            print("✅ Button configured with image and action")
        } else {
            print("❌ ERROR: Could not get status bar button!")
        }
        
        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 240, height: 300)
        popover?.behavior = .transient
        print("✅ Popover created")
        
        if let timerManager = timerManager {
            popover?.contentViewController = NSHostingController(
                rootView: StatusBarView(timerManager: timerManager)
            )
            print("✅ Popover content view configured")
        }
        
        // Start the timer
        timerManager?.start()
        
        print("🎯 Glance app launched successfully!")
        print("📍 Check your menu bar on the RIGHT side for the eye icon")
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
}
