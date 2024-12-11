//
//  User.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import Combine
import Firebase

// Represents a user entity, conforming to `Identifiable` and `Equatable`
struct User: Identifiable
    {
    let uid: String  // Unique identifier for the user
    let name: String // User's full name
    let email: String // User's email address
    let username: String // User's unique username
    let bio: String // User's biography or personal description
    let profileImageUrl: String?  // Optional profile image URL
    
    var notifications: [Notification] = [] //user-related notifications
    // Conformance to Identifiable (use uid as the unique identifier)
    var id: String { uid }

    // Conformance to Equatable
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.username == rhs.username &&
               lhs.bio == rhs.bio &&
               lhs.profileImageUrl == rhs.profileImageUrl
    }
    
    // Initializer to map data from a dictionary and a UID
    init(data: [String: Any], uid: String)
        {
        self.uid             = uid // `uid` is passed separately; this could be included in `data`
        self.name            = data["name"] as? String ?? "Unknown" // Provides a default value if `name` is missing
        self.username        = data["username"] as? String ?? "No Username"  // Default for missing `username`
        self.bio             = data ["bio"] as? String ?? "" // Default for missing `bio`
        self.email           = data["email"] as? String ?? "No Email" // Default for missing `email`
        self.profileImageUrl = data["profileImageUrl"] as? String // `profileImageUrl` is optional
        }
    }
