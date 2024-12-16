//
//  AllUsersSearchViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation

class AllUsersSearchViewModel: ObservableObject {
    // A published array that holds all users. This will trigger a UI update when modified.
    @Published var users = [User]() // Use your User model
    
    // A published array to hold the users filtered based on the search query.
    @Published var filteredUsers = [User]()
    
    // A published string to hold the search query. The `didSet` property observer triggers `filterUsers()` whenever the query changes.
    @Published var searchQuery = "" {
        didSet {
            filterUsers() // Calls the `filterUsers` function every time the `searchQuery` is updated.
        }
    }
    
    // Arrays to store users who have blocked the current user and users blocked by the current user.
    @Published var blockedUsers: [String] = []
    @Published var blockedByUsers: [String] = []
    
    // A private variable to store the current user's ID.
    private var currentUserId: String?
    
    // A cache to store search query results, improving performance by avoiding repeated searches.
    private var searchCache: [String: [User]] = [:] // Cache for search queries
    
    // Initializer to set up the view model.
    init() {
        // Get the current user's ID from Firebase Authentication.
        currentUserId = FirebaseManager.shared.auth.currentUser?.uid
        
        // Fetch blocked users and users who blocked the current user sequentially.
        fetchBlockedUsers {
            self.fetchBlockedByUsers {
                // Once both lists are fetched, fetch all users.
                self.fetchAllUsers()
            }
        }
    }
    
    func fetchBlockedByUsers(completion: @escaping () -> Void) {
        // Check if the currentUserId exists; if not, call the completion handler immediately.
        guard let currentUserId = currentUserId else {
            completion() // No current user ID, so just return.
            return
        }
        
        // Fetch the 'blockedByIds' array from the current user's 'blocks' document.
        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        
        // Asynchronously fetch the document from Firebase.
        currentUserBlocksRef.getDocument { documentSnapshot, error in
            // Handle any errors that occurred during the document fetch.
            if let error = error {
                print("Error fetching blockedBy users: \(error)")
                // If there is an error, set the 'blockedByUsers' to an empty array.
                self.blockedByUsers = []
                completion() // Call the completion handler to indicate that fetching is done.
            } else if let data = documentSnapshot?.data() {
                // If the document exists and contains data, extract the 'blockedByIds' array.
                self.blockedByUsers = data["blockedByIds"] as? [String] ?? [] // Default to empty array if data is missing.
                completion() // Call the completion handler once the fetch is successful.
            } else {
                // If the document does not exist (no data), set the 'blockedByUsers' to an empty array.
                self.blockedByUsers = []
                completion() // Call the completion handler once the fetch is done.
            }
        }
    }
    
    
    func fetchBlockedUsers(completion: @escaping () -> Void) {
        // Check if the currentUserId exists. If not, return early (no further action).
        guard let currentUserId = currentUserId else { return }
        
        // Fetch the 'blockedUserIds' array from the 'blocks' document for the current user.
        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .getDocument { documentSnapshot, error in
                // Check if the document exists and contains data.
                if let data = documentSnapshot?.data() {
                    // Extract the 'blockedUserIds' array from the data.
                    // If the key doesn't exist or is of a different type, default to an empty array.
                    self.blockedUsers = data["blockedUserIds"] as? [String] ?? []
                } else {
                    // If no document data exists, set 'blockedUsers' to an empty array.
                    self.blockedUsers = []
                }
                // Call the completion handler to signal that the function is done.
                completion()
            }
    }
    
    func fetchAllUsers() {
        // Fetch all documents from the "users" collection in Firestore.
        FirebaseManager.shared.firestore.collection("users")
            .getDocuments { snapshot, error in
                // Initialize an empty array to hold the users that will be fetched.
                var allUsers = [User]()
                
                // Check if there are documents in the snapshot.
                if let documents = snapshot?.documents {
                    // Loop through each document in the snapshot.
                    for document in documents {
                        // Extract the data from each document.
                        let data = document.data()
                        
                        // Create a 'User' object using the extracted data and the document ID (user's UID).
                        let user = User(data: data, uid: document.documentID)
                        
                        // Check if the user is not the current user and is not blocked by the current user.
                        if user.uid != self.currentUserId &&
                            !self.blockedByUsers.contains(user.uid) {
                            // If both conditions are true, add the user to the 'allUsers' array.
                            allUsers.append(user)
                        }
                    }
                    
                    // Once the loop finishes, update the UI on the main thread.
                    DispatchQueue.main.async {
                        // Update the 'users' property with the fetched users.
                        self.users = allUsers
                        // Filter users based on the current search query or other criteria.
                        self.filterUsers()
                    }
                }
            }
    }
    
    
    func filterUsers() {
        // Perform all UI-related updates on the main thread to avoid threading issues.
        DispatchQueue.main.async {
            // Convert the search query to lowercase for case-insensitive comparison.
            let query = self.searchQuery.lowercased()
            
            // If the search query is empty, clear the filtered users array.
            if query.isEmpty {
                self.filteredUsers = []
            } else if let cachedResults = self.searchCache[query] {
                // If the search query exists in the cache, use the cached results to avoid re-filtering.
                self.filteredUsers = cachedResults
            } else {
                // If the search query is not in the cache, perform filtering on the users list.
                let results = self.users.filter { user in
                    // Check if the user's name or username contains the search query (case-insensitive).
                    user.name.lowercased().contains(query) ||
                    user.username.lowercased().contains(query)
                }
                // Cache the results for future use with this search query.
                self.searchCache[query] = results
                // Update the filtered users list with the search results.
                self.filteredUsers = results
            }
        }
    }
    
}
