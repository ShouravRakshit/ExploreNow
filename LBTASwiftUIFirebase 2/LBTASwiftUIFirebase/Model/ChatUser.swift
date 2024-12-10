//
//  ChatUser.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation

// MARK: - ChatUser Struct
// This structure represents a user participating in a chat. It holds the user’s
// information such as UID, email, username, profile image URL, and name. The
// struct also conforms to Identifiable and Equatable protocols to help with
// identifying and comparing user instances.

struct ChatUser: Identifiable, Equatable {
    var id: String { uid } // Computed property that returns the user's unique identifier (uid).

    let uid: String                // Unique identifier for the user (typically assigned by Firebase).
    let email: String              // The user's email address.
    let username: String           // The user's chosen username.
    let profileImageUrl: String    // URL to the user's profile image.
    // let blockedUsers: [String]   // (Commented out) List of users that the current user has blocked.
    let name: String               // The user's full name.

    // MARK: - Initializer with individual parameters
    // Custom initializer to create a ChatUser instance from individual properties.
    init(uid: String, email: String, username: String, profileImageUrl: String, name: String) {
        self.uid = uid
        self.email = email
        self.username = username
        self.profileImageUrl = profileImageUrl
        self.name = name
    }

    // MARK: - Initializer with a dictionary
    // Custom initializer to create a ChatUser instance from a dictionary (e.g.,
    // data fetched from Firestore or a network request).
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""                // Default to empty string if uid is missing or invalid.
        self.email = data["email"] as? String ?? ""            // Default to empty string if email is missing or invalid.
        self.username = data["username"] as? String ?? ""      // Default to empty string if username is missing or invalid.
        self.profileImageUrl = data["profileImageUrl"] as? String ?? "" // Default to empty string if profileImageUrl is missing or invalid.
        // self.blockedUsers = data["blockedUsers"] as? [String] ?? [] // (Commented out) Default to an empty array if blockedUsers is missing or invalid.
        self.name = data["name"] as? String ?? ""              // Default to empty string if name is missing or invalid.
    }
}
