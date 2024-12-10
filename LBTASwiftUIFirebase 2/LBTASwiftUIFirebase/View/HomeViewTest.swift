//
//  HomeViewTest.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct HomeViewTest: View {
    @EnvironmentObject var userManager: UserManager
    
    @State private var hasNotifications = false // To keep track if new notifications have been added
    @State private var navigateToNotifications = false // Navigate to notifications view
    @State private var posts: [Post] = [] // List of posts that appear on home view
    @State private var isLoading = true
    @State private var friendIds: Set<String> = [] // To track the user ids of the friends of current user
    @State private var navigateToSearchView = false // Navigate to search user view
    @State private var blockedUserIds: Set<String> = [] // Track the list blocked user ids
    @State private var isFetching = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack(spacing: 16) {
                Text("ExploreNow")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                // Search Button
                NavigationLink(destination: AllUsersSearchView()) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryPurple)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.lightPurple)
                        .clipShape(Circle())
                }
                
                // Notifications Button
                NavigationLink(destination: NotificationView(userManager: userManager)) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryPurple)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.lightPurple)
                            .clipShape(Circle())
                        
                        if userManager.hasUnreadNotifications {
                            Circle()
                                .fill(AppTheme.error)
                                .frame(width: 12, height: 12)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(AppTheme.background)
            
            // Main Content
            if isLoading {
                // Loading State
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppTheme.primaryPurple)
                    
                    Text("Loading your feed...")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                    
                    // Loading Animation Dots
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(AppTheme.primaryPurple)
                                .frame(width: 8, height: 8)
                                .opacity(0.3)
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever()
                                        .delay(0.2 * Double(index)),
                                    value: isLoading
                                )
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
                
            } else if friendIds.isEmpty {
                // Empty Friends State
                EmptyStateView(
                    icon: "person.2",
                    message: "Add friends to see their posts",
                    backgroundColor: AppTheme.background
                )
                
            } else if posts.isEmpty {
                // Empty Posts State
                EmptyStateView(
                    icon: "photo.stack",
                    message: "No posts from friends yet",
                    backgroundColor: AppTheme.background
                )
                
            } else {
                // Posts Feed
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(posts) { post in
                            PostCard(post: post)
                                .environmentObject(userManager)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .background(AppTheme.background)
            }
        }
        .onAppear {
            if userManager.currentUser != nil {
                self.posts = []
                self.isLoading = true
                
                checkIfNotifications()
                setupBlockedUsersListener()
                fetchAllPosts()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isFetching = false
                }

            }
        }
    }
    
    // MARK: - UI Components
    // Helper View for Empty States
    private struct EmptyStateView: View {
        let icon: String
        let message: String
        let backgroundColor: Color
        
        var body: some View {
            ScrollView { // Wrap in ScrollView to maintain consistent layout
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 100) // Add some top spacing
                    
                    Image(systemName: icon)
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: UIScreen.main.bounds.height - 200) // Adjust height to account for nav bar and tab bar
            }
            .background(backgroundColor)
        }
    }


    // MARK: - Supporting functions
    // Function to fetch the user ids of friends of current user in session
    private func fetchFriends(completion: @escaping () -> Void) {
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
    private func fetchAllPosts() {
        print("DEBUG: Starting fetchAllPosts")
        isLoading = true
        
        fetchFriends {
            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
                print("DEBUG: No current user found when fetching posts")
                isLoading = false
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
    private func setupBlockedUsersListener() {
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
    private func checkIfNotifications() {
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
