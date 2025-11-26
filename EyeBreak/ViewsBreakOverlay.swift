//
//  BreakOverlay.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI

/// Fullscreen break overlay with glassmorphism effect
struct BreakOverlay: View {
    
    /// Whether ESC key can dismiss this overlay
    var allowDismissal: Bool = false
    
    /// Callback when user dismisses the break
    var onDismiss: () -> Void
    
    @State private var timeRemaining: TimeInterval = 20
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Frosted glass background
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                isEmphasized: true
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Content
            VStack(spacing: 40) {
                Spacer()
                
                // Eye icon with pulsing animation
                Image(systemName: "eye.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                
                // Title
                Text("Time for a break")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Subtitle
                Text("Look at something 20 feet away")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                
                // Timer countdown
                Text(timeFormatted)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.top, 20)
                
                Spacer()
                
                // Dismiss instruction (only show if dismissal is allowed)
                if allowDismissal {
                    HStack(spacing: 8) {
                        Text("Press")
                        Text("ESC")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.2))
                            .cornerRadius(8)
                        Text("to dismiss (Test Mode)")
                    }
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .padding(.bottom, 60)
                } else {
                    // Show that break is mandatory
                    VStack(spacing: 12) {
                        Text("This break is mandatory")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text("To pause breaks, use the menu bar")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .padding(.bottom, 60)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isPulsing = true
            startTimer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeFormatted: String {
        let seconds = Int(timeRemaining)
        return String(format: "%02d", seconds)
    }
    
    // MARK: - Timer Logic
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                // Auto-dismiss when timer completes
                onDismiss()
            }
        }
    }
}

#Preview {
    BreakOverlay(allowDismissal: true, onDismiss: {
        print("Break dismissed")
    })
    .frame(width: 1920, height: 1080)
}
