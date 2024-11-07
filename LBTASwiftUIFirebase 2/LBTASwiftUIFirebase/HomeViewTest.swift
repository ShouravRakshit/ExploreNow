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
                        
                        Button(action: {
                            navigateToNotifications = true
                        }) {
                            ZStack {
                                Image(systemName: "bell.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                                
                                if userManager.hasUnreadNotifications {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
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
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            .fullScreenCover(isPresented: $navigateToNotifications) {
                NotificationView()
                    .environmentObject(userManager)
            }
            .onAppear {
                if userManager.currentUser != nil {
                    checkIfNotifications()
                }
                fetchAllPosts()
            }
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
    @State private var currentImageIndex = 0
    
    var body: some View {
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
                
                Text(post.username)
                    .font(.headline)
                
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
            
            // Interaction buttons (Likes and Comments)
            HStack {
                Button(action: {
                    // Like action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.customPurple)
                        Text("1.2k")
                            .foregroundColor(.gray)
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
                        Text("600")
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
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
