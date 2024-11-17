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
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
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
                    
                    // Posts feed
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if friendIds.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.2")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Add friends to see their posts")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else if posts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No posts from friends yet")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
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
        db.collection("friends").document(currentUserId).getDocument { document, error in
            if let error = error {
                print("DEBUG: Error fetching friends: \(error)")
                return
            }
            
            if let document = document, document.exists {
                print("DEBUG: Found friends document for user: \(currentUserId)")
                
                // Get the friends array from the document
                if let friendsArray = document.data()?["friends"] as? [String] {
                    print("DEBUG: Found \(friendsArray.count) friends")
                    
                    // Add all friends to the Set
                    self.friendIds = Set(friendsArray)
                    
                    print("DEBUG: Total friends found: \(self.friendIds.count)")
                    print("DEBUG: Friends list: \(self.friendIds)")
                } else {
                    print("DEBUG: No friends array found in document")
                }
            } else {
                print("DEBUG: No friends document found for user")
            }
            
            completion()
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

struct PostCard: View {
    let post: Post
    @EnvironmentObject var userManager: UserManager
    @State private var currentImageIndex = 0
    @State private var comments: [Comment] = []
    @State private var commentCount: Int = 0
    @State private var likesCount: Int = 0  // Track the like count
    @State private var likedByUserIds: [String] = []  // Track the list of users who liked the post
    @State private var liked: Bool = false  // Track if the current user has liked the post

    var body: some View {
        NavigationLink(destination: PostView(post: post, likesCount: likesCount, liked:liked)) {
            VStack(alignment: .leading, spacing: 8) {
                // User info header
                HStack {
                    if let imageUrl = URL(string: post.userProfileImageUrl) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    }
                    
                    NavigationLink(destination: ProfileView(user_uid: post.uid)) {
                        Text(post.username)
                            .font(.headline)
                            .foregroundColor(.customPurple)  // Optional: To make the username look clickable
                    }
                    
                    Spacer()
                    
                    Text(formatDate(post.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Post images
                if !post.imageUrls.isEmpty {
                    TabView(selection: $currentImageIndex) {
                        ForEach(post.imageUrls.indices, id: \.self) { index in
                            if let imageUrl = URL(string: post.imageUrls[index]) {
                                WebImage(url: imageUrl)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .clipped()
                                    .tag(index)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .foregroundColor(.gray)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                    .cornerRadius(12)
                }
                
                // Post description
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.body)
                }
                
                HStack {
                    Button(action: {
                        toggleLike()
                    }) {
                        HStack(spacing: 4) {
                            // Heart icon that changes based on whether the post is liked
                            Image(systemName: liked ? "heart.fill" : "heart")  // Filled heart if liked, empty if not
                                .foregroundColor(liked ? .red : .gray)  // Red if liked, gray if not
                                .padding(5)
                            
                            // Display like count
                            Text("\(likesCount)")
                                .foregroundColor(.gray)  // Like count in gray
                        }

                    }
                    
                    Spacer()
                        .frame(width: 20)
                    
                    Button(action: {
                        // Comment action
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right.fill")
                                .foregroundColor(.customPurple)
                            Text("\(comments.count)")  // Use the updated comments count
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Location and rating
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.customPurple)
                        Text(post.locationAddress)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.customPurple)
                        Text("\(post.rating)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.gray)
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
            .onAppear {
                // Fetch likes count when post card appears
                fetchLikes()
                // Fetch comments when the post card appears
                fetchComments()
            }
        }
    }

    private func fetchLikes() {
        let db = FirebaseManager.shared.firestore
        db.collection("likes")
            .whereField("postId", isEqualTo: post.id) // Filter likes by post ID
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching likes: \(error)")
                } else {
                    // Count how many users liked the post
                    self.likesCount = snapshot?.documents.count ?? 0
                    
                    // Track users who liked this post
                    self.likedByUserIds = snapshot?.documents.compactMap { document in
                        return document.data()["userId"] as? String
                    } ?? []
                    
                    // Check if the current user liked the post
                    if let currentUserId = FirebaseManager.shared.auth.currentUser?.uid {
                        self.liked = self.likedByUserIds.contains(currentUserId)
                    }
                }
            }
    }

    private func toggleLike() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let db = FirebaseManager.shared.firestore
        
        // If the post is already liked by the current user, remove the like
        if liked {
            db.collection("likes")
                .whereField("postId", isEqualTo: post.id)
                .whereField("userId", isEqualTo: currentUserId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error removing like: \(error)")
                    } else if let document = snapshot?.documents.first {
                        document.reference.delete { err in
                            if let err = err {
                                print("Error removing like: \(err)")
                            } else {
                                self.likesCount -= 1
                                self.liked = false
                            }
                        }
                    }
                }
        } else {
            // Otherwise, add a like
            db.collection("likes").addDocument(data: [
                "postId": post.id,
                "userId": currentUserId,
                "timestamp": Timestamp()
            ]) { error in
                if let error = error {
                    print("Error adding like: \(error)")
                } else {
                    self.likesCount += 1
                    self.liked = true
                }
            }
            
        userManager.sendLikeNotification(likerId: userManager.currentUser?.uid ?? "", post: post) { success, error in
            if success {
                print("Like notification sent successfully!")
            } else {
                if let error = error {
                    print("Failed to send like notification: \(error.localizedDescription)")
                } else {
                    print("Failed to send like notification for an unknown reason.")
                }
            }
        }
            
        }
    }
    
    private func fetchComments() {
        let db = FirebaseManager.shared.firestore
        db.collection("comments")
            .whereField("pid", isEqualTo: post.id) // Filter comments by post ID
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error)")
                } else {
                    // Decode Firestore documents into Comment objects
                    self.comments = snapshot?.documents.compactMap { document in
                        Comment(document: document)
                    } ?? []
                    
                    // Update comment count
                    self.commentCount = self.comments.count
                }
            }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
