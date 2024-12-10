//
//  User.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import Combine
import Firebase

struct User: Identifiable
    {
    let uid: String
    let name: String
    let email: String
    let username: String
    let bio: String
    let profileImageUrl: String?
    
    var notifications: [Notification] = []
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
    
    init(data: [String: Any], uid: String)
        {
        self.uid             = uid //change to data["uid"]
        self.name            = data["name"] as? String ?? "Unknown"
        self.username        = data["username"] as? String ?? "No Username"
        self.bio             = data ["bio"] as? String ?? ""
        self.email           = data["email"] as? String ?? "No Email"
        self.profileImageUrl = data["profileImageUrl"] as? String // Optional
        }
    }
