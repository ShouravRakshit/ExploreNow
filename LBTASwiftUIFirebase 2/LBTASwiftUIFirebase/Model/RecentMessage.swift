//
//  RecentMessage.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

// Import necessary modules
import Foundation
import SwiftUI
import SDWebImageSwiftUI  // Used for asynchronous image loading in SwiftUI
import Firebase          // Firebase SDK for data storage and management
import FirebaseFirestore // Firestore SDK for database interaction

// MARK: - RecentMessage Struct
// This struct represents a "recent message" object. It conforms to Identifiable
// to ensure it can be used in SwiftUI views (like `List` or `ForEach`) where
// each item must have a unique ID. This struct is typically used for displaying
// a summary of recent chat messages in a list.

struct RecentMessage: Identifiable {
    // Computed property to conform to the Identifiable protocol.
    // Uses `documentId` as the unique identifier for this message.
    var id: String { documentId }

    // MARK: - Properties
    let documentId: String        // The Firestore document ID for this message (unique identifier in Firestore).
    let text: String              // The content of the message (text).
    let fromId: String            // The user ID of the sender.
    let toId: String              // The user ID of the recipient.
    let timestamp: Timestamp      // The timestamp of when the message was sent.
    let email: String             // The email of the sender.
    var profileImageUrl: String  // The URL of the sender's profile image (used to display profile image).
    var name: String?             // The name of the sender (optional, may not be available).

    // MARK: - Initializer
    // The custom initializer takes a Firestore document ID and a dictionary of data (`[String: Any]`).
    // It extracts data from the dictionary using keys defined in the `FirebaseConstants` struct.
    // Default values are provided for missing data to ensure the struct is initialized properly.

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        
        // Safely extract values from the Firestore data, with default values if not present.
        self.text = data[FirebaseConstants.text] as? String ?? ""  // Default to empty string if `text` is missing.
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""  // Default to empty string if `fromId` is missing.
        self.toId = data[FirebaseConstants.toId] as? String ?? ""  // Default to empty string if `toId` is missing.
        
        // Safely extract the timestamp from Firestore data, defaulting to the current date if not found.
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
        
        self.email = data[FirebaseConstants.email] as? String ?? ""  // Default to empty string if `email` is missing.
        self.profileImageUrl = data[FirebaseConstants.profileImageUrl] as? String ?? ""  // Default to empty string if `profileImageUrl` is missing.
        
       
    }
}
