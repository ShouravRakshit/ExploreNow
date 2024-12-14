////
////  PostCardViewModel.swift
////  LBTASwiftUIFirebase
////
////  Created by Ivan on 2024-12-13.
////
//
//import Foundation
//import Firebase
//import FirebaseFirestore
//
//class PostCardViewModel: ObservableObject {
//    @Published var currentImageIndex = 0
//    @Published var comments: [Comment] = []
//    @Published var commentCount: Int = 0
//    @Published var likesCount: Int = 0
//    @Published var likedByUserIds: [String] = []
//    @Published var liked: Bool = false
//    @Published var isCurrentUserPost: Bool = false
//    @Published var showDeleteConfirmation = false
//    @Published var blockedUserIds: Set<String> = []
//    @Published var blockedByIds: Set<String> = []
//    
//    private let post: Post
//    private var userManager: UserManager?
//    private var onDelete: ((Post) -> Void)?
//    
//    init(post: Post, onDelete: ((Post) -> Void)? = nil) {
//        self.post = post
//        self.onDelete = onDelete
//    }
//    
//    var postModel: Post {
//        return post
//    }
//    
//    func configure(userManager: UserManager) {
//        self.userManager = userManager
//    }
//    
//    func loadData() {
//        setupBlockedUsersListener()
//        fetchBlockedByUsers()
//        fetchLikes()
//        fetchComments()
//        isCurrentUserPost = post.uid == userManager?.currentUser?.id
//    }
//    
//    func deletePost() {
//            let postId = post.id
//            let db = Firestore.firestore()
//            db.collection("user_posts").document(postId).delete { error in
//                if let error = error {
//                    print("Error deleting post: \(error.localizedDescription)")
//                } else {
//                    print("Post successfully deleted")
//                    self.updateLocationRating(locationRef: self.post.locationRef)
//                    self.showDeleteConfirmation = false
//                    self.onDelete?(self.post)
//                }
//            }
//        }
//    
//    func toggleLike() {
//            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
//            
//            let db = FirebaseManager.shared.firestore
//            
//            if liked {
//                // Already liked, remove like
//                db.collection("likes")
//                    .whereField("postId", isEqualTo: post.id)
//                    .whereField("userId", isEqualTo: currentUserId)
//                    .getDocuments { snapshot, error in
//                        if let error = error {
//                            print("Error removing like: \(error)")
//                        } else if let document = snapshot?.documents.first {
//                            document.reference.delete { err in
//                                if let err = err {
//                                    print("Error removing like: \(err)")
//                                } else {
//                                    self.likesCount -= 1
//                                    self.liked = false
//                                }
//                            }
//                        }
//                    }
//            } else {
//                // Not liked, add like
//                db.collection("likes").addDocument(data: [
//                    "postId": post.id,
//                    "userId": currentUserId,
//                    "timestamp": Timestamp()
//                ]) { error in
//                    if let error = error {
//                        print("Error adding like: \(error)")
//                    } else {
//                        self.likesCount += 1
//                        self.liked = true
//                        self.sendLikeNotification()
//                    }
//                }
//            }
//        }
//    
//    private func sendLikeNotification() {
//        userManager?.sendLikeNotification(likerId: userManager?.currentUser?.id ?? "", post: post) { success, error in
//               if success {
//                   print("Like notification sent successfully!")
//               } else {
//                   if let error = error {
//                       print("Failed to send like notification: \(error.localizedDescription)")
//                   } else {
//                       print("Failed to send like notification for an unknown reason.")
//                   }
//               }
//           }
//       }
//    
//    private func fetchBlockedByUsers() {
//            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
//
//            FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
//                .addSnapshotListener { documentSnapshot, error in
//                    if let error = error {
//                        print("Error fetching blockedBy users: \(error)")
//                        return
//                    }
//
//                    if let document = documentSnapshot, document.exists {
//                        let blockedByUsers = document.data()?["blockedByIds"] as? [String] ?? []
//                        self.blockedByIds = Set(blockedByUsers)
//                    } else {
//                        self.blockedByIds = []
//                    }
//                }
//        }
//    
//    private func setupBlockedUsersListener() {
//            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
//            
//            FirebaseManager.shared.firestore
//                .collection("blocks")
//                .document(currentUserId)
//                .addSnapshotListener { documentSnapshot, error in
//                    if let error = error {
//                        print("Error listening for blocks: \(error)")
//                        return
//                    }
//                    
//                    if let document = documentSnapshot, document.exists {
//                        let blockedUsers = document.data()?["blockedUserIds"] as? [String] ?? []
//                        self.blockedUserIds = Set(blockedUsers)
//                        
//                    } else {
//                        self.blockedUserIds = []
//                    }
//                }
//        }
//
//        private func fetchLikes() {
//            let db = FirebaseManager.shared.firestore
//            db.collection("likes")
//                .whereField("postId", isEqualTo: post.id)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("Error fetching likes: \(error)")
//                        return
//                    }
//
//                    guard let documents = snapshot?.documents else {
//                        self.likesCount = 0
//                        self.likedByUserIds = []
//                        self.liked = false
//                        return
//                    }
//
//                    let unblockedLikes = documents.compactMap { document -> String? in
//                        let userId = document.data()["userId"] as? String
//                        return (userId != nil &&
//                                !self.blockedUserIds.contains(userId!) &&
//                                !self.blockedByIds.contains(userId!)) ? userId : nil
//                    }
//
//                    self.likesCount = unblockedLikes.count
//                    self.likedByUserIds = unblockedLikes
//
//                    if let currentUserId = FirebaseManager.shared.auth.currentUser?.uid {
//                        self.liked = unblockedLikes.contains(currentUserId)
//                    }
//                }
//        }
//
//        private func fetchComments() {
//            let db = FirebaseManager.shared.firestore
//            db.collection("comments")
//                .whereField("pid", isEqualTo: post.id)
//                .order(by: "timestamp", descending: true)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("Error fetching comments: \(error)")
//                        return
//                    }
//
//                    guard let documents = snapshot?.documents else {
//                        self.comments = []
//                        self.commentCount = 0
//                        return
//                    }
//
//                    self.comments = documents.compactMap { document in
//                        let comment = Comment(document: document)
//                        return (comment != nil &&
//                                !self.blockedUserIds.contains(comment!.userID) &&
//                                !self.blockedByIds.contains(comment!.userID)) ? comment : nil
//                    }
//
//                    self.commentCount = self.comments.count
//                }
//        }
//
//        private func updateLocationRating(locationRef: DocumentReference) {
//            let db = FirebaseManager.shared.firestore
//            
//            db.collection("user_posts")
//                .whereField("locationRef", isEqualTo: locationRef)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("Error getting posts for rating update: \(error.localizedDescription)")
//                        return
//                    }
//                    
//                    var totalRating = 0
//                    var count = 0
//                    
//                    snapshot?.documents.forEach { doc in
//                        if let rating = doc.data()["rating"] as? Int {
//                            totalRating += rating
//                            count += 1
//                        }
//                    }
//                    
//                    if count > 0 {
//                        let newAverageRating = Double(totalRating) / Double(count)
//                        locationRef.updateData(["average_rating": newAverageRating])
//                    } else {
//                        locationRef.updateData(["average_rating": 0])
//                    }
//                }
//        }
//    
//    func formatDate(_ date: Date) -> String {
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .abbreviated
//        return formatter.localizedString(for: date, relativeTo: Date())
//    }
//}












import SwiftUI
import FirebaseFirestore
import Firebase

class PostCardViewModel: ObservableObject {
    @Published var currentImageIndex = 0
    @Published var comments: [Comment] = []
    @Published var commentCount: Int = 0
    @Published var likesCount: Int = 0
    @Published var likedByUserIds: [String] = []
    @Published var liked: Bool = false
    @Published var isCurrentUserPost: Bool = false
    @Published var showDeleteConfirmation = false
    @Published var blockedUserIds: Set<String> = []
    @Published var blockedByIds: Set<String> = []
    
    let post: Post
    private let userManager: UserManager
    
    init(post: Post) {
        self.post = post
        self.userManager = UserManager()
        setupInitialState()
    }
    
    private func setupInitialState() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isCurrentUserPost = post.uid == currentUserId
    }
    
    func setupListeners() {
        setupBlockedUsersListener()
        fetchBlockedByUsers()
        fetchLikes()
        fetchComments()
    }
    
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
    
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
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
