import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI
import MapKit
import CoreLocation

// MARK: - Comment Extension
extension Comment {
    func formattedTimestamp() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
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
    @State private var blockedUserIds: Set<String> = []

        // Custom initializer to accept values passed from `PostCard`
        init(post: Post, likesCount: Int, liked: Bool) {
            self._post = State(initialValue: post)
            self._likesCount = State(initialValue: likesCount)
            self._liked = State(initialValue: liked)
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
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Images Section
                imageSection
                
                // Interaction Bar
                interactionBar
                    .padding(.vertical, 12)
                
                // Description Section
                if !post.description.isEmpty {
                    descriptionSection
                }
                
                Divider()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Comments Section
                commentsSection
            }
        }
        .overlay(alignment: .bottom) {
            commentInputSection
                .background(AppTheme.background)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchCurrentUserProfile()
            fetchLikes()
            setupBlockedUsersListener()
            fetchComments()
        }
    }
    
    // MARK: - UI Components
    private var profileImage: some View {
        Group {
            if let imageUrl = URL(string: post.userProfileImageUrl) {
                WebImage(url: imageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.lightPurple, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(AppTheme.secondaryText)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.lightPurple, lineWidth: 2))
            }
        }
    }
    
//    private var currentUserImage: some View {
//        if let imageUrl = URL(string: currentUserProfileImageUrl ?? "") {
//            WebImage(url: imageUrl)
//                .resizable()
//                .scaledToFill()
//                .frame(width: 32, height: 32)
//                .clipShape(Circle())
//        } else {
//            Image(systemName: "person.circle.fill")
//                .resizable()
//                .frame(width: 32, height: 32)
//                .foregroundColor(AppTheme.secondaryText)
//                .clipShape(Circle())
//        }
//    }

    
    private var headerSection: some View {
        HStack(spacing: 12) {
            profileImage  // Use the new component
            
            VStack(alignment: .leading, spacing: 2) {
                NavigationLink(destination: ProfileView(user_uid: post.uid)) {
                    Text(post.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryPurple)
                }
                
                Text(timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppTheme.background)
    }

    private var imageSection: some View {
        TabView {
            ForEach(post.imageUrls.indices, id: \.self) { index in
                Group {
                    if let imageUrl = URL(string: post.imageUrls[index]) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: CGFloat.infinity)
                            .frame(height: 400)
                            .clipped()
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: CGFloat.infinity)
                            .frame(height: 400)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 400)
    }

    private var interactionBar: some View {
        HStack(spacing: 20) {
            Button(action: { toggleLike() }) {
                HStack(spacing: 6) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(liked ? .red : AppTheme.secondaryText)
                    
                    Text("\(likesCount)")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            NavigationLink(destination: LocationPostsPage(locationRef: post.locationRef)) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                    Text(post.locationAddress)
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
                .foregroundColor(AppTheme.primaryPurple)
            }

            Spacer()
            
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= post.rating ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(index <= post.rating ? .yellow : AppTheme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var descriptionSection: some View {
        Text(post.description)
            .font(.system(size: 15))
            .foregroundColor(AppTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.background)
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(comments.count)")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            
            if comments.isEmpty {
                Text("No comments yet")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            } else {
                ForEach(comments) { comment in
                    CommentRow(comment: comment,
                             userData: userData[comment.userID],
                             onDelete: { deleteComment(comment) },
                             onLike: { toggleLikeForComment(comment) })
                }
            }
        }
        .padding(.bottom, 60) // Space for input bar
    }
    
    
    
    private var commentInputSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                Group {
                    if let imageUrl = currentUserProfileImageUrl,
                       let url = URL(string: imageUrl),
                       !imageUrl.isEmpty {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .foregroundColor(AppTheme.secondaryText)
                            .clipShape(Circle())
                    }
                }
                
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppTheme.secondaryBackground)
                    .cornerRadius(20)
                
                Button(action: { showEmojiPicker.toggle() }) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Button(action: addComment) {
                    Text("Post")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryPurple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if showEmojiPicker {
                EmojiPickerView(text: $commentText, showPicker: $showEmojiPicker)
                    .transition(.identity) // No animation

            }
        }
    }

    // MARK: - Supporting Views
    private struct CommentRow: View {
        let comment: Comment
        let userData: (username: String, profileImageUrl: String?)?
        let onDelete: () -> Void
        let onLike: () -> Void
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                // User Image
                Group {
                    if let profileUrl = userData?.profileImageUrl,
                       let url = URL(string: profileUrl),
                       !profileUrl.isEmpty {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .foregroundColor(AppTheme.secondaryText)
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(userData?.username ?? "Unknown User")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(comment.text)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(comment.timestampString ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                // Like and Delete buttons
                HStack(spacing: 12) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: comment.likedByCurrentUser ? "heart.fill" : "heart")
                                .foregroundColor(comment.likedByCurrentUser ? .red : AppTheme.secondaryText)
                            Text("\(comment.likeCount)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    if comment.userID == FirebaseManager.shared.auth.currentUser?.uid {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }


    private struct EmojiPickerView: View {
        @Binding var text: String
        @Binding var showPicker: Bool

        let emojis = [
           
            "😀", "😂", "😍", "😎", "😢", "😡", "🥳", "🤔", "🤗", "🤩", "🙄", "😳",
            "👍", "👎", "💀", "🫣", "🤯", "😴", "😇", "🥰", "😱", "🤮", "😵", "😈",
            "👻", "😜", "😬", "🤠", "🤑", "🥴", "🫡", "🫠", "😌", "😋", "🫢", "🤡",
            "😭", "😅", "😤", "🤤", "😐", "😶", "🤥", "😶‍🌫️", "😲", "😷", "🤧", "🤒",

            
            "🐶", "🐱", "🐼", "🦄", "🦉", "🦋", "🐙", "🐢", "🦥", "🦈", "🦓", "🦀",
            "🦜", "🪲", "🪸", "🐳", "🐊", "🦩", "🐉", "🦧", "🦦", "🪿", "🐇", "🐓",
            "🦅", "🪱", "🪰", "🕊️", "🐝", "🐾", "🐔",

            
            "🌸", "🌍", "🌞", "🌊", "🌵", "🌋", "🌌", "🌈", "⛰️", "🏔️", "🪵", "🍂",
            "🌿", "🌲", "🌳", "☘️", "🌾", "🌬️", "🪹", "🪷", "💐", "🪻", "🦚",

            
            "🍕", "🍩", "🍔", "🍎", "🍷", "🧋", "🍿", "🥑", "🥗", "🍓", "🍇", "🍪",
            "🍫", "🍬", "🥨", "🍟", "🌭", "🍗", "🥓", "🍣", "🍤", "🧁", "🫛",
            "🍉", "🥥", "🫖", "🍸", "🥮",

           
            "🚗", "✈️", "🚀", "🛸", "🛤️", "🏝️", "🏰", "🎢", "🗽", "🗼", "🏜️", "🏕️",
            "🏟️", "🏖️", "🚂", "🛳️", "⛵️", "🚠", "🚞", "🗺️", "🌅", "🌠", "🎇",

           
            "🎵", "🎨", "📚", "🖥️", "📱", "💡", "💰", "📅", "📸", "🔑", "📖", "🧸",
            "💣", "🧪", "🪴", "🪔", "🛍️", "🛏️", "🪩", "🖊️", "📔", "🎙️", "🎤", "🎧",
            "🪞", "🪜", "🧳", "🔨", "🛠️", "⚙️", "🪚", "🔧", "🔗", "📦",

            
            "🎮", "🎭", "🏀", "⚽️", "🏈", "🏓", "🎯", "🪁", "🏋️‍♀️", "🏇", "🏂", "🛹",
            "🏄‍♂️", "🚴‍♀️", "🧘‍♂️", "🎣", "🤹‍♀️", "🧗‍♂️", "🤼‍♂️", "🎻", "🎷",
            "🥋", "🪂", "🎽", "🏌️‍♀️",

           
            "❤️", "✨", "🌟", "⚡️", "🔥", "💧", "🎉", "🎊", "🪄", "🔮", "🪦", "☠️",
            "🛡️", "🏆", "🎲", "🃏", "🪙",  "🕹️", "📡", "🧿", "🎶"
        ]

        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                    spacing: 10
                ) {
                    
                    ForEach(emojis + Array(repeating: " ", count: (6 - emojis.count % 6) % 6), id: \.self) { emoji in
                        Button(action: {
                            if emoji != " " {
                                text += emoji
                                showPicker = false
                            }
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 40, height: 40)
                                .background(emoji == " " ? Color.clear : Color.gray.opacity(0.1))
                                .cornerRadius(5)
                        }
                        .padding(5)
                    }
                }
                .padding([.top, .horizontal])
            }
            .background(AppTheme.background)
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
                            comment.timestampString = formatCommentTimestamp(timestampDate)
                        }
                        
                        // Handle liked status
                        if let currentUserId = FirebaseManager.shared.auth.currentUser?.uid,
                           let likedByCurrentUser = document.data()["likedByCurrentUser"] as? [String: Bool] {
                            comment.likedByCurrentUser = likedByCurrentUser[currentUserId] ?? false
                        }
                        
                        // Filter comments by blocked users
                        if !blockedUserIds.contains(comment.userID) {
                            // Fetch user data for this comment'
                            fetchUserData(for: comment.userID) { username, profileImageUrl in
                                // Store user data in the cache
                                userData[comment.userID] = (username, profileImageUrl)
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
                    comments = newComments.sorted { $0.timestamp > $1.timestamp }
                    updateCommentUI()
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
                userData[userID] = (username, profileImageUrl)
                
                // Return the data
                completion(username, profileImageUrl)
            } else {
                print("No user document found for ID: \(userID)")
                completion("Unknown", nil)
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

    
    



