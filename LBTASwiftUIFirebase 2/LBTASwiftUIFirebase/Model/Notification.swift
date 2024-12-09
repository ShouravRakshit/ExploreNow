//
//  Notification.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-12-08.
//

import SwiftUI
import Combine
import Firebase

struct Notification {
    let receiverId: String
    let senderId: String
    var message: String
    let timestamp: Timestamp
    var status: String
    var isRead: Bool
    let type: String
    let post_id: String? //Optional
    
    
    // Initializer that takes a Firestore document
    init(from document: QueryDocumentSnapshot) {
        let data = document.data()
        self.receiverId = data["receiverId"] as? String ?? ""
        self.senderId = data["senderId"] as? String ?? ""
        self.message = data["message"] as? String ?? "No message"
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date()) // Default to current time if not found
        self.isRead = data["isRead"] as? Bool ?? false // Default to unread
        self.status = data ["status"] as? String ?? ""
        self.type = data ["type"] as? String ?? ""
        self.post_id = data ["post_id"] as? String ?? ""
    }
    
    // Initializer to create a Notification from Firestore data
    init(receiverId: String, senderId: String, message: String, timestamp: Timestamp, isRead: Bool, status: String, type: String, post_id: String? = nil) {
        self.receiverId = receiverId
        self.senderId = senderId
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.status = status
        self.type   = type
        self.post_id = post_id // This can be nil if no post_id is passed
    }
    
    // You can add a computed property to display the time nicely
    var timeAgo: String {
        let date = timestamp.dateValue()
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date, to: now)

        // Handle years
        if let year = components.year, year > 0 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        }

        // Handle months
        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        }

        // Handle days
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        }

        // Handle hours
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }

        // Handle minutes
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }

        // Handle seconds
        if let second = components.second, second > 0 {
            return second == 1 ? "1 second ago" : "\(second) seconds ago"
        }

        // If no significant time difference
        return "Just now"
    }

}
