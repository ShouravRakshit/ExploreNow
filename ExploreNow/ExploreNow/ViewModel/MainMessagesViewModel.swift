//
//  MainMessagesViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore


// MainMessagesViewModel is an ObservableObject that manages fetching and filtering recent messages for the current user.
class MainMessagesViewModel: ObservableObject {
    
    // Published properties that will notify the UI of any changes.
    @Published var errorMessage = "" // To store error messages if message fetching fails
    @Published var isUserCurrentlyLoggedOut = false // Boolean to track if the user is logged out
    @Published var recentMessages = [RecentMessage]() // Stores all recent messages retrieved from Firestore
    @Published var filteredMessages = [RecentMessage]() // Stores filtered messages based on search query
    @Published var searchQuery = "" // Holds the search query input by the user
    
    // Initializer to fetch recent messages when the view model is created
    init() {
        fetchRecentMessages() // Fetch the user's recent messages as soon as the ViewModel is initialized
    }
    
    // Fetch recent messages from Firestore for the current user
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return } // Ensure the current user is logged in
        
        // Firestore query to fetch the user's messages, ordered by timestamp in descending order
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: FirebaseConstants.timestamp, descending: true) // Order messages by timestamp
            .addSnapshotListener { [weak self] querySnapshot, error in
                // Handle any errors during the fetch
                if let error = error {
                    self?.errorMessage = "Failed to fetch recent messages: \(error)" // Set error message to be shown in the UI
                    print(error)
                    return
                }
                
                // Parse the documents and map them to RecentMessage models
                self?.recentMessages = querySnapshot?.documents.compactMap { document in
                    let data = document.data() // Get the data of the document
                    return RecentMessage(documentId: document.documentID, data: data) // Create a RecentMessage object from the data
                } ?? [] // Return an empty array if no documents found
                
                // Update the filtered messages with all recent messages (without filtering)
                DispatchQueue.main.async {
                    self?.filteredMessages = self?.recentMessages ?? []
                }
                
                // Update the recent messages with any additional user-related data (presumably involves fetching user info)
                self?.updateRecentMessagesWithUserData()
            }
    }
    
    func filterMessages(query: String) {
        // Check if the query string is empty
        if query.isEmpty {
            // If the query is empty, reset the filteredMessages to show all recent messages
            filteredMessages = recentMessages
        } else {
            // Otherwise, filter the recentMessages array based on the query string
            filteredMessages = recentMessages.filter { recentMessage in
                // Check if the recentMessage's name contains the query string (case insensitive)
                recentMessage.name?.lowercased().contains(query.lowercased()) ?? false
            }
        }
    }
    
    
    func updateRecentMessagesWithUserData() {
        // Iterate over the recentMessages array to update each message with user data
        for (index, recentMessage) in recentMessages.enumerated() {
            // Determine the UID of the user (the one opposite to the current user)
            let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
            
            // Fetch user data for the determined UID
            fetchUserData(uid: uid) { [weak self] user in
                guard let self = self else { return }  // Ensure self is still valid in the closure
                DispatchQueue.main.async {
                    // Update the recent message with the fetched user data (name and profile image)
                    self.recentMessages[index].name = user.name
                    self.recentMessages[index].profileImageUrl = user.profileImageUrl
                    // Reapply any filters to the messages based on the current search query
                    self.filterMessages(query: self.searchQuery)
                }
            }
        }
    }
    
    
    // Fetches user data from Firestore based on the provided user ID (uid).
    func fetchUserData(uid: String, completion: @escaping (ChatUser) -> Void) {
        // Creates a reference to the specific user's document in the "users" collection using their unique uid.
        let userRef = FirebaseManager.shared.firestore.collection("users").document(uid)
        
        // Fetches the document asynchronously.
        userRef.getDocument { (document, error) in
            // Handles any errors encountered during the fetch process.
            if let error = error {
                print("Error fetching user data: \(error)")
                // If an error occurs, returns an empty ChatUser object to the completion handler.
                completion(ChatUser(data: [:]))
                return
            }
            
            // Checks if the document exists.
            if let document = document, document.exists {
                // If the document exists, retrieves the data from the document (as a dictionary).
                let data = document.data() ?? [:]
                // Creates a ChatUser object using the fetched data and passes it to the completion handler.
                let user = ChatUser(data: data)
                completion(user)
            } else {
                // If the document does not exist, prints an error message and returns an empty ChatUser object.
                print("User document does not exist")
                completion(ChatUser(data: [:]))
            }
        }
    }
    
    // Handles the sign-out process for the user.
    func handleSignOut() {
        // Logs a message to indicate that the sign-out process has been triggered.
        print("Signing out user in handleSignOut")
        
        do {
            // Attempts to sign out the user using Firebase's authentication system.
            try FirebaseManager.shared.auth.signOut()
            
            // If sign-out is successful, updates the `isUserCurrentlyLoggedOut` property to reflect that the user is now logged out.
            isUserCurrentlyLoggedOut = true
        } catch {
            // If an error occurs during the sign-out process, prints the error message to the console.
            print("Failed to sign out:", error)
        }
    }
    
    
    // Function to delete a user's account from both Firebase Authentication and Firestore.
    func deleteUserAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure the current user is logged in and has a valid UID. If not, return a failure result.
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            // If the user UID is unavailable, return a failure with an appropriate error.
            completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
            return
        }
        
        // Delete the user from Firebase Authentication.
        FirebaseManager.shared.auth.currentUser?.delete { error in
            // If there's an error while deleting the user from Authentication, return a failure.
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // If Authentication deletion is successful, delete the user's data from Firestore.
            FirebaseManager.shared.firestore.collection("users").document(uid).delete { error in
                // If there's an error while deleting the user's data from Firestore, return a failure.
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // If both deletions are successful, return a success result.
                completion(.success(()))
            }
        }
    }
    
    
    // Function to initiate a password reset for a given email address.
    func changePassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Call Firebase's password reset function using the provided email.
        FirebaseManager.shared.auth.sendPasswordReset(withEmail: email) { error in
            // If there is an error in sending the password reset email, return a failure result via the completion handler.
            if let error = error {
                completion(.failure(error))
                return
            }
            // If the password reset request is successful, return a success result.
            completion(.success(()))
        }
    }
    
    
    // This function takes a Date object as input and returns a string representing
    // the relative time difference between the provided date and the current date.
    func timeAgo(_ date: Date) -> String {
        // Create an instance of RelativeDateTimeFormatter to format the time difference.
        let formatter = RelativeDateTimeFormatter()
        
        // Set the unitsStyle to `.short` to use abbreviated time units (e.g., "1h" for 1 hour, "2d" for 2 days).
        formatter.unitsStyle = .short
        
        // Use the `localizedString(for:relativeTo:)` method to generate a localized string
        // representing the time difference between the provided date and the current date (Date()).
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
