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
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var pauseEndTime: Date?
    
    // MARK: - Configuration
    
    /// Enable debug mode to use 5-second timer instead of 20 minutes
    var debugMode: Bool = false {
        didSet {
            if debugMode != oldValue {
                resetTimer()
            }
        }
    }
    
    // MARK: - Callbacks
    
    /// Called when timer completes and break should start
    var onBreakStarted: (() -> Void)?
    
    /// Called when break ends and timer should reset
    var onBreakEnded: (() -> Void)?
    
    /// Called 30 seconds before break (for notification)
    var onBreakWarning: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private let workDuration: TimeInterval = 20 * 60 // 20 minutes
    private let debugDuration: TimeInterval = 5 // 5 seconds for testing
    private let breakDuration: TimeInterval = 20 // 20 seconds for break
    private let warningTime: TimeInterval = 30 // 30 seconds warning
    private var hasWarningFired = false
    
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
    
    /// Whether the app is currently paused for an hour
    var isPausedForHour: Bool {
        guard let endTime = pauseEndTime else { return false }
        return Date() < endTime
    }
    
    // MARK: - Initialization
    
    init(debugMode: Bool = false) {
        self.debugMode = debugMode
        self.timeRemaining = currentWorkDuration
    }
    
    // MARK: - Public Methods
    
    /// Starts or resumes the timer
    func start() {
        // Check if paused for an hour
        if isPausedForHour {
            Swift.print("⏸️ App is paused for 1 hour, not starting timer")
            return
        }
        
        guard state != .running else { return }
        
        state = .running
        isPaused = false
        pauseEndTime = nil
        
        // If timeRemaining is 0, reset it
        if timeRemaining <= 0 {
            timeRemaining = currentWorkDuration
        }
        
        startTimer()
    }
    
    /// Pauses the timer
    func pause() {
        state = .paused
        isPaused = true
        stopTimer()
    }
    
    /// Pauses the app for 1 hour
    func pauseForOneHour() {
        Swift.print("⏸️ Pausing app for 1 hour")
        pause()
        pauseEndTime = Date().addingTimeInterval(60 * 60) // 1 hour from now
        Swift.print("⏸️ Pause will end at: \(pauseEndTime!)")
    }
    
    /// Resumes from 1-hour pause
    func resumeFromPause() {
        Swift.print("▶️ Resuming from pause")
        pauseEndTime = nil
        isPaused = false
        start()
    }
    
    /// Resets the timer to the initial work duration
    func resetTimer() {
        stopTimer()
        state = .running
        timeRemaining = currentWorkDuration
        hasWarningFired = false
        startTimer()
    }
    
    /// Stops the timer completely
    func stop() {
        stopTimer()
        state = .paused
        timeRemaining = currentWorkDuration
        hasWarningFired = false
    }
    
    /// Called when break window is dismissed (after 20 seconds)
    func breakCompleted() {
        Swift.print("✅ Break completed, resetting timer")
        state = .running
        timeRemaining = currentWorkDuration
        hasWarningFired = false
        onBreakEnded?()
        startTimer()
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        stopTimer() // Ensure no duplicate timers
        
        // Check if paused for an hour
        if isPausedForHour {
            Swift.print("⏸️ Still paused, scheduling resume check")
            scheduleResumeCheck()
            return
        }
        
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
        
        // Check if pause period ended
        if isPausedForHour, let endTime = pauseEndTime, Date() >= endTime {
            Swift.print("⏰ 1-hour pause period ended, resuming")
            resumeFromPause()
            return
        }
        
        timeRemaining -= 1
        
        // Fire warning 30 seconds before break (only in non-debug mode)
        if !hasWarningFired && !debugMode && timeRemaining <= warningTime && timeRemaining > 0 {
            hasWarningFired = true
            Swift.print("⚠️ 30-second warning before break")
            onBreakWarning?()
        }
        
        if timeRemaining <= 0 {
            timerDidComplete()
        }
    }
    
    private func timerDidComplete() {
        state = .onBreak
        stopTimer()
        Swift.print("⏰ Timer completed! Time for a break.")
        onBreakStarted?()
    }
    
    private func scheduleResumeCheck() {
        guard let endTime = pauseEndTime else { return }
        
        let timeInterval = endTime.timeIntervalSinceNow
        if timeInterval > 0 {
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.resumeFromPause()
                }
            }
        }
    }
}
