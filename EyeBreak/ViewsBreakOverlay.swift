//
//  BreakOverlay.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI
import Combine

/// Fullscreen break overlay - uses class-based countdown manager for proper memory management
struct BreakOverlay: View {
    
    var allowDismissal: Bool = false
    var onDismiss: () -> Void
    
    @StateObject private var countdownManager = CountdownManager()
    
    var body: some View {
        ZStack {
            // Simple solid background - NO gradients (gradients are GPU-intensive)
            Color.black.opacity(0.90)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Eye icon - NO animation (animations constantly allocate memory)
                Image(systemName: "eye.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white)
                
                Text("Time for a break")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Look at something 20 feet away")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                // Countdown
                Text("\(countdownManager.timeRemaining)")
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.top, 10)
                
                Spacer()
                
                if allowDismissal {
                    Text("Press ESC to dismiss (Test Mode)")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 40)
                } else {
                    Text("This break is mandatory")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            countdownManager.start { @MainActor in
                onDismiss()
            }
        }
        .onDisappear {
            countdownManager.stop()
        }
    }
}

/// Manages the countdown timer separately from the view to prevent use-after-free crashes
@MainActor
final class CountdownManager: ObservableObject {
    @Published var timeRemaining: Int = 20
    
    private var timer: Timer?
    private var onComplete: (@MainActor () -> Void)?
    
    func start(onComplete: @escaping @MainActor () -> Void) {
        // Stop any existing timer first
        stop()
        
        self.onComplete = onComplete
        timeRemaining = 20
        
        // CRITICAL: Use [weak self] to prevent retain cycle
        // Timer runs on main RunLoop, so we dispatch to MainActor
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.complete()
                }
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        onComplete = nil
    }
    
    private func complete() {
        // Store callback before stopping
        let callback = onComplete
        
        // Stop timer first to prevent any further ticks
        stop()
        
        // Call callback after cleanup
        callback?()
    }
    
    nonisolated deinit {
        // Can't call @MainActor methods from deinit
        // Timer will be invalidated when deallocated
    }
}

#Preview {
    BreakOverlay(allowDismissal: true, onDismiss: {
        print("Break dismissed")
    })
}
