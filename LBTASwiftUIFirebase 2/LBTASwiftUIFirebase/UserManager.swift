//
//  UserManager.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-21.
//

import SwiftUI
import Combine
import Firebase

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
                self.currentUser = User(data: data, uid: uid)
                if let currentUser = self.currentUser {
                       print("User Manager - Fetched User: \(currentUser.name)")
                   } else {
                       print("User Manager - Failed to initialize current user.")
                   }
                }
            }
        }
    
    private func updateUserInFirestore(_ user: User) {
        print ("in updateUserInFirestore")
        let userData: [String: Any] = [
            "uid": user.uid,
            "name": user.name,
            "username": user.username,
            "email": user.email,
            "bio": user.bio,
            "profileImageUrl": user.profileImageUrl ?? ""
        ]
        print ("UID: \(user.uid)")
        FirebaseManager.shared.firestore.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("Failed to update user in Firestore: \(error.localizedDescription)")
            } else {
                print("User successfully updated in Firestore.")
            }
        }
    }
    
    func setCurrentUser_name(newName: String) {
        print ("in setCurrentUser_name")
        if let username = currentUser?.username
            {
            if let bio = currentUser?.bio {
                updateCurrentUserFields (newName: newName, newUsername: username, newBio: bio)
            }
            }
        
        else {}
    }
    
    func setCurrentUser_username(newUsername: String) {
        if let name = currentUser?.name
            {
            if let bio = currentUser?.bio {
                updateCurrentUserFields (newName: name, newUsername: newUsername, newBio: bio)
            }
            }
        
        else {}
    }
    
    func setCurrentUser_bio (newBio: String) {
        if let name = currentUser?.name
            {
            if let username = currentUser?.username{
                updateCurrentUserFields (newName: name, newUsername: username, newBio: newBio)
            }
            }
        
        else {}
    }
    
    func updateCurrentUserFields (newName: String, newUsername: String, newBio: String)
    {
        print ("in updateCurrentUserFields: newName: \(newName)")
        // Check if currentUser is not nil
        guard var user = currentUser else {
            print("Current user is not set.")
            return
        }
        
        if let uid = currentUser?.uid{
            // Update the user's name
            user = User(data: [
                "name": newName,
                "username": newUsername,
                "email": user.email,
                "bio": newBio,
                "profileImageUrl": user.profileImageUrl ?? ""
            ], uid: uid)
        }
        // Assign the updated user back to currentUser
        self.currentUser = user
        
        // Optionally, you might want to update the user in Firestore as well
        updateUserInFirestore(user)
    }
    
    
}

struct User
    {
    let uid: String
    let name: String
    let email: String
    let username: String
    let bio: String
    let profileImageUrl: String?

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
