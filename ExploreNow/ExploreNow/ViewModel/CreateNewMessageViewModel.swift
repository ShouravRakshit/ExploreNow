//
//  CreateNewMessageViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman,----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    @Published var users = [ChatUser]()  // Array to hold all users that can be displayed or messaged
    @Published var errorMessage = ""  // String to store error messages, if any
    @Published var searchQuery = ""  // User's search query, used to filter users
    @Published var filteredUsers = [ChatUser]()  // Array to store users filtered by the search query
    @Published var blockedUsers: [String] = []  // List of users blocked by the current user, stored as an array of user IDs
    @Published var blockedByUsers: [String] = []  // List of users who have blocked the current user, stored as an array of user IDs
    
    // Initializer that chains a series of asynchronous calls to fetch blocked users, users who have blocked the current user, and friends
    init() {
        fetchBlockedUsers {
            self.fetchBlockedByUsers {
                self.fetchFriends()  // Fetch friends after blocked users and blocked-by users are fetched
            }
        }
    }
    
    func fetchBlockedByUsers(completion: @escaping () -> Void) {
        // Ensure we have a valid current user ID before proceeding
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            completion()  // Call the completion handler if no user ID is found
            return
        }
        
        // Attempt to fetch the "blocks" document for the current user
        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .getDocument { documentSnapshot, error in
                if let error = error {
                    // If an error occurs while fetching the document, print an error message
                    print("Error fetching blockedBy users: \(error)")
                }
                
                // If the document data is available
                if let data = documentSnapshot?.data() {
                    // Assign the "blockedByIds" array from the document data to the blockedByUsers array
                    self.blockedByUsers = data["blockedByIds"] as? [String] ?? []
                } else {
                    // If no data is found, assign an empty array to blockedByUsers
                    self.blockedByUsers = []
                }
                
                // Call the completion handler after the fetch is complete
                completion()
            }
    }
    
    
    func fetchUsers(withUIDs uids: [String]) {
        var users = [ChatUser]()  // Temporary array to store fetched users
        let dispatchGroup = DispatchGroup()  // A DispatchGroup to manage asynchronous calls
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }  // Ensure current user is authenticated
        
        for uid in uids {
            if self.blockedByUsers.contains(uid) {  // Skip fetching users who have blocked the current user
                continue
            }
            
            dispatchGroup.enter()  // Enter DispatchGroup to track the start of an async task
            FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { documentSnapshot, error in
                if let error = error {  // Handle any errors encountered during the fetch
                    print("Failed to fetch user with uid \(uid): \(error.localizedDescription)")
                } else if let data = documentSnapshot?.data() {  // Successfully fetched document data
                    let user = ChatUser(data: data)  // Create a ChatUser from the fetched data
                    if user.uid != currentUserId && !self.blockedUsers.contains(user.uid) {  // Check if the user is not the current user and is not blocked
                        users.append(user)  // Add the user to the temporary users array
                    }
                }
                dispatchGroup.leave()  // Leave DispatchGroup after completing the task for this user
            }
        }
        
        dispatchGroup.notify(queue: .main) {  // Notify once all async tasks are complete
            self.users = users  // Update the 'users' array with the fetched users
            self.filterUsers()  // Apply any filtering logic if necessary
        }
    }
    
    func fetchFriends() {
        // Ensure the current user is authenticated and get their UID.
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        // Create a reference to the 'friends' collection, specifically to the current user's document.
        let friendsRef = FirebaseManager.shared.firestore.collection("friends").document(currentUserId)
        
        // Fetch the document from Firestore.
        friendsRef.getDocument { document, error in
            // Error handling if fetching the document fails.
            if let error = error {
                // Assign an error message to the errorMessage property if there's an issue fetching the document.
                self.errorMessage = "Failed to fetch friends: \(error.localizedDescription)"
                return
            }
            
            // Check if the document exists. If not, set an error message.
            guard let document = document, document.exists else {
                // If no document is found for the current user, update the error message.
                self.errorMessage = "No friends list found"
                return
            }
            
            // Extract the array of friend user IDs from the 'friends' field.
            if let friendUIDs = document.data()?["friends"] as? [String], !friendUIDs.isEmpty {
                // If there are friend IDs, call the fetchUsers function to fetch their details.
                self.fetchUsers(withUIDs: friendUIDs)
            } else {
                // If there are no friends, set an appropriate error message.
                self.errorMessage = "No friends found"
                // Update the 'users' property to an empty list and call filterUsers.
                DispatchQueue.main.async {
                    self.users = []
                    self.filterUsers()
                }
            }
        }
    }
    
    
    func fetchBlockedUsers(completion: @escaping () -> Void) {
        // Ensure the current user is authenticated and retrieve their UID.
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        // Reference the 'blocks' collection in Firestore for the current user.
        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .getDocument { documentSnapshot, error in
                // Error handling if the request fails.
                if let error = error {
                    // Print the error message to the console for debugging.
                    print("Error fetching blocked users: \(error)")
                }
                // Check if the document data exists.
                if let data = documentSnapshot?.data() {
                    // Safely cast the 'blockedUserIds' field to an array of strings.
                    self.blockedUsers = data["blockedUserIds"] as? [String] ?? []
                } else {
                    // If no data exists, initialize an empty array for blocked users.
                    self.blockedUsers = []
                }
                // Execute the completion handler to notify that the function has finished.
                completion()
            }
    }
    
    func filterUsers() {
        // If the search query is empty, return all users as filtered results.
        if searchQuery.isEmpty {
            filteredUsers = users
        } else {
            // Otherwise, filter the list of users based on the search query.
            filteredUsers = users.filter { user in
                // Check if the user's name or email contains the search query (case insensitive).
                user.name.lowercased().contains(searchQuery.lowercased()) ||
                user.email.lowercased().contains(searchQuery.lowercased())
            }
        }
    }
}
