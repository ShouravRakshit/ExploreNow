//
//  SearchUserViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class SearchUserViewModel: ObservableObject {
    @Published var searchQuery = ""  // Published property to track the search query entered by the user
    @Published var users: [ChatUser] = []  // Published array holding all fetched users from Firestore
    @Published var filteredUsers: [ChatUser] = []  // Published array holding filtered users based on the search query
    
    // Initializer for the ViewModel, automatically loads users when an instance is created
    init() {
        loadUsers()
    }
    
    // Function to load all users from Firestore
    func loadUsers() {
        let db = FirebaseManager.shared.firestore  // Reference to Firestore database
        
        // Fetching documents from the "users" collection
        db.collection("users").getDocuments { [weak self] snapshot, error in
            // Check for any error during the fetch operation
            if let error = error {
                print("Error fetching users: \(error)")  // Print error message if any
                return
            }
            
            // Ensure that there are documents in the snapshot
            guard let documents = snapshot?.documents else { return }
            
            // Map the fetched documents to ChatUser objects
            let fetchedUsers = documents.compactMap { doc -> ChatUser? in
                let data = doc.data()  // Extract the data from the Firestore document
                return ChatUser(data: data)  // Convert the data into a ChatUser object
            }
            
            // Ensure that UI updates happen on the main thread
            DispatchQueue.main.async {
                self?.users = fetchedUsers  // Set the fetched users
                self?.filteredUsers = fetchedUsers  // Set the initial filtered list to all users
            }
        }
    }

    
    func filterUsers(query: String) {
        // Step 1: If the query is empty, display all users.
        if query.isEmpty {
            filteredUsers = users
        } else {
            // Step 2: Filter users based on the query, searching in both the email and name fields.
            filteredUsers = users.filter { user in
                // Case-insensitive search for the query in both email and name.
                user.email.lowercased().contains(query.lowercased()) ||
                user.name.lowercased().contains(query.lowercased())
            }
        }
    }
}
