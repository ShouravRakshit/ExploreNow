//
//  UserManager.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-21.
//

import SwiftUI
import Combine

class UserManager: ObservableObject {
    @Published public var currentUser: User?

    init() {
        fetchCurrentUser()
    }

    func fetchCurrentUser()
        {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Could not find Firebase UID")
            return
        }

        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("No data found")
                return
            }

            // Initialize the User object
            DispatchQueue.main.async
                {
                self.currentUser = User(data: data)
                if let currentUser = self.currentUser {
                       print("User Manager - Fetched User: \(currentUser.name)")
                   } else {
                       print("User Manager - Failed to initialize current user.")
                   }
                }
            }
        }
    
    
}

struct User
    {
    let uid: String
    let name: String
    let email: String
    let username: String
    let profileImageUrl: String?

    init(data: [String: Any])
        {
        self.uid = data["uid"] as? String ?? ""
        self.name = data["name"] as? String ?? "Unknown"
        self.username = data["username"] as? String ?? "No Username"
        self.email = data["email"] as? String ?? "No Email"
        self.profileImageUrl = data["profileImageUrl"] as? String // Optional
        }
    }
