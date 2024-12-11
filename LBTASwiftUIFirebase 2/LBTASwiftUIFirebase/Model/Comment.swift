//
//  Comment.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Firebase
import FirebaseFirestore

// MARK: - Comment Struct
// This structure represents a comment on a post. It contains properties to store
// the comment's data, such as the comment text, associated post ID, user ID,
// like counts, and timestamps.
struct Comment: Identifiable, Decodable {
    var id: String                   // Unique identifier for the comment (usually the Firestore document ID).
    let postID: String               // The ID of the post this comment is associated with.
    let userID: String               // The ID of the user who made the comment.
    let text: String                 // The text content of the comment.
    var timestamp: Date              // The timestamp of when the comment was created.
    var timestampString: String?     // A string representation of the timestamp (optional).
    var likeCount: Int               // The number of likes this comment has received.
    var likedByCurrentUser: Bool     // Indicates whether the current user has liked this comment.
}

// MARK: - Comment Extension
// Extension to provide custom initialization for the Comment struct.
// This initializer is designed to convert Firestore data (from a DocumentSnapshot) into a Comment object.
extension Comment {
    // Custom initializer to decode data from Firestore
    init?(document: DocumentSnapshot) {
        // Attempt to extract the data dictionary from the Firestore document snapshot.
        guard let data = document.data() else { return nil }
        
        // Extract the necessary fields from Firestore document data.
        guard let id = document.documentID as String?,               // Document ID as the comment ID
              let postID = data["pid"] as? String,                    // Post ID that the comment belongs to
              let userID = data["uid"] as? String,                    // User ID of the comment's author
              let text = data["comment"] as? String,                   // Text content of the comment
              let timestamp = data["timestamp"] as? Timestamp else {   // Timestamp field from Firestore
            return nil // If any of the fields are missing or incorrectly typed, initialization fails.
        }
        
        // Assign values to the Comment properties
        self.id = id
        self.postID = postID
        self.userID = userID
        self.text = text
        self.timestamp = timestamp.dateValue() // Convert Firestore Timestamp to Date object
        
        // Safely extract likeCount and likedByCurrentUser from Firestore data
        self.likeCount = data["likeCount"] as? Int ?? 0  // Default to 0 if 'likeCount' is not found.
        self.likedByCurrentUser = data["likedByCurrentUser"] as? Bool ?? false // Default to false if 'likedByCurrentUser' is not found.
    }
}
