//
//  HomeViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
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
            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
                print("DEBUG: No current user found")
                completion()
                return
            }
            
            print("DEBUG: Starting to fetch friends for user: \(currentUserId)")
            let db = FirebaseManager.shared.firestore
            
            // Get the friends document for the current user using their UID
            db.collection("friends").document(currentUserId).getDocument { friendsSnapshot, friendsError in
                if let friendsError = friendsError {
                    print("DEBUG: Error fetching friends: \(friendsError)")
                    completion()
                    return
                }
                
                if let friendsSnapshot = friendsSnapshot, friendsSnapshot.exists {
                    print("DEBUG: Found friends document for user: \(currentUserId)")
                    
                    // Get the friends array from the document
                    if let friendsArray = friendsSnapshot.data()?["friends"] as? [String] {
                        print("DEBUG: Found \(friendsArray.count) friends")
                        
                        // Fetch blocked users
                        db.collection("blocks").document(currentUserId).getDocument { blocksSnapshot, blocksError in
                            if let blocksError = blocksError {
                                print("DEBUG: Error fetching blocked users: \(blocksError)")
                                completion()
                                return
                            }
                            
                            let blockedUserIds = blocksSnapshot?.data()?["blockedUserIds"] as? [String] ?? []
                            print("DEBUG: Blocked user IDs: \(blockedUserIds)")
                            
                            // Filter out blocked users from the friends list
                            let filteredFriendIds = friendsArray.filter { !blockedUserIds.contains($0) }
                            print("DEBUG: Filtered friend IDs: \(filteredFriendIds)")
                            
                            // Add filtered friends to the Set
                            self.friendIds = Set(filteredFriendIds)
                            
                            print("DEBUG: Total non-blocked friends found: \(self.friendIds.count)")
                            print("DEBUG: Non-blocked friends list: \(self.friendIds)")
                            
                            completion()
                        }
                    } else {
                        print("DEBUG: No friends array found in document")
                        completion()
                    }
                } else {
                    print("DEBUG: No friends document found for user")
                    completion()
                }
            }
        }
        
        // Function to fetch all the friends posts excluding the blocked users
        func fetchAllPosts() {
            print("DEBUG: Starting fetchAllPosts")
            isLoading = true
            
            fetchFriends {
                guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
                    print("DEBUG: No current user found when fetching posts")
                    self.isLoading = false
                    return
                }
                
                print("DEBUG: Current user ID: \(currentUserId)")
                
                let friendIdsArray = Array(self.friendIds)
                print("DEBUG: Friends array count: \(friendIdsArray.count)")
                
                if friendIdsArray.isEmpty {
                    print("DEBUG: No friends found, stopping post fetch")
                    self.isLoading = false
                    return
                }
                
                print("DEBUG: Starting to fetch posts for \(friendIdsArray.count) friends")
                
                // First fetch blocked users
                FirebaseManager.shared.firestore
                    .collection("blocks")
                    .document(currentUserId)
                    .addSnapshotListener { blockSnapshot, blockError in
                        if let blockError = blockError {
                            print("DEBUG: Error fetching blocks: \(blockError)")
                            return
                        }
                        
                        // Get current blocked users
                        let blockedUserIds = Set((blockSnapshot?.data()?["blockedUserIds"] as? [String]) ?? [])
                        
                        // Now fetch posts with real-time updates
                        FirebaseManager.shared.firestore
                            .collection("user_posts")
                            .whereField("uid", in: friendIdsArray)
                            .order(by: "timestamp", descending: true)
                            .addSnapshotListener { querySnapshot, error in
                                if let error = error {
                                    print("DEBUG: Error fetching posts: \(error)")
                                    return
                                }
                                
                                print("DEBUG: Received snapshot with \(querySnapshot?.documentChanges.count ?? 0) changes")
                                
                                // Create a Set to track processed post IDs
                                var processedPostIds = Set<String>()
                                
                                querySnapshot?.documentChanges.forEach { change in
                                    switch change.type {
                                    case .added:
                                        let postId = change.document.documentID
                                        print("DEBUG: Processing post: \(postId)")
                                        
                                        // Skip if we've already processed this post
                                        if processedPostIds.contains(postId) {
                                            print("DEBUG: Skipping already processed post: \(postId)")
                                            return
                                        }
                                        processedPostIds.insert(postId)
                                        
                                        let data = change.document.data()
                                        print("DEBUG: Post author ID: \(data["uid"] as? String ?? "unknown")")
                                        
                                        // Skip if post is from blocked user
                                        guard let postUserId = data["uid"] as? String,
                                              !blockedUserIds.contains(postUserId) else {
                                            print("DEBUG: Skipping post from blocked user")
                                            return
                                        }
                                        
                                        // Get the location reference
                                        guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                                        
                                        // Fetch location details
                                        locationRef.getDocument { locationSnapshot, locationError in
                                            if let locationData = locationSnapshot?.data(),
                                               let address = locationData["address"] as? String {
                                                
                                                // Fetch user details
                                                if let uid = data["uid"] as? String {
                                                    FirebaseManager.shared.firestore
                                                        .collection("users")
                                                        .document(uid)
                                                        .getDocument { userSnapshot, userError in
                                                            if let userData = userSnapshot?.data() {
                                                                let post = Post(
                                                                    id: postId,
                                                                    description: data["description"] as? String ?? "",
                                                                    rating: data["rating"] as? Int ?? 0,
                                                                    locationRef: locationRef,
                                                                    locationAddress: address,
                                                                    imageUrls: data["images"] as? [String] ?? [],
                                                                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                                                    uid: uid,
                                                                    username: userData["username"] as? String ?? "User",
                                                                    userProfileImageUrl: userData["profileImageUrl"] as? String ?? ""
                                                                )
                                                                
                                                                DispatchQueue.main.async {
                                                                    if !blockedUserIds.contains(post.uid) {
                                                                        // Remove any existing post with the same ID before adding
                                                                        self.posts.removeAll { $0.id == post.id }
                                                                        self.posts.append(post)
                                                                        self.posts.sort { $0.timestamp > $1.timestamp }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                        }
                                        
                                    case .modified:
                                        print("DEBUG: Post modified: \(change.document.documentID)")
                                        let postId = change.document.documentID
                                        let data = change.document.data()
                                        
                                        // Check if post is from blocked user
                                        if let uid = data["uid"] as? String {
                                            if blockedUserIds.contains(uid) {
                                                // Remove post if user was blocked
                                                DispatchQueue.main.async {
                                                    self.posts.removeAll { $0.uid == uid }
                                                }
                                                return
                                            }
                                            
                                            // Continue with post modification if user is not blocked
                                            guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                                            
                                            locationRef.getDocument { locationSnapshot, locationError in
                                                if let locationData = locationSnapshot?.data(),
                                                   let address = locationData["address"] as? String {
                                                    
                                                    FirebaseManager.shared.firestore
                                                        .collection("users")
                                                        .document(uid)
                                                        .getDocument { userSnapshot, userError in
                                                            if let userData = userSnapshot?.data() {
                                                                let updatedPost = Post(
                                                                    id: postId,
                                                                    description: data["description"] as? String ?? "",
                                                                    rating: data["rating"] as? Int ?? 0,
                                                                    locationRef: locationRef,
                                                                    locationAddress: address,
                                                                    imageUrls: data["images"] as? [String] ?? [],
                                                                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                                                    uid: uid,
                                                                    username: userData["username"] as? String ?? "User",
                                                                    userProfileImageUrl: userData["profileImageUrl"] as? String ?? ""
                                                                )
                                                                
                                                                DispatchQueue.main.async {
                                                                    if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                                                                        self.posts[index] = updatedPost
                                                                    }
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                        }
                                    case .removed:
                                        print("DEBUG: Post removed: \(change.document.documentID)")
                                        let postId = change.document.documentID
                                        DispatchQueue.main.async {
                                            self.posts.removeAll { $0.id == postId }
                                        }
                                    }
                                }
                                
                                // Also remove any existing posts from blocked users
                                DispatchQueue.main.async {
                                    self.posts.removeAll { blockedUserIds.contains($0.uid) }
                                    print("DEBUG: Total posts in feed after block filter: \(self.posts.count)")
                                    self.isLoading = false
                                }
                            }
                    }
            }
        }



        // Function to get the list of blocked user ids of the current user in session
        func setupBlockedUsersListener() {
            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
            
            FirebaseManager.shared.firestore
                .collection("blocks")
                .document(currentUserId)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        print("Error listening for blocks: \(error)")
                        return
                    }
                    
                    if let document = documentSnapshot, document.exists {
                        let blockedUsers = document.data()?["blockedUserIds"] as? [String] ?? []
                        self.blockedUserIds = Set(blockedUsers)
                        
                        // Filter out posts from blocked users
                        self.posts = self.posts.filter { post in
                            !self.blockedUserIds.contains(post.uid)
                        }
                    } else {
                        self.blockedUserIds = []
                    }
                }
        }

        // Function to fetch the notifications for the current user
        func checkIfNotifications() {
            userManager.fetchNotifications {result in
                switch result {
                case .success(let notifications):
                    print("Fetched \(notifications.count) notifications successfully.")
                    
                case .failure(let error):
                    print("Error fetching notifications: \(error.localizedDescription)")
                    // Handle the error, e.g., show an alert or log the issue
                }
            }
        }
        
        // Helper function to get safe area top padding
        private func getSafeAreaTop() -> CGFloat {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window.safeAreaInsets.top
            }
            return 0
        }
}
