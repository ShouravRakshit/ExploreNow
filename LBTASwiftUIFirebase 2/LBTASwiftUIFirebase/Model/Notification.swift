//
//  Notification.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import Combine
import Firebase

// Represents a notification, typically sent between users (e.g., for interactions like likes, comments, or messages)
struct Notification {
    let receiverId: String // The ID of the user receiving the notification
    let senderId: String // The ID of the user sending the notification
    var message: String  // The message content of the notification
    let timestamp: Timestamp // Timestamp when the notification was created
    var status: String // Status of the notification (e.g., "pending", "completed")
    var isRead: Bool // Indicates whether the notification has been read
    let type: String  // Type of notification (e.g., "like", "comment", "follow")
    let post_id: String? // Optional ID of the associated post, if applicable (e.g., for likes/comments on posts)
    
    
    // Initializer that takes a Firestore document
    init(from document: QueryDocumentSnapshot) {
        let data = document.data() // Retrieves the document's data as a dictionary
        
        // Maps Firestore fields to the struct's properties with fallback/default values

        self.receiverId = data["receiverId"] as? String ?? "" // Default to an empty string if missing
        self.senderId = data["senderId"] as? String ?? "" // Default to an empty string if missing
        self.message = data["message"] as? String ?? "No message" // Default message if none exists
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date()) // Default to current time if not found
        self.isRead = data["isRead"] as? Bool ?? false // Default to `false` (unread status)
        self.status = data ["status"] as? String ?? "" // Default to an empty string if no status is provided
        self.type = data ["type"] as? String ?? "" // Default to an empty string if no type is provided
        self.post_id = data ["post_id"] as? String ?? "" // Optional field; defaults to `nil` if missing
    }
    
    // Initializer to create a Notification from Firestore data
    init(receiverId: String, senderId: String, message: String, timestamp: Timestamp, isRead: Bool, status: String, type: String, post_id: String? = nil) {
        self.receiverId = receiverId // Sets the receiver's ID, a required parameter
        self.senderId = senderId // Sets the sender's ID, a required parameter
        self.message = message  // Sets the message content of the notification
        self.timestamp = timestamp   // Sets the timestamp, which is typically a Firestore
        self.isRead = isRead // Indicates whether the notification has been read
        self.status = status // Sets the status of the notification (e.g., "pending", "completed")
        self.type   = type // Sets the type of notification (e.g., "like", "comment", "follow")
        self.post_id = post_id  // Optionally sets the associated post ID, defaults to `nil` if not provided
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
