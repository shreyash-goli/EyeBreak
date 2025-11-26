//
//  TimerManager.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import Foundation
import Combine

/// Manages the 20-20-20 timer logic for eye breaks
@MainActor
final class TimerManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var state: BreakState = .running
    @Published private(set) var timeRemaining: TimeInterval = 0
    
    // MARK: - Configuration
    
    /// Enable debug mode to use 5-second timer instead of 20 minutes
    var debugMode: Bool = false {
        didSet {
            if debugMode != oldValue {
                resetTimer()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private let workDuration: TimeInterval = 20 * 60 // 20 minutes
    private let debugDuration: TimeInterval = 5 // 5 seconds for testing
    
    // MARK: - Computed Properties
    
    /// Returns the appropriate duration based on debug mode
    private var currentWorkDuration: TimeInterval {
        debugMode ? debugDuration : workDuration
    }
    
    /// Formatted time string for display (mm:ss)
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    init(debugMode: Bool = false) {
        self.debugMode = debugMode
        self.timeRemaining = currentWorkDuration
    }
    
    // MARK: - Public Methods
    
    /// Starts or resumes the timer
    func start() {
        guard state != .running else { return }
        
        state = .running
        
        // If timeRemaining is 0, reset it
        if timeRemaining <= 0 {
            timeRemaining = currentWorkDuration
        }
        
        startTimer()
    }
    
    /// Pauses the timer
    func pause() {
        state = .paused
        stopTimer()
    }
    
    /// Resets the timer to the initial work duration
    func resetTimer() {
        stopTimer()
        state = .running
        timeRemaining = currentWorkDuration
        startTimer()
    }
    
    /// Stops the timer completely
    func stop() {
        stopTimer()
        state = .paused
        timeRemaining = currentWorkDuration
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        stopTimer() // Ensure no duplicate timers
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        
        // Ensure timer runs even when menu is open
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard state == .running else { return }
        
        timeRemaining -= 1
        
        if timeRemaining <= 0 {
            timerDidComplete()
        }
    }
    
    private func timerDidComplete() {
        state = .onBreak
        stopTimer()
        // In Phase 3, this will trigger the overlay window
        print("⏰ Timer completed! Time for a break.")
    }
    
    // MARK: - Deinit
    
    deinit {
        timer?.invalidate()
    }
}
