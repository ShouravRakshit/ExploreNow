//
//  ChatMessage.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

// Import necessary modules
import Foundation
import SwiftUI
import Firebase

// MARK: - FirebaseConstants Struct
// This struct holds constant keys used in Firestore documents. It helps ensure
// consistency when referring to specific fields in Firestore collections related
// to chat messages.
struct FirebaseConstants {
    static let fromId = "fromId"         // The field key for the sender's ID.
    static let toId = "toId"             // The field key for the recipient's ID.
    static let text = "text"             // The field key for the message text.
    static let timestamp = "timestamp"   // The field key for the message timestamp.
    static let profileImageUrl = "profileImageUrl" // The field key for the sender's profile image URL.
    static let email = "email"           // The field key for the sender's email.
}

// MARK: - ChatMessage Struct
// This struct represents a single chat message. It conforms to Identifiable
// to allow the message to be uniquely identified, making it easier to display
// in SwiftUI lists.

struct ChatMessage: Identifiable {
    // Computed property `id` that conforms to Identifiable. It uses `documentId`
    // as the unique identifier for the message.
    var id: String { documentId }
    
    let documentId: String         // The unique identifier for this message document in Firestore.
    let fromId: String             // The ID of the user who sent the message.
    let toId: String               // The ID of the recipient of the message.
    let text: String               // The content of the message (text).
    let timestamp: Timestamp       // The timestamp when the message was sent (in Firestore Timestamp format).
    
    // MARK: - Initializer
    // This custom initializer is used to create a `ChatMessage` instance from a Firestore document snapshot.
    // The `documentId` represents the document's unique ID in Firestore, and `data` contains the message data.
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        // Use the FirebaseConstants struct to access specific field keys
        // Ensure that if a field is missing or has an unexpected type, default values are provided.
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""      // Default to empty string if fromId is missing.
        self.toId = data[FirebaseConstants.toId] as? String ?? ""          // Default to empty string if toId is missing.
        self.text = data[FirebaseConstants.text] as? String ?? ""          // Default to empty string if text is missing.
        // Ensure that if timestamp is missing or has an invalid type, default to the current date.
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
    }
}

