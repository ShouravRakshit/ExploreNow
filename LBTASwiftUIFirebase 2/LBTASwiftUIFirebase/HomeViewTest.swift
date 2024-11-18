import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct HomeViewTest: View {
    @EnvironmentObject var userManager: UserManager
    @State private var hasNotifications = false
    @State private var navigateToNotifications = false
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var friendIds: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with notification bell
                HStack {
                    Text("ExploreNow")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                    
                    // NavigationLink that wraps the bell icon
                    NavigationLink(destination: NotificationView(userManager: userManager), isActive: $navigateToNotifications) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                            
                            // Show unread notification indicator if there are unread notifications
                            if userManager.hasUnreadNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 8, y: -8)
                            }
                        }
                        .onTapGesture {
                            // Trigger navigation to NotificationView
                            navigateToNotifications = true
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensure the link doesn't look like a standard button
                    .padding(.trailing)
                }
                .padding(.top)
                
                // Loading and empty states
                if isLoading {
                    Spacer()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.customPurple)
                            .padding()
                        
                        Text("Loading your feed...")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        
                        // Optional: Add a subtle animation
                        HStack(spacing: 4) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.customPurple)
                                    .frame(width: 8, height: 8)
                                    .opacity(0.3)
                                    .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.2 * Double(index)))
                            }
                        }
                    }
                    Spacer()
                } else if friendIds.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Add friends to see their posts")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Spacer()
                } else if posts.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No posts from friends yet")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Spacer()
                } else {
                    // Posts feed
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                PostCard(post: post)
                                    .environmentObject(userManager)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            if userManager.currentUser != nil {
                checkIfNotifications()
            }
            fetchAllPosts()
        }
    }


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
                                                        // Remove any existing post with the same ID before adding
                                                        posts.removeAll { $0.id == post.id }
                                                        posts.append(post)
                                                        posts.sort { $0.timestamp > $1.timestamp }
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                            
                        case .modified:
                            print("DEBUG: Post modified: \(change.document.documentID)")
                            // Handle modified posts
                            let postId = change.document.documentID
                            let data = change.document.data()
                            
                            // Similar to added case, but update existing post
                            guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                            
                            locationRef.getDocument { locationSnapshot, locationError in
                                if let locationData = locationSnapshot?.data(),
                                   let address = locationData["address"] as? String {
                                    
                                    if let uid = data["uid"] as? String {
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
                                                        if let index = posts.firstIndex(where: { $0.id == postId }) {
                                                            posts[index] = updatedPost
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                            
                        case .removed:
                            print("DEBUG: Post removed: \(change.document.documentID)")
                            // Remove deleted posts
                            let postId = change.document.documentID
                            DispatchQueue.main.async {
                                posts.removeAll { $0.id == postId }
                            }
                        }
                    }
                    
                    print("DEBUG: Total posts in feed: \(self.posts.count)")
                    self.isLoading = false
                }
        }
    }

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
        //hasNotifications = !(userManager.currentUser?.notifications.isEmpty ?? true)
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


