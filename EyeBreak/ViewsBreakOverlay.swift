//
//  BreakOverlay.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI
import Combine

/// Manages the countdown logic
@MainActor
class CountdownManager: ObservableObject {
    @Published var timeRemaining: Int = 20
    private var timer: Timer?
    private var onComplete: (() -> Void)?
    
    func start(duration: Int = 20, onComplete: @escaping () -> Void) {
        self.timeRemaining = duration
        self.onComplete = onComplete
        
        stop() // Invalidate existing timer if any
        
        Swift.print("⏱️ CountdownManager: Starting countdown from \(duration)")
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    func stop() {
        Swift.print("🛑 CountdownManager: Stopping countdown")
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining % 5 == 0 {
                Swift.print("⏱️ CountdownManager: \(timeRemaining) seconds remaining")
            }
        } else {
            Swift.print("✅ CountdownManager: Countdown complete")
            stop()
            onComplete?()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

/// Fullscreen break overlay with countdown timer
struct BreakOverlay: View {
    
    var allowDismissal: Bool = false
    var onDismiss: () -> Void
    
    @StateObject private var countdownManager = CountdownManager()
    
    var body: some View {
        ZStack {
            // Simple solid background
            Color.black.opacity(0.90)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Eye icon
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
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills the window
        .onAppear {
            Swift.print("👀 BreakOverlay onAppear called")
            // Always restart countdown on appear
            countdownManager.start(duration: 20) {
                Swift.print("👋 BreakOverlay onDismiss closure called")
                onDismiss()
            }
        }
        .onDisappear {
            Swift.print("👋 BreakOverlay onDisappear called")
            countdownManager.stop()
        }
    }
}

#Preview {
    BreakOverlay(allowDismissal: true, onDismiss: {
        print("Break dismissed")
    })
}
