//
//  TimerManagerTests.swift
//  EyeBreakTests
//
//  Created by Shreyash Goli on 11/26/25.
//

import XCTest
@testable import EyeBreak

@MainActor
final class TimerManagerTests: XCTestCase {
    
    var manager: TimerManager!
    
    override func setUp() async throws {
        try await super.setUp()
        manager = TimerManager(debugMode: false)
    }
    
    override func tearDown() async throws {
        manager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() async throws {
        XCTAssertEqual(manager.state, .running)
        XCTAssertEqual(manager.timeRemaining, 20 * 60) // 20 minutes
    }
    
    func testDebugModeInitialization() async throws {
        let debugManager = TimerManager(debugMode: true)
        
        XCTAssertTrue(debugManager.debugMode)
        XCTAssertEqual(debugManager.timeRemaining, 5)
    }
    
    // MARK: - Time Formatting Tests
    
    func testTimeFormattingTwentyMinutes() async throws {
        XCTAssertEqual(manager.timeRemainingFormatted, "20:00")
    }
    
    func testTimeFormattingFiveSeconds() async throws {
        let debugManager = TimerManager(debugMode: true)
        XCTAssertEqual(debugManager.timeRemainingFormatted, "00:05")
    }
    
    func testTimeFormattingVariousValues() async throws {
        let debugManager = TimerManager(debugMode: true)
        debugManager.start()
        
        // Wait 2 seconds
        try await Task.sleep(for: .seconds(2.5))
        
        let formatted = debugManager.timeRemainingFormatted
        XCTAssertTrue(formatted == "00:03" || formatted == "00:02", "Expected 00:03 or 00:02, got \(formatted)")
    }
    
    // MARK: - State Management Tests
    
    func testStartKeepsStateRunning() async throws {
        manager.start()
        XCTAssertEqual(manager.state, .running)
    }
    
    func testPauseChangesStateToPaused() async throws {
        manager.start()
        manager.pause()
        XCTAssertEqual(manager.state, .paused)
    }
    
    func testResumeFromPause() async throws {
        manager.pause()
        manager.start()
        XCTAssertEqual(manager.state, .running)
    }
    
    // MARK: - Timer Control Tests
    
    func testResetRestoresInitialTime() async throws {
        let debugManager = TimerManager(debugMode: true)
        debugManager.start()
        
        // Wait for timer to tick
        try await Task.sleep(for: .seconds(1.1))
        
        let timeBefore = debugManager.timeRemaining
        XCTAssertLessThan(timeBefore, 5)
        
        debugManager.resetTimer()
        
        XCTAssertEqual(debugManager.timeRemaining, 5)
        XCTAssertEqual(debugManager.state, .running)
    }
    
    func testStopPausesAndResetsTime() async throws {
        let debugManager = TimerManager(debugMode: true)
        debugManager.start()
        
        // Wait a bit
        try await Task.sleep(for: .seconds(1.1))
        
        debugManager.stop()
        
        XCTAssertEqual(debugManager.state, .paused)
        XCTAssertEqual(debugManager.timeRemaining, 5)
    }
    
    // MARK: - Timer Countdown Tests
    
    func testTimerCountsDown() async throws {
        let debugManager = TimerManager(debugMode: true)
        debugManager.start()
        
        let initialTime = debugManager.timeRemaining
        
        // Wait for 2 seconds
        try await Task.sleep(for: .seconds(2.5))
        
        let newTime = debugManager.timeRemaining
        
        XCTAssertLessThan(newTime, initialTime)
        XCTAssertGreaterThanOrEqual(newTime, 2) // Should have at least 2 seconds left
    }
    
    func testTimerCompletesAndEntersBreakState() async throws {
        let debugManager = TimerManager(debugMode: true)
        debugManager.start()
        
        // Wait for timer to complete (5 seconds + buffer)
        try await Task.sleep(for: .seconds(6))
        
        XCTAssertEqual(debugManager.state, .onBreak)
        XCTAssertLessThanOrEqual(debugManager.timeRemaining, 0)
    }
    
    func testPausedTimerDoesNotCountDown() async throws {
        let debugManager = TimerManager(debugMode: true)
        debugManager.start()
        debugManager.pause()
        
        let pausedTime = debugManager.timeRemaining
        
        // Wait 2 seconds
        try await Task.sleep(for: .seconds(2))
        
        XCTAssertEqual(debugManager.timeRemaining, pausedTime, "Paused timer should not count down")
    }
    
    // MARK: - Debug Mode Tests
    
    func testDebugModeToggleResetsTimer() async throws {
        XCTAssertEqual(manager.timeRemaining, 20 * 60)
        
        manager.debugMode = true
        
        XCTAssertEqual(manager.timeRemaining, 5)
        
        manager.debugMode = false
        
        XCTAssertEqual(manager.timeRemaining, 20 * 60)
    }
    
    // MARK: - Edge Case Tests
    
    func testMultipleStartCallsDoNotCreateDuplicateTimers() async throws {
        let debugManager = TimerManager(debugMode: true)
        
        debugManager.start()
        debugManager.start()
        debugManager.start()
        
        XCTAssertEqual(debugManager.state, .running)
        
        // Wait and verify countdown happens normally
        try await Task.sleep(for: .seconds(1.5))
        
        // Should be around 3-4 seconds, not weird values from multiple timers
        let remaining = debugManager.timeRemaining
        XCTAssertGreaterThanOrEqual(remaining, 3)
        XCTAssertLessThanOrEqual(remaining, 4)
    }
    
    func testStartWithZeroTimeResetsTimer() async throws {
        let debugManager = TimerManager(debugMode: true)
        debugManager.start()
        
        // Wait for completion
        try await Task.sleep(for: .seconds(6))
        
        XCTAssertEqual(debugManager.state, .onBreak)
        
        // Start again should reset time
        debugManager.start()
        
        XCTAssertEqual(debugManager.timeRemaining, 5)
        XCTAssertEqual(debugManager.state, .running)
    }
}

// MARK: - BreakState Tests

@MainActor
final class BreakStateTests: XCTestCase {
    
    func testBreakStateEquality() async throws {
        XCTAssertEqual(BreakState.running, BreakState.running)
        XCTAssertEqual(BreakState.onBreak, BreakState.onBreak)
        XCTAssertEqual(BreakState.paused, BreakState.paused)
        XCTAssertNotEqual(BreakState.running, BreakState.paused)
        XCTAssertNotEqual(BreakState.running, BreakState.onBreak)
        XCTAssertNotEqual(BreakState.paused, BreakState.onBreak)
    }
}
