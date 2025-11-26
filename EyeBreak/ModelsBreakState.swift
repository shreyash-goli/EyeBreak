//
//  BreakState.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import Foundation

/// Represents the current state of the break cycle
enum BreakState: Equatable {
    case running
    case onBreak
    case paused
}
