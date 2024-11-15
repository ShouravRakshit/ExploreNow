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
                    } else if posts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No posts yet")
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
        .edgesIgnoringSafeArea(.top) // To avoid clipping at the top edge of the screen
        /*
        .fullScreenCover(isPresented: $navigateToNotifications) {
            NotificationView(userManager: userManager)
                .environmentObject(userManager)
        }
         */
        .onAppear {
            //print("ON APPEAR")
            // Make sure the current user is available before checking notifications
            if userManager.currentUser != nil {
                checkIfNotifications()
            }
            fetchAllPosts()
        }
        
    }
    
    private func fetchAllPosts() {
        isLoading = true
        
        FirebaseManager.shared.firestore
            .collection("user_posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error)")
                    return
                }
                
                // Create a Set to track processed post IDs
                var processedPostIds = Set<String>()
                
                querySnapshot?.documentChanges.forEach { change in
                    switch change.type {
                    case .added:
                        let postId = change.document.documentID
                        
                        // Skip if we've already processed this post
                        if processedPostIds.contains(postId) {
                            return
                        }
                        processedPostIds.insert(postId)
                        
                        let data = change.document.data()
                        
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
                        // Remove deleted posts
                        let postId = change.document.documentID
                        DispatchQueue.main.async {
                            posts.removeAll { $0.id == postId }
                        }
                    }
                }
                
                isLoading = false
            }
    }

    private func checkIfNotifications() {
        userManager.fetchNotifications()
        hasNotifications = !(userManager.currentUser?.notifications.isEmpty ?? true)
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
