//
//  HomeViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
import SDWebImageSwiftUI

// The view model class for managing the state and data of the Home view
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var hasNotifications = false    // Indicates if there are unread notifications
    @Published var posts: [Post] = []    // List of posts to display in the feed
    @Published var isLoading = true    // Indicates if data is currently loading
    @Published var friendIds: Set<String> = []    // Set of friend IDs for the current user.
    @Published var blockedUserIds: Set<String> = []    // Set of blocked user IDs.
    @Published var isFetching = false    // Tracks whether data fetching is in progress.
    @Published var userManager: UserManager // Manages user-related logic and actions.

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

     // MARK: - Initializer
    init() {
        self.userManager = UserManager()
    }

    // MARK: - Supporting functions
    
    // Function to fetch the user ids of friends of current user in session
        func fetchFriends(completion: @escaping () -> Void) {
            // Check if there is a current user logged in
            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
                print("DEBUG: No current user found")   // If no user is logged in, log a debug message
                completion()        // Call completion handler to signal that the function has finished
                return
            }
            
            print("DEBUG: Starting to fetch friends for user: \(currentUserId)")    // Log the start of the fetching process
            let db = FirebaseManager.shared.firestore           // Reference the Firestore database
            
            // Get the "friends" document for the current user using their UID
            db.collection("friends").document(currentUserId).getDocument { friendsSnapshot, friendsError in
                // Check if there was an error fetching the friends document
                if let friendsError = friendsError {
                    print("DEBUG: Error fetching friends: \(friendsError)")         // Log the error for debugging
                    completion()                        // Call completion handler to signal the end of the process
                    return
                }
                
                // If the friends document exists, proceed with extracting friend data
                if let friendsSnapshot = friendsSnapshot, friendsSnapshot.exists {
                    print("DEBUG: Found friends document for user: \(currentUserId)")   // Log successful retrieval
                    
                    // Retrieve the friends array from the document, if available
                    if let friendsArray = friendsSnapshot.data()?["friends"] as? [String] {
                        print("DEBUG: Found \(friendsArray.count) friends")     // Log the count of friends
                        
                        // Fetch blocked users for the current user
                        db.collection("blocks").document(currentUserId).getDocument { blocksSnapshot, blocksError in
                            // Check if there was an error fetching the blocked users document
                            if let blocksError = blocksError {
                                print("DEBUG: Error fetching blocked users: \(blocksError)")    // Log the error
                                completion()            // Call completion handler to signal the end of the process
                                return
                            }
                            
                            // Retrieve the blocked user IDs, defaulting to an empty array if not found
                            let blockedUserIds = blocksSnapshot?.data()?["blockedUserIds"] as? [String] ?? []
                            print("DEBUG: Blocked user IDs: \(blockedUserIds)") // Log the blocked user IDs
                            
                            // Filter the friends array to exclude blocked users
                            let filteredFriendIds = friendsArray.filter { !blockedUserIds.contains($0) }
                            print("DEBUG: Filtered friend IDs: \(filteredFriendIds)")   // Log the filtered list of friends
                            
                            // Add the filtered friend IDs to the friendIds set
                            self.friendIds = Set(filteredFriendIds)
                            
                            print("DEBUG: Total non-blocked friends found: \(self.friendIds.count)")                // Log the number of non-blocked friends
                            print("DEBUG: Non-blocked friends list: \(self.friendIds)") // Log the final list of non-blocked friends
                            
                            completion()                // Call completion handler to signal the function has finished
                        }
                    } else {
                        print("DEBUG: No friends array found in document")       // Log if the friends array is missing
                        completion()                                    // Call completion handler to signal the end of the process
                    }
                } else {
                    print("DEBUG: No friends document found for user")       // Log if the friends document doesn't exist
                    completion()                                // Call completion handler to signal the end of the process
                }
            }
        }
        
    // Function to fetch all the friends posts excluding the blocked users
        func fetchAllPosts() {
            print("DEBUG: Starting fetchAllPosts")               // Log the start of fetching posts
            isLoading = true                                // Set loading state to true while posts are being fetched
            
            // Fetch the current user's friends
            fetchFriends {
                // Check if the current user is logged in
                guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
                    print("DEBUG: No current user found when fetching posts")    // Log if no user is logged in
                    self.isLoading = false                              // Set loading state to false when there's no user
                    return
                }
                
                print("DEBUG: Current user ID: \(currentUserId)")           // Log the current user's ID
                
                // Convert the Set of friend IDs to an array
                let friendIdsArray = Array(self.friendIds)
                print("DEBUG: Friends array count: \(friendIdsArray.count)")        // Log the number of friends
                
                // If no friends are found, stop fetching posts
                if friendIdsArray.isEmpty {
                    print("DEBUG: No friends found, stopping post fetch")       // Log if no friends are found
                    self.isLoading = false                              // Set loading state to false
                    return
                }
                
                print("DEBUG: Starting to fetch posts for \(friendIdsArray.count) friends") // Log the start of fetching posts for friends
                
                // First, fetch blocked users to exclude their posts
                FirebaseManager.shared.firestore
                    .collection("blocks")
                    .document(currentUserId)
                    .addSnapshotListener { blockSnapshot, blockError in
                        // Handle errors in fetching blocked users
                        if let blockError = blockError {
                            print("DEBUG: Error fetching blocks: \(blockError)")    // Log error while fetching blocked users
                            return
                        }
                        
                        // Get the list of blocked user IDs
                        let blockedUserIds = Set((blockSnapshot?.data()?["blockedUserIds"]   as? [String]) ?? [])
                        
                        // Now fetch posts with real-time updates
                        FirebaseManager.shared.firestore
                            .collection("user_posts")
                            .whereField("uid", in: friendIdsArray)          // Fetch posts by friends only
                            .order(by: "timestamp", descending: true)       // Order posts by timestamp (latest first)
                            .addSnapshotListener { querySnapshot, error in
                                // Handle errors in fetching posts
                                if let error = error {
                                    print("DEBUG: Error fetching posts: \(error)")      // Log error while fetching posts
                                    return
                                }
                                
                                // Log the number of changes (added, modified, deleted) in the snapshot
                                print("DEBUG: Received snapshot with \(querySnapshot?.documentChanges.count ?? 0) changes")
                                
                                // Create a Set to track processed post IDs to avoid duplicates
                                var processedPostIds = Set<String>()
                                
                                // Loop through each document change in the snapshot
                                querySnapshot?.documentChanges.forEach { change in
                                    switch change.type {
                                    case .added:
                                        let postId = change.document.documentID         // Get the post ID
                                        print("DEBUG: Processing post: \(postId)")      // Log post being processed
                                        
                                        // Skip processing if the post has already been processed
                                        if processedPostIds.contains(postId) {
                                            print("DEBUG: Skipping already processed post: \(postId)")                          // Log skipped post
                                            return
                                        }
                                        processedPostIds.insert(postId)              // Mark the post as processed
                                            
                                        let data = change.document.data()           // Get the post data
                                        print("DEBUG: Post author ID: \(data["uid"] as? String ?? "unknown")")                  // Log the author of the post
                                        
                                        // Skip posts from blocked users
                                        guard let postUserId = data["uid"] as? String,
                                              !blockedUserIds.contains(postUserId) else {
                                            print("DEBUG: Skipping post from blocked user")  // Log skipped post from blocked user
                                            return
                                        }
                                        
                                        // Get the location reference from the post data
                                        guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                                        
                                        // Fetch location details for the post using the location reference
                                        locationRef.getDocument { locationSnapshot, locationError in
                                            // Fetch user details for the post author using the UID from the post data
                                            if let locationData = locationSnapshot?.data(),
                                               let address = locationData["address"] as? String {
                                                
                                                // Fetch user details for the post author
                                                if let uid = data["uid"] as? String {
                                                    FirebaseManager.shared.firestore
                                                        .collection("users")    // Access the 'users' collection
                                                        .document(uid)          // Use the user’s UID to fetch the document
                                                        .getDocument { userSnapshot, userError in
                                                            // If the user snapshot exists and contains valid data, proceed
                                                            if let userData = userSnapshot?.data() {
                                                                // Create a new Post object with the data from the post and user details
                                                                let post = Post(
                                                                    id: postId,  // Post ID
                                                                    description: data["description"] as? String ?? "",      // Post description
                                                                    rating: data["rating"] as? Int ?? 0,     // Rating for the post
                                                                    locationRef: locationRef,       // Location reference
                                                                    locationAddress: address,            // Address from location data
                                                                    imageUrls: data["images"] as? [String] ?? [],           // List of image URLs
                                                                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),        // Timestamp of the post
                                                                    uid: uid,        // User ID of the post author
                                                                    username: userData["username"] as? String ?? "User",        // Username of the post author
                                                                    userProfileImageUrl: userData["profileImageUrl"] as? String ?? ""        // Profile image URL of the post author
                                                                )
                                                                
                                                                // Update the UI on the main thread
                                                                DispatchQueue.main.async {
                                                                    // Only add the post if it is not from a blocked user
                                                                    if !blockedUserIds.contains(post.uid) {
                                                                        // Remove any existing post with the same ID before adding the new post
                                                                        self.posts.removeAll { $0.id == post.id }   // Add the new post to the posts array
                                                                        self.posts.append(post)
                                                                        // Sort the posts array by timestamp in descending order
                                                                        self.posts.sort { $0.timestamp > $1.timestamp }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                        }
                                        
                                    case .modified:
                                        print("DEBUG: Post modified: \(change.document.documentID)")    // Log the post ID that was modified
                                        let postId = change.document.documentID      // Get the ID of the modified post
                                        let data = change.document.data()           // Extract the data of the modified post from the document
                                        
                                        // Check if the post is from a blocked user
                                        if let uid = data["uid"] as? String {   // Ensure the "uid" field exists in the data
                                            if blockedUserIds.contains(uid) {
                                                // Check if the user ID is in the blocked list
                                                // If the user is blocked, remove the post from the displayed posts
                                                DispatchQueue.main.async {
                                                    self.posts.removeAll { $0.uid == uid }   // Remove all posts by the blocked user
                                                }
                                                return          // Exit the method if the user is blocked, no further processing is needed
                                            }
                                            
                                            // If the user is not blocked, continue processing the modified post
                                            guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                                            
                                            // Fetch location details using the location reference
                                            locationRef.getDocument { locationSnapshot, locationError in
                                                // If location data exists and contains an address, proceed
                                                if let locationData = locationSnapshot?.data(),
                                                   let address = locationData["address"] as? String {
                                                    
                                                    // Fetch user details of the post author using the UID
                                                    FirebaseManager.shared.firestore
                                                        .collection("users")         // Access the "users" collection
                                                        .document(uid)              // Fetch the document of the user by their UID
                                                        .getDocument { userSnapshot, userError in
                                                            // If user data exists, proceed to update the post
                                                            if let userData = userSnapshot?.data() {
                                                                // Create an updated Post object with the modified data
                                                                let updatedPost = Post(
                                                                    id: postId,     // Use the post ID
                                                                    description: data["description"] as? String ?? "",          // Get the post description
                                                                    rating: data["rating"] as? Int ?? 0,         // Get the post rating
                                                                    locationRef: locationRef,           // Include the location reference
                                                                    locationAddress: address,               // Include the location address
                                                                    imageUrls: data["images"] as? [String] ?? [],               // Get the image URLs associated with the post
                                                                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),             // Get the timestamp of the post
                                                                    uid: uid,    // User ID of the post author
                                                                    username: userData["username"] as? String ?? "User",     // Get the username of the post author
                                                                    userProfileImageUrl: userData["profileImageUrl"] as? String ?? ""       // Get the profile image URL of the post author
                                                                )
                                                                
                                                                // Update the post in the UI on the main thread
                                                                DispatchQueue.main.async {
                                                                    // Find the index of the post to be updated in the posts array
                                                                    if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                                                                        self.posts[index] = updatedPost // Replace the old post with the updated post
                                                                    }
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                        }
                                        // Handle the removal of a post
                                    case .removed:
                                        print("DEBUG: Post removed: \(change.document.documentID)")     // Log the post
                                        let postId = change.document.documentID // Get the ID of the removed post
                                        
                                        // Remove the post from the displayed posts in the UI
                                        DispatchQueue.main.async {
                                            self.posts.removeAll { $0.id == postId }     // Remove the post with the matching ID from the posts array
                                        }
                                    }
                                }
                                
                                // Also remove any posts authored by blocked users from the displayed posts
                                DispatchQueue.main.async {
                                    // Remove all posts where the user is in the blocked user list
                                    self.posts.removeAll { blockedUserIds.contains($0.uid) }    // Check if the user ID is in the blocked user list, and remove those posts
                                    print("DEBUG: Total posts in feed after block filter: \(self.posts.count)") // Log the number of posts after filtering blocked users
                                    self.isLoading = false  // Indicate that the loading process is complete by setting isLoading to false
                                }
                            }
                    }
            }
        }

    // Function to get the list of blocked user ids of the current user in session
        func setupBlockedUsersListener() {
            // Get the current user's ID, return if not available
            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
            
            // Set up a listener for changes in the "blocks" collection for the current user
            FirebaseManager.shared.firestore
                .collection("blocks")                       // Access the "blocks" collection
                .document(currentUserId)                    // Select the document for the current user
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        // If there is an error while fetching the snapshot, print it
                        print("Error listening for blocks: \(error)")       // Log the error
                        return
                    }
                    
                    // If the document exists, extract the blocked user IDs from it
                    if let document = documentSnapshot, document.exists {
                        // Get the list of blocked user IDs (defaulting to an empty array if not available)
                        let blockedUsers = document.data()?["blockedUserIds"] as? [String] ?? []
                        // Convert the list to a Set to eliminate duplicates and improve lookup performance
                        self.blockedUserIds = Set(blockedUsers)
                        
                        // Filter out posts from blocked users
                        self.posts = self.posts.filter { post in
                            !self.blockedUserIds.contains(post.uid)         // Remove posts by blocked users
                        }
                    } else {
                        // If no document exists (e.g., no blocks), initialize an empty set of blocked user IDs
                        self.blockedUserIds = []
                    }
                }
        }

    // Function to fetch the notifications for the current user
        func checkIfNotifications() {
            // Call the fetchNotifications method from userManager to fetch notifications
            userManager.fetchNotifications {result in
                // Handle the result of the fetch request
                switch result {
                case .success(let notifications):                   // If fetching was successful
                    // Print the number of notifications fetched successfully
                    print("Fetched \(notifications.count) notifications successfully.")
                    
                case .failure(let error):                        // If fetching failed
                    // Print the error message if the fetching failed
                    print("Error fetching notifications: \(error.localizedDescription)")
                    // Handle the error, e.g., show an alert or log the issue
                }
            }
        }
        
    // Helper function to get safe area top padding
        private func getSafeAreaTop() -> CGFloat {
            // Check if the first connected scene is a UIWindowScene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {         // Get the first window of the scene
                // Return the top safe area inset of the window
                return window.safeAreaInsets.top
            }
            // If the safe area cannot be determined, return 0
            return 0
        }
}

