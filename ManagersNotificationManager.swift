//
//  NotificationManager.swift
//  EyeBreak
//
//  Created by Shreyash Goli on 11/26/25.
//

import Foundation
import UserNotifications

/// Manages local notifications for break warnings
@MainActor
final class NotificationManager {
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    init() {
        requestAuthorization()
    }
    
    // MARK: - Public Methods
    
    /// Requests notification permission from the user
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                Swift.print("✅ Notification permission granted")
            } else if let error = error {
                Swift.print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                Swift.print("⚠️ Notification permission denied")
            }
        }
    }
    
    /// Sends a notification 30 seconds before break
    func sendBreakWarning() {
        let content = UNMutableNotificationContent()
        content.title = "Break Coming Soon"
        content.body = "Your 20-second eye break starts in 30 seconds"
        content.sound = .default
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "breakWarning",
            content: content,
            trigger: nil // Fire immediately
        )
        
        // Add the notification
        notificationCenter.add(request) { error in
            if let error = error {
                Swift.print("❌ Error sending notification: \(error.localizedDescription)")
            } else {
                Swift.print("✅ Break warning notification sent")
            }
        }
    }
    
    /// Cancels all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
}
