//
//  StatusBarView.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import SwiftUI

/// Menu bar dropdown content view
struct StatusBarView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "eye.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Glance")
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Timer Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                }
                
                HStack {
                    Text("Next break in:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(timerManager.timeRemainingFormatted)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            // Debug Mode Toggle
            Toggle("Debug Mode (5s)", isOn: Binding(
                get: { timerManager.debugMode },
                set: { timerManager.debugMode = $0 }
            ))
            .toggleStyle(.checkbox)
            .font(.caption)
            .help("Use 5-second timer for testing")
            
            Divider()
            
            // Control Buttons
            HStack(spacing: 8) {
                if timerManager.state == .running {
                    Button("Pause") {
                        timerManager.pause()
                    }
                    .keyboardShortcut("p", modifiers: [.command])
                } else {
                    Button("Start") {
                        timerManager.start()
                    }
                    .keyboardShortcut("s", modifiers: [.command])
                }
                
                Button("Reset") {
                    timerManager.resetTimer()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            // Quit Button
            Button("Quit Glance") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .padding()
        .frame(width: 240)
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        switch timerManager.state {
        case .running:
            return "Active"
        case .onBreak:
            return "On Break"
        case .paused:
            return "Paused"
        }
    }
    
    private var statusColor: Color {
        switch timerManager.state {
        case .running:
            return .green
        case .onBreak:
            return .orange
        case .paused:
            return .gray
        }
    }
}

#Preview {
    StatusBarView(timerManager: TimerManager(debugMode: true))
}
