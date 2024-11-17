//
//  PostCard.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-11-17.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

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
