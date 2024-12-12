//
//  IndividualPostViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit

class PostViewModel: ObservableObject {

    @Published var comments: [Comment] = [] // To store the comments for the current post id
    @Published var commentText: String = "" // To add a new comment
    @Published var userData: [String: (username: String, profileImageUrl: String?)] = [:]   // Cache for user data
    @Published var currentUserProfileImageUrl: String?  // To store the current user's profile image URL
    @Published var likesCount: Int = 0  // Track the like count
    @Published var liked: Bool = false  // Track if the current user has liked the post
    @Published var post: Post
    @Published var showEmojiPicker = false  // Toggle to show/hide the emoji picker
    @Published var blockedUserIds: Set<String> = [] // Track the list blocked user ids
    @Published var blockedByIds: Set<String> = []   // Track the list of users that blocked current logged in user ids

    private let userManager: UserManager

    init(post: Post, likesCount: Int, liked: Bool) {
        self.post = post
        self.likesCount = likesCount
        self.liked = liked
        self.userManager = UserManager()
    }

    // MARK: - Initialization Logic
    func fetchInitialData() {
        fetchCurrentUserProfile()
        setupBlockedUsersListener()
        fetchBlockedByUsers()
        fetchLikes()
        fetchComments()
    }

    // To format the comment timestamp in terms of "Just Now", "min", "hr ago" , "d ago" and "wk ago"
    private func formatCommentTimestamp(_ timestamp: Date) -> String {
        let currentTime = Date()
        let timeInterval = currentTime.timeIntervalSince(timestamp)
        
        let secondsInMinute: TimeInterval = 60
        let secondsInHour: TimeInterval = 3600
        let secondsInDay: TimeInterval = 86400
        let secondsInWeek: TimeInterval = 604800
        
        if timeInterval < secondsInMinute {
            return "Just now"
        } else if timeInterval < secondsInHour {
            let minutes = Int(timeInterval / secondsInMinute)
            return "\(minutes) min"
        } else if timeInterval < secondsInDay {
            let hours = Int(timeInterval / secondsInHour)
            return "\(hours) hr ago"
        } else if timeInterval < secondsInWeek {
            let days = Int(timeInterval / secondsInDay)
            return "\(days) d ago"
        } else {
            let weeks = Int(timeInterval / secondsInWeek)
            return "\(weeks) wk ago"
        }
    }


    // Function to calculate the time since the post was posted
    var timeAgo: String {
           let calendar = Calendar.current
           let now = Date()

           // Ensure post.timestamp is a Firestore Timestamp and convert it to Date
           let postDate: Date
           if let timestamp = post.timestamp as? Timestamp {
               postDate = timestamp.dateValue() // Convert Firestore Timestamp to Date
           } else if let date = post.timestamp as? Date {
               postDate = date // If it's already a Date object
           } else {
               postDate = now // Fallback in case timestamp is nil or of an unexpected type
           }
           
           // Calculate the time difference in various units
           let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: postDate, to: now)
           
           if let year = components.year, year > 0 {
               return "\(year) yr\(year > 1 ? "s" : "") ago"
           } else if let month = components.month, month > 0 {
               return "\(month) mo ago"
           } else if let week = components.weekOfYear, week > 0 {
               return "\(week) wk\(week > 1 ? "s" : "") ago"
           } else if let day = components.day, day > 0 {
               return "\(day)d ago"
           } else if let hour = components.hour, hour > 0 {
               return "\(hour) hr\(hour > 1 ? "s" : "") ago"
           } else if let minute = components.minute, minute > 0 {
               return "\(minute) min\(minute > 1 ? "s" : "") ago"
           } else {
               return "Just now"
           }
       }
    
    // Function to open the location tagged in the post in maps
    private func openInMaps() {
        // First, get the location reference
        post.locationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching location: \(error)")
                return
            }
            
            if let data = snapshot?.data(),
               let coordinates = data["location_coordinates"] as? [Double],
               coordinates.count == 2 {
                
                let latitude = coordinates[0]
                let longitude = coordinates[1]
                
                // Create a map item from the coordinates
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let placemark = MKPlacemark(coordinate: coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = self.post.locationAddress
                
                // Open in Maps
                mapItem.openInMaps(launchOptions: nil)
            }
        }
    }
    
    // MARK: - Like Management
    // Function to add or delete the like count on the post when clicked by the user
    func toggleLike() {
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        if liked {
            // Unlike logic
            FirebaseManager.shared.firestore.collection("likes")
                .whereField("postId", isEqualTo: post.id)
                .whereField("userId", isEqualTo: userID)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error unliking post: \(error)")
                    } else if let document = snapshot?.documents.first {
                        document.reference.delete()
                        self.likesCount -= 1
                        self.liked = false
                    }
                }
        } else {
            // Like logic
            let likeData: [String: Any] = [
                "postId": post.id,
                "userId": userID,
                "timestamp": FieldValue.serverTimestamp()
            ]
            FirebaseManager.shared.firestore.collection("likes")
                .addDocument(data: likeData) { error in
                    if let error = error {
                        print("Error liking post: \(error)")
                    } else {
                        self.likesCount += 1
                        self.liked = true
                    }
                }
        }
    }
    
    // Function to like comments and keep count of number of likes on each comment
        func toggleLikeForComment(_ comment: Comment) {
              guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
              
              let db = FirebaseManager.shared.firestore
              let commentRef = db.collection("comments").document(comment.id)
              
              // Fetch current comment data from Firestore
              commentRef.getDocument { documentSnapshot, error in
                  if let error = error {
                      print("Failed to fetch comment data: \(error)")
                      return
                  }
                  
                  guard let documentSnapshot = documentSnapshot, let commentData = documentSnapshot.data() else {
                      print("Document does not exist or data is missing")
                      return
                  }
                  
                  // Retrieve the current like count and likedByCurrentUser dictionary
                  var currentLikeCount = commentData["likeCount"] as? Int ?? 0
                  var likedByCurrentUser = commentData["likedByCurrentUser"] as? [String: Bool] ?? [:]
                  
                  // Check if the current user has already liked the comment
                  if likedByCurrentUser[currentUserId] == true {
                      // User has liked the comment, so we'll remove their like
                      currentLikeCount -= 1
                      likedByCurrentUser[currentUserId] = nil // Remove the user from the likedByCurrentUser dictionary
                  } else {
                      // User hasn't liked the comment, so we'll add their like
                      currentLikeCount += 1
                      likedByCurrentUser[currentUserId] = true // Add the user to the likedByCurrentUser dictionary
                  }
                  
                  // Update the comment's data in Firestore
                  commentRef.updateData([
                      "likeCount": currentLikeCount,
                      "likedByCurrentUser": likedByCurrentUser
                  ]) { error in
                      if let error = error {
                          print("Error updating like data: \(error)")
                      } else {
                          // After successfully updating the data, update the local state (UI)
                          if let index = self.comments.firstIndex(where: { $0.id == comment.id }) {
                              self.comments[index].likeCount = currentLikeCount
                              self.comments[index].likedByCurrentUser = likedByCurrentUser[currentUserId] ?? false
                          }
                          
                          // Optionally, send a notification when the comment is liked or unliked
                          self.userManager.sendCommentLikeNotification(commenterId: comment.userID, post: self.post, commentMessage: comment.text) { success, error in
                              if success {
                                  print("Comment-like notification sent successfully!")
                              } else {
                                  if let error = error {
                                      print("Failed to send Comment-like notification: \(error.localizedDescription)")
                                  } else {
                                      print("Failed to send Comment-like notification for an unknown reason.")
                                  }
                              }
                          }
                      }
                  }
              }
          }

    // MARK: - Comments Management
    
    // Function to add a new comment to the post
    func addComment() {
        guard !commentText.isEmpty else { return }
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let commentData: [String: Any] = [
            "pid": post.id,
            "uid": userID,
            "comment": commentText,
            "timestamp": FieldValue.serverTimestamp(),
            "likeCount": 0,
            "likedByCurrentUser": false
        ]
        let db = FirebaseManager.shared.firestore
        db.collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                self.commentText = ""
                self.fetchComments()
            }
        }
        
        // Send notification
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

    // Function to change the comment view when liked
        private func updateCommentUI() {
              
               for comment in self.comments {
                   
                   if let index = self.comments.firstIndex(where: { $0.id == comment.id }) {
                       let isLiked = comment.likedByCurrentUser
                       
                       updateLikeButtonAppearance(for: comment, isLiked: isLiked)
                   }
               }
           }
    
    // Function to delete a comment added by the current user in session
    func deleteComment(_ comment: Comment) {
        FirebaseManager.shared.firestore.collection("comments").document(comment.id).delete { error in
            if let error = error {
                print("Error deleting comment: \(error)")
            } else {
                self.comments.removeAll { $0.id == comment.id }
            }
        }
    }
    
    // Function to change the like heart colour to red from default when liked
     private func updateLikeButtonAppearance(for comment: Comment, isLiked: Bool) {
           
            
            let likeButton = getLikeButton(for: comment) // A method to get the button or image view for the specific comment
            
            if isLiked {
                likeButton.setImage(UIImage(named: "red_heart"), for: .normal)
            } else {
                likeButton.setImage(UIImage(named: "default_heart"), for: .normal)
            }
        }

   
    private func getLikeButton(for comment: Comment) -> UIButton {
            
        return UIButton()
    }

    // MARK: - User and Block Data
    // Fetch current user profile data
    private func fetchCurrentUserProfile() {
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error fetching current user profile: \(error)")
            } else if let document = document, document.exists,
                      let data = document.data(),
                      let profileImageUrl = data["profileImageUrl"] as? String {
                self.currentUserProfileImageUrl = profileImageUrl
            }
        }
    }

    // Function to get the list of blocked user ids
    private func setupBlockedUsersListener() {
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("blocks").document(userID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching blocked users: \(error)")
            } else if let document = documentSnapshot, document.exists {
                let blockedUserIds = document.data()?["blockedUserIds"] as? [String] ?? []
                self.blockedUserIds = Set(blockedUserIds)
            }
        }
    }

    // Function to get the list of users that blocked the current loged in user
    private func fetchBlockedByUsers() {
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("blocks").document(userID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching blockedBy users: \(error)")
            } else if let document = documentSnapshot, document.exists {
                let blockedByUserIds = document.data()?["blockedByIds"] as? [String] ?? []
                self.blockedByIds = Set(blockedByUserIds)
            }
        }
    }

    
    // Function to fetch comments of non-blocked users
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
                
                // Create a temporary array to hold comments while we fetch user data
                var newComments: [Comment] = []
                
                let group = DispatchGroup()
                
                for document in snapshot?.documents ?? [] {
                    group.enter()
                    
                    // Initialize the comment
                    if var comment = Comment(document: document) {
                        // Format timestamp
                        if let timestamp = document.data()["timestamp"] as? Timestamp {
                            let timestampDate = timestamp.dateValue()
                            comment.timestampString = self.formatCommentTimestamp(timestampDate)
                        }
                        
                        // Handle liked status
                        if let currentUserId = FirebaseManager.shared.auth.currentUser?.uid,
                           let likedByCurrentUser = document.data()["likedByCurrentUser"] as? [String: Bool] {
                            comment.likedByCurrentUser = likedByCurrentUser[currentUserId] ?? false
                        }
                        
                        // Filter comments by blocked users
                        if (!self.blockedUserIds.contains(comment.userID) && !self.blockedByIds.contains(comment.userID)) {
                            // Fetch user data for this comment'
                            self.fetchUserData(for: comment.userID) { username, profileImageUrl in
                                // Store user data in the cache
                                self.userData[comment.userID] = (username, profileImageUrl)
                                newComments.append(comment)
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
                
                // When all user data is fetched
                group.notify(queue: .main) {
                    self.comments = newComments.sorted { $0.timestamp > $1.timestamp }
                    self.updateCommentUI()
                }
            }
    }
    
    // Function to fetch user data
    private func fetchUserData(for userID: String, completion: @escaping (String, String?) -> Void) {
        // First check the cache
        if let cachedData = userData[userID] {
            completion(cachedData.username, cachedData.profileImageUrl)
            return
        }
        
        // If not in cache, fetch from Firestore
        let db = FirebaseManager.shared.firestore
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                completion("Unknown", nil)
                return
            }
            
            if let document = document,
               document.exists,
               let data = document.data() {
                let username = data["username"] as? String ?? "Unknown"
                let profileImageUrl = data["profileImageUrl"] as? String
                
                // Store in cache
                self.userData[userID] = (username, profileImageUrl)
                
                // Return the data
                completion(username, profileImageUrl)
            } else {
                print("No user document found for ID: \(userID)")
                completion("Unknown", nil)
            }
        }
    }

    // Fetch Likes
    private func fetchLikes() {
        FirebaseManager.shared.firestore.collection("likes")
            .whereField("postId", isEqualTo: post.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching likes: \(error)")
                } else {
                    self.likesCount = snapshot?.documents.count ?? 0
                    self.liked = snapshot?.documents.contains(where: {
                        $0.data()["userId"] as? String == FirebaseManager.shared.auth.currentUser?.uid
                    }) ?? false
                }
            }
    }
}
