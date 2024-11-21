import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI
import MapKit
import CoreLocation

// extending comment

extension Comment {
    func formattedTimestamp() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full // Options: .full, .short, .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

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
    @State private var selectedEmoji: String? = nil // Variable to store selected emoji
    @State private var showEmojiPicker = false  // Toggle to show/hide the emoji picker
 
   

        // Custom initializer to accept values passed from `PostCard`
        init(post: Post, likesCount: Int, liked: Bool) {
            self._post = State(initialValue: post)
            self._likesCount = State(initialValue: likesCount)
            self._liked = State(initialValue: liked)
        }
    
      private var emojiPicker: some View {
          let emojis: [String] = ["😀", "😂", "😍", "😎", "😢", "😡", "🥳", "🤔", "🤗", "🤩", "🙄", "😳"]
          
          return VStack {
              LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                  ForEach(emojis, id: \.self) { emoji in
                      Button(action: {
                    // Add selected emoji to commentText
                            commentText += emoji
                            showEmojiPicker = false  // Hide the picker after selecting an emoji
                    }) {
                            Text(emoji)
                                    .font(.largeTitle)
                                     }
                                 }
                             }
              .padding()
              .background(Color.white)
              .cornerRadius(10)
              .shadow(radius: 5)
          }
      }
  
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
            return "\(minutes) min ago"
        } else if timeInterval < secondsInDay {
            let hours = Int(timeInterval / secondsInHour)
            return "\(hours) hr ago"
        } else if timeInterval < secondsInWeek {
            let days = Int(timeInterval / secondsInDay)
            return "\(days) day(s) ago"
        } else {
            let weeks = Int(timeInterval / secondsInWeek)
            return "\(weeks) week(s) ago"
        }
        
    }

   
    private var timeAgo: String {
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


    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
           
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
                // Display the time ago
                Text(timeAgo)  // Show the "time ago" string
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
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
            
            /*
            // Display the time ago
            Text(timeAgo)  // Show the "time ago" string
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.horizontal)*/
            
            // Location, Rating, Likes
            HStack {
                Button(action: {
                    openInMaps()
                }) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                        Text("\(post.locationAddress)")
                            .font(.system(size: 16))
                            .foregroundColor(.blue) // Make it look clickable
                            .underline() // Optional: add underline to make it look more like a link
                    }
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
                                        Text(comment.timestampString ?? "Unknown time")
                                                   .font(.subheadline)
                                                   .foregroundColor(.gray)
                                    }
                                    
                                    
                                    Spacer()
                                    
                                    // Like button for each comment
                                           HStack(spacing: 4) {
                                               Image(systemName: comment.likedByCurrentUser ? "heart.fill" : "heart")
                                                   .foregroundColor(comment.likedByCurrentUser ? .red : .gray)
                                                   .onTapGesture {
                                                       toggleLikeForComment(comment)  // Toggle like for comment
                                                   }
                                               
                                               Text("\(comment.likeCount)")
                                                   .foregroundColor(.gray)
                                           }
                                           
                                    
                                    // Delete button
                                    if comment.userID == FirebaseManager.shared.auth.currentUser?.uid {
                                        Button(action: { deleteComment(comment) }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                    }
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
                   
                    
                            .padding(.leading, 5)
                    
                    Button(action: {
                        withAnimation {
                            showEmojiPicker.toggle()
                        }
                        }) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 24))
                                .foregroundColor(Color(.darkGray))
                    }
                                      
                    
                    Button(action: addComment) {
                        Text("Post")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        // Emoji Picker Sheet
                        // Emoji Picker Overlay
                        
                        
                    }
                    .padding(.leading, 5)
                    
                }
                .padding(.horizontal)
                
                // Conditional rendering of the emoji picker
                if showEmojiPicker {
                    emojiPicker  // Display the emoji picker when `showEmojiPicker` is true
                        .transition(.move(edge: .bottom))  // Add a transition for a smooth animation
                            }
                        }
                
            
            
            .padding(.bottom, 20)
            .onAppear {
                fetchCurrentUserProfile() // Fetch profile image on view load
                fetchLikes() // Fetch likes on view load
            }
            
        }
        .padding(.bottom, 20)
        .navigationTitle("Post View")
        .navigationBarBackButtonHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchComments() // Fetch comments when the view appears
        }
    }
    
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
                mapItem.name = post.locationAddress
                
                // Open in Maps
                mapItem.openInMaps(launchOptions: nil)
            }
        }
    }

    
    private func toggleLikeForComment(_ comment: Comment) {
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
                      userManager.sendCommentLikeNotification(commenterId: comment.userID, post: post, commentMessage: comment.text) { success, error in
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


    private func addComment() {
        guard !commentText.isEmpty else { return } // Avoid posting empty comments
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let postId = post.id
        
        let commentData: [String: Any] = [
            "pid": postId,
            "uid": userID,
            "comment": commentText,
            "timestamp": FieldValue.serverTimestamp(),
            "likeCount": 0,
            "likedByCurrentUser": false // Add this field so that you can track if the comment is liked by the current user
        ]
        
        let db = FirebaseManager.shared.firestore
        db.collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                print("Comment successfully added!")
                
                // Immediately add the comment to the local array with the actual document ID
                let newComment = Comment(id: db.collection("comments").document().documentID, // Use the actual Firestore document ID
                                         postID: postId,
                                         userID: userID,
                                         text: commentText,
                                         timestamp: Date(),
                                         likeCount: 0,
                                         likedByCurrentUser: false)
                
                self.comments.insert(newComment, at: 0) // Insert at the beginning for descending order
                
                commentText = "" // Clear the input field after posting
                
                // Optionally, fetch comments again (though adding it to local state as above might be sufficient)
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

    private func updateCommentUI() {
          
           for comment in self.comments {
               
               if let index = self.comments.firstIndex(where: { $0.id == comment.id }) {
                   let isLiked = comment.likedByCurrentUser
                   
                   updateLikeButtonAppearance(for: comment, isLiked: isLiked)
               }
           }
       }

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
                           // Initialize the Comment object
                           var comment = Comment(document: document)
                           
                           // Fetch the 'likedByCurrentUser' dictionary to see if the current user liked the comment
                           guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return comment }
                           
                           // Format the timestamp and update the comment object
                           if let timestamp = document.data()["timestamp"] as? Timestamp {
                               let timestampDate = timestamp.dateValue()
                               comment?.timestampString = formatCommentTimestamp(timestampDate) // Store the formatted timestamp
                           }


                           
                           // Fetch the likedByCurrentUser field
                           if let likedByCurrentUser = document.data()["likedByCurrentUser"] as? [String: Bool],
                              let isLikedByCurrentUser = likedByCurrentUser[currentUserId] {
                               comment?.likedByCurrentUser = isLikedByCurrentUser
                           } else {
                               comment?.likedByCurrentUser = false
                           }
                           
                           // Return the comment object
                           return comment
                       } ?? []

                       // Once we have all the comments with the 'likedByCurrentUser' information, we can update the UI accordingly
                       self.updateCommentUI()
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
    
    private func deleteComment(_ comment: Comment) {
          let db = FirebaseManager.shared.firestore
          db.collection("comments").document(comment.id).delete { error in
              if let error = error {
                  print("Error deleting comment: \(error)")
              } else {
                  // Remove comment from local array
                  if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                      comments.remove(at: index)
                  }
                  print("Comment successfully deleted!")
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

    
    


