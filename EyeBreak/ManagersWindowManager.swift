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
    
    private var overlayWindow: NSWindow?
    private var eventMonitor: Any?
    
    /// CRITICAL: Reuse the SAME hosting controller instead of creating new ones
    private var hostingController: NSHostingController<AnyView>?
    
    @Published private(set) var isShowing = false
    
    var onBreakCompleted: (() -> Void)?
    
    // MARK: - Deinitialization
    
    nonisolated deinit {
        print("🗑️ WindowManager deinit")
    }
    
    // MARK: - Public Methods
    
    func show(allowDismissal: Bool = false) {
        Swift.print("🪟 show() called (dismissal allowed: \(allowDismissal))")
        
        if isShowing {
            Swift.print("⚠️ Window already showing")
            return
        }
        
        guard let mainScreen = NSScreen.main else {
            Swift.print("❌ Could not get main screen")
            return
        }
        
        Swift.print("📍 Screen frame: \(mainScreen.frame)")
        
        // CRITICAL: Reuse hosting controller if it exists
        // We use .id(UUID()) to force SwiftUI to treat this as a fresh view every time.
        // This ensures @StateObject is re-initialized and onAppear fires correctly.
        let content = BreakOverlay(allowDismissal: allowDismissal) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                self.hide()
                // Small delay to ensure window is gone before next cycle logic
                try? await Task.sleep(nanoseconds: 100_000_000)
                self.onBreakCompleted?()
            }
        }
        
        let viewWithId = content.id(UUID())
        
        if hostingController == nil {
            hostingController = NSHostingController(rootView: AnyView(viewWithId))
            hostingController?.view.frame = mainScreen.frame // Force frame
            Swift.print("✅ Created hosting controller (ONCE)")
        } else {
            // Update the existing controller with new content
            hostingController?.rootView = AnyView(viewWithId)
            hostingController?.view.frame = mainScreen.frame // Force frame update
            Swift.print("✅ Reused existing hosting controller with NEW view ID")
        }
        
        // Create or reuse window
        if overlayWindow == nil {
            overlayWindow = NSWindow(
                contentRect: mainScreen.frame,  // CRITICAL: Use screen frame
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false,
                screen: mainScreen
            )
            
            overlayWindow?.isOpaque = false
            overlayWindow?.backgroundColor = .clear
            overlayWindow?.level = .screenSaver
            overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            overlayWindow?.isMovable = false
            overlayWindow?.hasShadow = false
            overlayWindow?.isReleasedWhenClosed = false  // Keep in memory
            
            Swift.print("✅ Created window (ONCE)")
        }
        
        // CRITICAL: Set the frame BEFORE setting content and ensure display is TRUE
        overlayWindow?.setFrame(mainScreen.frame, display: true, animate: false)
        
        // Set content
        overlayWindow?.contentViewController = hostingController
        
        // Setup ESC key if allowed
        if allowDismissal {
            setupKeyMonitoring()
        }
        
        // Show window
        overlayWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        
        isShowing = true
        
        Swift.print("✅ Window displayed - frame: \(overlayWindow?.frame ?? .zero)")
    }
    
    func hide() {
        Swift.print("🪟 hide() called")
        
        guard isShowing else { return }
        
        stopKeyMonitoring()
        
        // Just hide the window, don't destroy anything
        overlayWindow?.orderOut(nil)
        
        // CRITICAL: DO NOT set contentViewController to nil
        // This keeps the hosting controller alive for reuse
        
        isShowing = false
        
        Swift.print("✅ Window hidden (controller kept in memory)")
    }
    
    func cleanup() {
        Swift.print("🧹 WindowManager cleanup (app terminating)")
        
        stopKeyMonitoring()
        
        overlayWindow?.contentViewController = nil
        overlayWindow?.close()
        overlayWindow = nil
        
        hostingController = nil
        
        Swift.print("✅ WindowManager cleanup complete")
    }
    
    // MARK: - Private Methods
    
    private func setupKeyMonitoring() {
        guard eventMonitor == nil else { return }
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                Swift.print("⌨️ ESC pressed")
                Task { @MainActor in
                    self?.hide()
                    self?.onBreakCompleted?()
                }
                return nil
            }
            return event
        }
    }
    
    private func stopKeyMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
