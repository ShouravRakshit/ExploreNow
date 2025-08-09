//  PostCardViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ---------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni




import SwiftUI
import FirebaseFirestore
import Firebase

// ViewModel for managing the state and logic of a PostCard
class PostCardViewModel: ObservableObject {
    // Published properties to update the UI when changes occur
    @Published var currentImageIndex = 0 // Index for post image carousel
    @Published var comments: [Comment] = [] // List of comments on the post
    @Published var commentCount: Int = 0 // Total count of comments
    @Published var likesCount: Int = 0 // Total count of likes
    @Published var likedByUserIds: [String] = [] // List of user IDs who liked the post
    @Published var liked: Bool = false // Indicates if the current user liked the post
    @Published var isCurrentUserPost: Bool = false // Indicates if the post belongs to the current user
    @Published var showDeleteConfirmation = false // Toggles the delete confirmation alert
    @Published var blockedUserIds: Set<String> = [] // Set of user IDs blocked by the current user
    @Published var blockedByIds: Set<String> = [] // Set of user IDs who blocked the current user

    let post: Post // The post being managed
    private let userManager: UserManager // Handles user-related operations
    
    // Initializer
    init(post: Post) {
        self.post = post
        self.userManager = UserManager()
        setupInitialState()
    }
    
    // Sets up the initial state of the ViewModel
    private func setupInitialState() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isCurrentUserPost = post.uid == currentUserId
    }
    
    // Sets up listeners for real-time updates
    func setupListeners() {
        setupBlockedUsersListener() // Listen for changes to blocked users
        fetchBlockedByUsers() // Fetch users who blocked the current user
        fetchLikes() // Fetch likes on the post
        fetchComments() // Fetch comments on the post
    }
    
    // Deletes the current post
    func deletePost() {
        let db = Firestore.firestore()
        db.collection("user_posts").document(post.id).delete { error in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
            } else {
                print("Post successfully deleted")
                self.updateLocationRating(locationRef: self.post.locationRef)
                self.showDeleteConfirmation = false
            }
        }
    }
    
    // Fetches the list of users who blocked the current user
    private func fetchBlockedByUsers() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("Error fetching blockedBy users: \(error)")
                    return
                }
                
                if let document = documentSnapshot, document.exists {
                    let blockedByUsers = document.data()?["blockedByIds"] as? [String] ?? []
                    self.blockedByIds = Set(blockedByUsers)
                } else {
                    self.blockedByIds = []
                }
            }
    }
    
    // Sets up a listener for blocked users
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
                } else {
                    self.blockedUserIds = []
                }
            }
    }
    
    // Fetches total number of likes for the post
    private func fetchLikes() {
        let db = FirebaseManager.shared.firestore
        db.collection("likes")
            .whereField("postId", isEqualTo: post.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching likes: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.likesCount = 0
                    self.likedByUserIds = []
                    self.liked = false
                    return
                }
                
                let unblockedLikes = documents.compactMap { document -> String? in
                    let userId = document.data()["userId"] as? String
                    return (userId != nil && !(self.blockedUserIds.contains(userId!)) && !(self.blockedByIds.contains(userId!))) ? userId : nil
                }
                
                self.likesCount = unblockedLikes.count
                self.likedByUserIds = unblockedLikes
                
                if let currentUserId = FirebaseManager.shared.auth.currentUser?.uid {
                    self.liked = unblockedLikes.contains(currentUserId)
                }
            }
    }
    
    //Likes/unlikes the post depending on previous state
    func toggleLike() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let db = FirebaseManager.shared.firestore
        
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
                                DispatchQueue.main.async {
                                    self.likesCount -= 1
                                    self.liked = false
                                }
                            }
                        }
                    }
                }
        } else {
            db.collection("likes").addDocument(data: [
                "postId": post.id,
                "userId": currentUserId,
                "timestamp": Timestamp()
            ]) { error in
                if let error = error {
                    print("Error adding like: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self.likesCount += 1
                        self.liked = true
                    }
                }
                
                self.userManager.sendLikeNotification(likerId: currentUserId, post: self.post) { success, error in
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
    }
    
    //Fetches all comments for a post
    private func fetchComments() {
        let db = FirebaseManager.shared.firestore
        db.collection("comments")
            .whereField("pid", isEqualTo: post.id)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.comments = []
                    self.commentCount = 0
                    return
                }
                
                self.comments = documents.compactMap { document in
                    let comment = Comment(document: document)
                    return (comment != nil && !(self.blockedUserIds.contains(comment!.userID)) && !(self.blockedByIds.contains(comment!.userID))) ? comment : nil
                }
                
                self.commentCount = self.comments.count
            }
    }
    
    // Formats a date into a relative time string
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Updates the average rating for a location based on its posts
    private func updateLocationRating(locationRef: DocumentReference) {
        let db = FirebaseManager.shared.firestore
        
        db.collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting posts for rating update: \(error.localizedDescription)")
                    return
                }
                
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
                    locationRef.updateData([
                        "average_rating": newAverageRating
                    ])
                } else {
                    locationRef.updateData([
                        "average_rating": 0
                    ])
                }
            }
    }
}
