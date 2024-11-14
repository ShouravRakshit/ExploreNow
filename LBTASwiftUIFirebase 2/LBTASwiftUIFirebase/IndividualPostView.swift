import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct PostView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var comments: [Comment] = []
    @State private var commentText: String = ""
    @State private var userData: [String: (username: String, profileImageUrl: String?)] = [:] // Cache for user data
    @State private var currentUserProfileImageUrl: String? // To store the current user's profile image URL
    @State private var scrollOffset: CGFloat = 0 // To track the scroll position
    @State private var likesCount: Int = 0  // Track the like count
    @State private var liked: Bool = false  // Track if the current user has liked the post
    @State private var post: Post

        // Custom initializer to accept values passed from `PostCard`
        init(post: Post, likesCount: Int, liked: Bool) {
            self._post = State(initialValue: post)
            self._likesCount = State(initialValue: likesCount)
            self._liked = State(initialValue: liked)
        }
   
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Profile section
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
            }
            .padding()
            
            // Post images
            if !post.imageUrls.isEmpty {
                TabView {
                    ForEach(post.imageUrls.indices, id: \.self) { index in
                        if let imageUrl = URL(string: post.imageUrls[index]) {
                            WebImage(url: imageUrl)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .tag(index)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .foregroundColor(.gray)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 200)
                .cornerRadius(12)
            }
            
            // Location, Rating, Likes
            HStack {
                Label {
                    Text("\(post.locationAddress)")
                        .font(.system(size: 16))
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                }
                
                Spacer()
                
                Label {
                    Text("\(post.rating)")
                        .font(.system(size: 16))
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                // Likes are dynamic
                HStack(spacing: 4) {
                    // Heart icon that changes based on whether the post is liked
                    Image(systemName: liked ? "heart.fill" : "heart")  // Filled heart if liked, empty if not
                        .foregroundColor(liked ? .red : .gray)  // Red if liked, gray if not
                        .padding(5)
                        .onTapGesture {
                          toggleLike()  // Toggle like action
                        }
                    
                    // Display like count
                    Text("\(likesCount)")
                        .foregroundColor(.gray)  // Like count in gray
                }
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 10)
            
            // Description Box
            VStack(alignment: .leading, spacing: 8) {
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(width: 350, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 140/255, green: 82/255, blue: 255/255))
                        )
                }
            }
            .padding(.horizontal)
            
            // Comments Section
            VStack(alignment: .leading) {
                HStack {
                    Text("Comments")
                        .font(.headline)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    
                    Text("\(comments.count)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                
                // Display "No comments yet" if there are no comments
                if comments.isEmpty {
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(comments) { comment in
                                HStack(alignment: .top, spacing: 8) {
                                    if let profileImageUrl = userData[comment.userID]?.profileImageUrl,
                                       let url = URL(string: profileImageUrl) {
                                        WebImage(url: url)
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(userData[comment.userID]?.username ?? "Loading...")
                                            .font(.subheadline)
                                            .bold()
                                        Text(comment.text)
                                            .font(.body)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 140/255, green: 82/255, blue: 255/255)))
                                .onAppear {
                                    // Fetch user data if not already cached
                                    if userData[comment.userID] == nil {
                                        fetchUserData(for: comment.userID) { username, profileImageUrl in
                                            userData[comment.userID] = (username, profileImageUrl)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // "Add a comment" Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Display current user's profile image
                    if let imageUrl = currentUserProfileImageUrl, let url = URL(string: imageUrl) {
                        WebImage(url: url)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill") // Placeholder if image URL is not available
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    }
                    
                    TextField("Add a comment for @\(post.username)...", text: $commentText)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    
                    Button(action: addComment) {
                        Text("Post")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 5)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
            .onAppear {
                fetchCurrentUserProfile() // Fetch profile image on view load
                fetchLikes() // Fetch likes on view load
            }
        }
        .padding(.bottom, 20)
        .onAppear {
            fetchComments() // Fetch comments when the view appears
        }
    }
    
    private func addComment() {
        guard !commentText.isEmpty else { return } // Avoid posting empty comments
        let userID = FirebaseManager.shared.auth.currentUser?.uid
        let postId = post.id
        
        let commentData: [String: Any] = [
            "pid": postId,
            "uid": userID,
            "comment": commentText,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        let db = FirebaseManager.shared.firestore
        db.collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                print("Comment successfully added!")
                commentText = "" // Clear the input field after posting
            }
        }
        
        userManager.sendCommentNotification(commenterId: userManager.currentUser?.uid ?? "", post: post, commentMessage: commentText) { success, error in
            if success {
                print("Comment notification sent successfully!")
            } else {
                if let error = error {
                    print("Failed to send Comment notification: \(error.localizedDescription)")
                } else {
                    print("Failed to send Comment notification for an unknown reason.")
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
                }
            }
    }
    
    // Function to fetch user data
    private func fetchUserData(for userID: String, completion: @escaping (String, String?) -> Void) {
        if let cachedData = userData[userID] {
            completion(cachedData.username, cachedData.profileImageUrl)
        } else {
            let db = FirebaseManager.shared.firestore
            db.collection("users").document(userID).getDocument { document, error in
                if let error = error {
                    print("Error fetching user data: \(error)")
                    completion("Unknown", nil)
                } else if let document = document, document.exists,
                          let data = document.data(),
                          let username = data["username"] as? String {
                    let profileImageUrl = data["profileImageUrl"] as? String
                    userData[userID] = (username, profileImageUrl) // Cache the result
                    completion(username, profileImageUrl)
                } else {
                    completion("Unknown", nil)
                }
            }
        }
    }
    
    // Fetch current user profile data
    private func fetchCurrentUserProfile() {
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let db = FirebaseManager.shared.firestore
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error fetching current user data: \(error)")
            } else if let document = document, document.exists,
                      let data = document.data(),
                      let profileImageUrl = data["profileImageUrl"] as? String {
                currentUserProfileImageUrl = profileImageUrl
            }
        }
    }
    private func toggleLike() {
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        if liked {
            // Unlike the post (remove the like from Firestore)
            FirebaseManager.shared.firestore.collection("likes")
                .whereField("postId", isEqualTo: post.id)
                .whereField("userId", isEqualTo: userID)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error unliking post: \(error.localizedDescription)")
                    } else if let document = snapshot?.documents.first {
                        document.reference.delete()  // Remove like from Firestore
                        likesCount -= 1
                        liked = false
                    }
                }
        } else {
            // Like the post (add a like to Firestore)
            let likeData: [String: Any] = [
                "postId": post.id,
                "userId": userID,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            FirebaseManager.shared.firestore.collection("likes")
                .addDocument(data: likeData) { error in
                    if let error = error {
                        print("Error liking post: \(error.localizedDescription)")
                    } else {
                        likesCount += 1
                        liked = true
                    }
                }
        }
    }
    // Fetch Likes
    private func fetchLikes() {
        FirebaseManager.shared.firestore.collection("likes")  // Use firestore here
            .whereField("postId", isEqualTo: post.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching likes: \(error.localizedDescription)")
                } else {
                    likesCount = snapshot?.documents.count ?? 0
                    liked = snapshot?.documents.contains(where: { $0.data()["userId"] as? String == FirebaseManager.shared.auth.currentUser?.uid }) ?? false
                }
            }
    }
}

    
    


