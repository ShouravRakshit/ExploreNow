import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore


struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var userPosts: [Post] = []
    @State private var isLoading = false
    @State private var showProfileSettings = false
    @State private var showAddPost = false
    var profileImageUrl: String?
    var name: String

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Settings Button
                HStack {
                    Spacer()
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color(red: 0.45, green: 0.3, blue: 0.7))
                        .onTapGesture {
                            showProfileSettings = true
                        }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Profile Info Section
                HStack {
                    WebImage(url: URL(string: profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(40)
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1))
                        .padding(.horizontal, 1)
                        .shadow(radius: 5)
                    
                    // Post Counts
                    VStack {
                        Text("\(userPosts.count)")
                            .font(.system(size: 20, weight: .bold))
                        Text("Posts")
                            .font(.system(size: 16))
                    }.padding(.horizontal, 40)
                    
                    // Friends Counts
                    VStack {
                        Text("\(1100)")
                            .font(.system(size: 20, weight: .bold))
                        Text("Friends")
                            .font(.system(size: 16))
                    }.padding(.horizontal, 10)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Username and Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 24, weight: .bold))
                    
                    if let bio = userManager.currentUser?.bio {
                        Text(bio)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 21)
                .padding(.top, 8)
                
                // Posts Section
                ScrollView {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if userPosts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                                .padding(.top, 40)
                            
                            Text("Share Your First Adventure!")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showAddPost = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Add Your First Post")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                                .cornerRadius(25)
                                .shadow(color: Color(red: 140/255, green: 82/255, blue: 255/255).opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else {
                        LazyVStack {
                            ForEach(userPosts) { post in
                                UserPostCard(post: post, onDelete: { deletedPost in
                                    deletePost(deletedPost)
                                })
                                .padding(.top, 10)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .background(Color.white)
            .fullScreenCover(isPresented: $showProfileSettings) {
                ProfileSettingsView()
                    .environmentObject(userManager)
            }
            .fullScreenCover(isPresented: $showAddPost) {
                AddPostView()
            }
            .onAppear {
                fetchUserPosts()
            }
        }
    }
    
    private func fetchUserPosts() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isLoading = true
        
        FirebaseManager.shared.firestore
            .collection("user_posts")
            .whereField("uid", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Failed to fetch user posts:", error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        
                        guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                        
                        // Fetch location details
                        locationRef.getDocument { locationSnapshot, locationError in
                            if let locationData = locationSnapshot?.data(),
                               let address = locationData["address"] as? String {
                                
                                let post = Post(
                                    id: change.document.documentID,
                                    description: data["description"] as? String ?? "",
                                    rating: data["rating"] as? Int ?? 0,
                                    locationRef: locationRef,
                                    locationAddress: address,
                                    imageUrls: data["images"] as? [String] ?? [],
                                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                    uid: data["uid"] as? String ?? ""
                                )
                                
                                if !userPosts.contains(where: { $0.id == post.id }) {
                                    userPosts.append(post)
                                    userPosts.sort { $0.timestamp > $1.timestamp }
                                }
                            }
                        }
                    }
                }
            }
    }
    
    private func deletePost(_ post: Post) {
        // Remove from local array first for immediate UI update
        userPosts.removeAll { $0.id == post.id }
        
        // Delete images from Storage
        for imageUrl in post.imageUrls {
            let imageRef = FirebaseManager.shared.storage.reference(forURL: imageUrl)
            imageRef.delete { error in
                if let error = error {
                    print("Error deleting image: \(error.localizedDescription)")
                }
            }
        }
        
        // Delete post document from Firestore
        FirebaseManager.shared.firestore
            .collection("user_posts")
            .document(post.id)
            .delete { error in
                if let error = error {
                    print("Error deleting post: \(error.localizedDescription)")
                    return
                }
                
                // Update location's average rating
                updateLocationRating(locationRef: post.locationRef)
            }
    }
    
    private func updateLocationRating(locationRef: DocumentReference) {
        let db = FirebaseManager.shared.firestore
        
        // Get all remaining posts for this location
        db.collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting posts for rating update: \(error.localizedDescription)")
                    return
                }
                
                // Calculate new average
                var totalRating = 0
                var count = 0
                
                snapshot?.documents.forEach { doc in
                    if let rating = doc.data()["rating"] as? Int {
                        totalRating += rating
                        count += 1
                    }
                }
                
                if count > 0 {
                    let newAverageRating = Double(totalRating) / Double(count)
                    // Update location with new average rating
                    locationRef.updateData([
                        "average_rating": newAverageRating
                    ])
                } else {
                    // Either delete the location or set rating to 0
                    locationRef.updateData([
                        "average_rating": 0
                    ])
                }
            }
    }
}

// Post Model
struct Post: Identifiable {
    let id: String
    let description: String
    let rating: Int
    let locationRef: DocumentReference
    let locationAddress: String // Add this to store the fetched location address
    let imageUrls: [String]
    let timestamp: Date
    let uid: String
}

// Updated PostCard to show actual post data
struct UserPostCard: View {
    let post: Post
    let onDelete: (Post) -> Void
    @State private var showingAlert = false
    @State private var currentImageIndex = 0
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    showingAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding([.top, .trailing])
            
            if !post.imageUrls.isEmpty {
                TabView(selection: $currentImageIndex) {
                    ForEach(post.imageUrls.indices, id: \.self) { index in
                        WebImage(url: URL(string: post.imageUrls[index]))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 172)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 172)
                .padding(.horizontal, 10)
                .padding(.top, 6)
            }
            
            Text(post.description)
                .font(.system(size: 14))
                .padding(.horizontal)
                .padding(.top, 8)
            
            HStack {
                Image(systemName: "bubble.right").foregroundColor(Color.customPurple)
                Text("600")
                
                Spacer()
                
                HStack(spacing: 10) {
                    Image(systemName: "star.fill").foregroundColor(Color.customPurple)
                    Text("\(post.rating)")
                    
                    Image(systemName: "mappin.and.ellipse").foregroundColor(Color.customPurple)
                    Text(post.locationAddress)
                        .lineLimit(1)
                }
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.customPurple, lineWidth: 1))
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Delete Post"),
                message: Text("Are you sure you want to delete this post? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    onDelete(post)
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}
