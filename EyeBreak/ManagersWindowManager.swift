//
//  WindowManager.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI
import AppKit
import Combine

/// Manages the fullscreen break overlay window with proper memory management
@MainActor
final class WindowManager: ObservableObject {
    
    // MARK: - Properties
    
    /// The persistent window instance - created once and reused
    private var overlayWindow: NSWindow!
    
    /// Event monitor for ESC key handling
    private var eventMonitor: Any?
    
    /// Hosting controller for the SwiftUI content
    private var hostingController: NSHostingController<BreakOverlay>?
    
    /// Whether the window is currently visible
    @Published private(set) var isShowing = false
    
    /// Callback when break completes (for timer reset)
    var onBreakCompleted: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        Swift.print("🪟 WindowManager init - creating persistent window")
        setupWindow()
    }
    
    // MARK: - Deinitialization
    
    nonisolated deinit {
        // Note: Can't call cleanup() here due to @MainActor isolation
        // Cleanup should happen in hide() or applicationWillTerminate
        print("🗑️ WindowManager deinit")
    }
    
    // MARK: - Window Setup
    
    /// Creates the persistent window ONCE during initialization
    private func setupWindow() {
        guard let mainScreen = NSScreen.main else {
            Swift.print("❌ Could not get main screen during init")
            return
        }
        
        // Create the window using the FULL screen frame
        overlayWindow = NSWindow(
            contentRect: mainScreen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: mainScreen
        )
        
        // ⚠️ CRITICAL FIX: Prevent automatic deallocation when hidden/closed
        overlayWindow.isReleasedWhenClosed = false
        
        // Configure window properties for overlay behavior
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.level = .screenSaver // High level to cover everything
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        overlayWindow.isMovable = false
        overlayWindow.isMovableByWindowBackground = false
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.acceptsMouseMovedEvents = true
        overlayWindow.hasShadow = false
        
        Swift.print("✅ Persistent window created with isReleasedWhenClosed = false")
    }
    
    // MARK: - Public Methods
    
    /// Shows the break overlay window covering the main screen
    /// - Parameter allowDismissal: If true, ESC key can dismiss (for testing). If false, overlay is mandatory.
    func show(allowDismissal: Bool = false) {
        Swift.print("🪟 show() called (dismissal allowed: \(allowDismissal))")
        
        // If already showing, just update and return
        if isShowing {
            Swift.print("⚠️ Window already showing - ignoring duplicate show() call")
            return
        }
        
        // Ensure we have the main screen
        guard let mainScreen = NSScreen.main else {
            Swift.print("❌ Could not get main screen")
            return
        }
        
        // Update window frame to match current screen (handles resolution changes)
        overlayWindow.setFrame(mainScreen.frame, display: true)
        
        Swift.print("📍 Screen frame: \(mainScreen.frame)")
        
        // Create the SwiftUI content view with callback
        let contentView = BreakOverlay(allowDismissal: allowDismissal) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                Swift.print("📞 Break overlay callback - hiding window")
                
                // Hide window first
                self.hide()
                
                // Small delay to ensure window is fully hidden
                try? await Task.sleep(nanoseconds: 100_000_000)
                
                // Then notify timer that break is complete
                Swift.print("🔚 Calling onBreakCompleted")
                self.onBreakCompleted?()
            }
        }
        
        // Create or update the hosting controller
        if hostingController == nil {
            hostingController = NSHostingController(rootView: contentView)
            Swift.print("✅ Created new hosting controller")
        } else {
            hostingController?.rootView = contentView
            Swift.print("✅ Updated existing hosting controller")
        }
        
        // Set the controller as the window's content
        overlayWindow.contentViewController = hostingController
        
        // Set up key monitoring for ESC key (only if allowed)
        if allowDismissal {
            setupKeyMonitoring()
        }
        
        // Show the window (orderOut -> orderFront pattern is safe with isReleasedWhenClosed = false)
        overlayWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        isShowing = true
        
        Swift.print("✅ Break overlay window displayed")
        Swift.print("📍 Window level: \(overlayWindow.level.rawValue)")
        Swift.print("📍 Window frame: \(overlayWindow.frame)")
    }
    
    /// Hides the break overlay window (keeps it in memory for reuse)
    func hide() {
        Swift.print("🪟 hide() called")
        
        guard isShowing else {
            Swift.print("⚠️ Window not showing - ignoring hide() call")
            return
        }
        
        // Stop key monitoring
        stopKeyMonitoring()
        
        // Hide the window using orderOut (safe with isReleasedWhenClosed = false)
        overlayWindow.orderOut(nil)
        
        // Clear the content to free the SwiftUI view hierarchy
        overlayWindow.contentViewController = nil
        hostingController = nil
        
        isShowing = false
        
        Swift.print("✅ Break overlay window hidden (remains in memory)")
    }
    
    /// Complete cleanup - call this on app termination
    func cleanup() {
        Swift.print("🧹 WindowManager cleanup called")
        
        stopKeyMonitoring()
        
        if overlayWindow != nil {
            overlayWindow.contentViewController = nil
            overlayWindow.orderOut(nil)
            // Now we can safely close it since we're terminating
            overlayWindow.close()
            overlayWindow = nil
        }
        
        hostingController = nil
        isShowing = false
        
        Swift.print("✅ WindowManager cleanup complete")
    }
    
    // MARK: - Private Methods - Key Monitoring
    
    /// Sets up ESC key monitoring for manual dismissal
    private func setupKeyMonitoring() {
        // Avoid duplicate monitors
        guard eventMonitor == nil else {
            Swift.print("⚠️ Event monitor already exists")
            return
        }
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key code
                Swift.print("⌨️ ESC key pressed - dismissing overlay")
                Task { @MainActor in
                    self?.hide()
                    // Notify timer of early dismissal
                    self?.onBreakCompleted?()
                }
                return nil // Consume the event
            }
            return event
        }
        
        Swift.print("✅ ESC key monitoring enabled")
    }
    
    /// Stops ESC key monitoring
    private func stopKeyMonitoring() {
        if let monitor = eventMonitor {
            Swift.print("🧹 Removing event monitor")
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
