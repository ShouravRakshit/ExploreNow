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
    @State private var likesCount: Int = 0
    @State private var likedByUserIds: [String] = []
    @State private var liked: Bool = false
    @State private var isCurrentUserPost: Bool = false
    @State private var showDeleteConfirmation = false


    var body: some View {
        NavigationLink(destination: PostView(post: post, likesCount: likesCount, liked: liked)) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Section
                HStack(spacing: 12) {
                    // Profile Image
                    if let imageUrl = URL(string: post.userProfileImageUrl) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.lightPurple, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppTheme.secondaryText)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Username
                        NavigationLink(destination: ProfileView(user_uid: post.uid)) {
                            Text(post.username)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.primaryPurple)
                        }
                        
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(post.locationAddress)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Timestamp
                    Text(formatDate(post.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                    
                    if isCurrentUserPost {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
//                        .alert(isPresented: $showDeleteConfirmation) {
//                            Alert(
//                                title: Text("Delete Post"),
//                                message: Text("Are you sure you want to delete this post?"),
//                                primaryButton: .destructive(Text("Delete")) {
//                                    deletePost()
//                                },
//                                secondaryButton: .cancel()
//                            )
//                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Images Section
                if !post.imageUrls.isEmpty {
                    TabView(selection: $currentImageIndex) {
                        ForEach(post.imageUrls.indices, id: \.self) { index in
                            if let imageUrl = URL(string: post.imageUrls[index]) {
                                WebImage(url: imageUrl)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipped()
                                    .tag(index)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                }
                
                // Interaction Bar
                HStack(spacing: 20) {
                    // Like Button
                    Button(action: { toggleLike() }) {
                        HStack(spacing: 6) {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(liked ? .red : AppTheme.secondaryText)
                            
                            Text("\(likesCount)")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    // Comment Button
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryPurple)
                        Text("\(comments.count)")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= post.rating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(index <= post.rating ? .yellow : AppTheme.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Description
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .lineLimit(3)
                }
            }
            .background(AppTheme.background)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray6), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            fetchLikes()
            fetchComments()
            isCurrentUserPost = post.uid == userManager.currentUser?.id
        }
    }
    
    func deletePost() {
        let postId = post.id
        
        let db = Firestore.firestore()
        db.collection("user_posts").document(postId).delete { error in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
            } else {
                print("Post successfully deleted")
                updateLocationRating(locationRef: post.locationRef)
                showDeleteConfirmation = false
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
