//
//  WindowManager.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI
import AppKit
import Combine

/// Manages the fullscreen break overlay window
@MainActor
final class WindowManager: ObservableObject {
    
    // MARK: - Properties
    
    private var overlayWindow: NSWindow?
    @Published private(set) var isShowing = false
    
    // MARK: - Public Methods
    
    /// Shows the break overlay window covering all screens
    /// - Parameter allowDismissal: If true, ESC key can dismiss (for testing). If false, overlay is mandatory.
    func show(allowDismissal: Bool = false) {
        guard !isShowing else {
            Swift.print("⚠️ Window already showing")
            return
        }
        
        Swift.print("🪟 Showing break overlay window (dismissal allowed: \(allowDismissal))")
        
        // Get all screens
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            Swift.print("❌ Could not get screens")
            return
        }
        
        // Use the main screen (where menu bar is)
        guard let mainScreen = NSScreen.main else {
            Swift.print("❌ Could not get main screen")
            return
        }
        
        Swift.print("📍 Main screen frame: \(mainScreen.frame)")
        Swift.print("📍 Main screen visible frame: \(mainScreen.visibleFrame)")
        
        // Create the SwiftUI content view
        let contentView = BreakOverlay(allowDismissal: allowDismissal) {
            Task { @MainActor in
                self.hide()
            }
        }
        
        // Create the hosting controller
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = mainScreen.frame
        
        // Create the window using the FULL screen frame (not visibleFrame)
        let window = NSWindow(
            contentRect: mainScreen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: mainScreen
        )
        
        // Configure window properties for glassmorphism effect
        window.contentViewController = hostingController
        window.isOpaque = false // CRITICAL: Must be false for blur to work
        window.backgroundColor = .clear // CRITICAL: Must be clear for blur to work
        window.level = .screenSaver // High level to cover everything
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.hasShadow = false
        
        // Force the window to fill the entire screen
        window.setFrame(mainScreen.frame, display: true)
        
        // Set up key monitoring for ESC key (only if allowed)
        if allowDismissal {
            window.makeFirstResponder(hostingController.view)
            setupKeyMonitoring(for: window)
        }
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Store reference
        overlayWindow = window
        isShowing = true
        
        Swift.print("✅ Break overlay window displayed")
        Swift.print("📍 Window level: \(window.level.rawValue)")
        Swift.print("📍 Window frame: \(window.frame)")
        Swift.print("📍 Screen frame: \(mainScreen.frame)")
    }
    
    /// Hides the break overlay window
    func hide() {
        guard isShowing, let window = overlayWindow else {
            Swift.print("⚠️ No window to hide")
            return
        }
        
        Swift.print("🪟 Hiding break overlay window")
        
        window.orderOut(nil)
        window.close()
        
        overlayWindow = nil
        isShowing = false
        
        Swift.print("✅ Break overlay window hidden")
    }
    
    // MARK: - Private Methods
    
    private func setupKeyMonitoring(for window: NSWindow) {
        // Monitor for ESC key press
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key code
                Swift.print("⌨️ ESC key pressed - dismissing overlay")
                Task { @MainActor in
                    self?.hide()
                }
                return nil // Consume the event
            }
            return event
        }
    }
}
