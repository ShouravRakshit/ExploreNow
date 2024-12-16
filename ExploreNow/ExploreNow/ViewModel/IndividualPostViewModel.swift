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

class IndividualPostViewModel: ObservableObject {

    @Published var comments: [Comment] = [] // To store the comments for the current post id
    // This property holds an array of `Comment` objects, representing all comments for the current post.
    // It's marked as `@Published` so that any changes trigger a UI update in SwiftUI views that observe this variable.

    @Published var commentText: String = "" // To add a new comment
    // This property holds the text input for adding a new comment. It's initialized as an empty string and is bound to a text field.
    @Published var userData: [String: (username: String, profileImageUrl: String?)] = [:]    // Cache for user data
        // This dictionary stores user data where the key is the user ID, and the value is a tuple containing the user's username and profile image URL.
        // It serves as a cache for user-related information to avoid fetching it repeatedly.
    @Published var currentUserProfileImageUrl: String?  // To store the current user's profile image URL
    // This optional property holds the profile image URL of the current user. It is used to display the user's image in the UI.
    @Published var likesCount: Int = 0   // Track the like count
    // This property tracks the number of likes for the current post. It is initialized to 0 and can be updated when the like count changes.
    @Published var liked: Bool = false // Track if the current user has liked the post
    // This property tracks whether the current user has liked the post. It's a boolean value that gets updated based on user interaction.

    @Published var post: Post
    // This property holds the `Post` object representing the current post. It is used throughout the class to manage post-related data.
    @Published var showEmojiPicker = false // Toggle to show/hide the emoji picker
    // This property is a boolean flag to control whether the emoji picker is visible or not in the UI. It is toggled when the use
    @Published var blockedUserIds: Set<String> = [] // Track the list blocked user ids
    // This `Set` stores the IDs of users that the current user has blocked. Using a set ensures uniqueness and fast lookups.
    @Published var blockedByIds: Set<String> = []    // Track the list of users that blocked current logged in user ids
    // This `Set` stores the IDs of users who have blocked the current user. This helps to determine the users who cannot interact with the current user.


    private let userManager: UserManager
    // This is an instance of `UserManager`, likely responsible for handling user-related operations such as fetching user data, managing authentication, etc.


    init(post: Post, likesCount: Int, liked: Bool) {
        self.post = post
        // Initializes the `post` property with the provided `Post` object.
        self.likesCount = likesCount
        // Initializes the `likesCount` with the provided value representing the number of likes for the post.
        self.liked = liked
        // Initializes the `liked` property with the provided boolean value to indicate if the current user has liked the post.
        self.userManager = UserManager()
        // Initializes the `userManager` to handle user-related functionalities.
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
        let currentTime = Date()                        // Get the current date and time
        let timeInterval = currentTime.timeIntervalSince(timestamp)     // Calculate the time difference between current time and comment timestamp
        
        // Define constants for time intervals in seconds
        let secondsInMinute: TimeInterval = 60           // 1 minute in seconds
        let secondsInHour: TimeInterval = 3600          // 1 hour in seconds
        let secondsInDay: TimeInterval = 86400          // 1 day in seconds
        let secondsInWeek: TimeInterval = 604800         // 1 week in seconds
        
        // Check the time interval and return the appropriate formatted string
        if timeInterval < secondsInMinute {
            return "Just now"           // If the comment was posted less than a minute ago, return "Just now"
        } else if timeInterval < secondsInHour {
            let minutes = Int(timeInterval / secondsInMinute)       // Calculate the number of minutes
            return "\(minutes) min"             // Return the formatted string for minutes
        } else if timeInterval < secondsInDay {
            let hours = Int(timeInterval / secondsInHour)       // Calculate the number of hours
            return "\(hours) hr ago"                // Calculate the number of hours
        } else if timeInterval < secondsInWeek {
            let days = Int(timeInterval / secondsInDay)              // Calculate the number of days
            return "\(days) d ago"                      // Return the formatted string for days
        } else {
            let weeks = Int(timeInterval / secondsInWeek)           // Calculate the number of weeks
            return "\(weeks) wk ago"            // Return the formatted string for weeks
        }
    }


    // Function to calculate the time since the post was posted
    var timeAgo: String {
           let calendar = Calendar.current          // Get the current calendar for date components calculation

           let now = Date()      // Get the current date and time

        // Ensure post.timestamp is a Firestore Timestamp and convert it to Date
           let postDate: Date
           if let timestamp = post.timestamp as? Timestamp {
               postDate = timestamp.dateValue() // Convert Firestore Timestamp to Date
           } else if let date = post.timestamp as? Date {
               postDate = date // If it's already a Date object, use it
           } else {
               postDate = now // Fallback to current date if timestamp is nil or of an unexpected type
           }
           
        // Calculate the time difference in various units (minutes, hours, days, weeks, months, years)
           let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: postDate, to: now)
        // Check the components and return the appropriate formatted string
           if let year = components.year, year > 0 {
               return "\(year) yr\(year > 1 ? "s" : "") ago"         // Return years if available
           } else if let month = components.month, month > 0 {
               return "\(month) mo ago"          // Return months if available
           } else if let week = components.weekOfYear, week > 0 {
               return "\(week) wk\(week > 1 ? "s" : "") ago"        // Return weeks if available
           } else if let day = components.day, day > 0 {
               return "\(day)d ago"             // Return days if available
           } else if let hour = components.hour, hour > 0 {
               return "\(hour) hr\(hour > 1 ? "s" : "") ago"        // Return hours if available
           } else if let minute = components.minute, minute > 0 {
               return "\(minute) min\(minute > 1 ? "s" : "") ago"       // Return minutes if available
           } else {
               return "Just now"                     // Default to "Just now" if no time difference is significant
           }
       }
    
    // Function to open the location tagged in the post in maps
    private func openInMaps() {
        // First, get the location reference from Firestore
        post.locationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching location: \(error)")  // Handle error if location fetch fails
                return
            }
            
            // If the location data is successfully fetched, extract coordinates
            if let data = snapshot?.data(),
               let coordinates = data["location_coordinates"] as? [Double],
               coordinates.count == 2 {
                
                let latitude = coordinates[0]       // Extract latitude from coordinates
                let longitude = coordinates[1]      // Extract longitude from coordinates
                
                // Create a CLLocationCoordinate2D object using the extracted coordinates
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                // Create a MKPlacemark with the location coordinates
                let placemark = MKPlacemark(coordinate: coordinate)
                // Create an MKMapItem using the placemark and set its name to the location address
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = self.post.locationAddress
                
                // Open the location in Apple Maps using the created map item
                mapItem.openInMaps(launchOptions: nil)
            }
        }
    }
    
    // MARK: - Like Management
    // Function to add or delete the like count on the post when clicked by the user
    func toggleLike() {
        // Ensure the user is authenticated by getting the current user ID
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        if liked {
            // Unlike logic: If the post is already liked by the user, we remove the like
            FirebaseManager.shared.firestore.collection("likes")
                .whereField("postId", isEqualTo: post.id)        // Search for the like based on post ID
                .whereField("userId", isEqualTo: userID)        // Search for the like based on user ID
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error unliking post: \(error)")      // Handle error if there's an issue
                    } else if let document = snapshot?.documents.first {
                        // If a like document is found, delete it
                        document.reference.delete()
                        self.likesCount -= 1        // Decrease the like count
                        self.liked = false          // Update the liked status to false
                    }
                }
        } else {
            // Like logic: If the post is not liked, we add a like
            let likeData: [String: Any] = [
                "postId": post.id,
                "userId": userID,
                "timestamp": FieldValue.serverTimestamp()         // Add timestamp when the like is created
            ]
            FirebaseManager.shared.firestore.collection("likes")
                .addDocument(data: likeData) { error in
                    if let error = error {
                        print("Error liking post: \(error)")        // Handle error if there's an issue
                    } else {
                        self.likesCount += 1            // Increase the like count
                        self.liked = true               // Update the liked status to true
                    }
                }
        }
    }
    
    // Function to like comments and keep count of number of likes on each comment
        func toggleLikeForComment(_ comment: Comment) {
            // Ensure the user is authenticated by getting the current user ID
              guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
              
              let db = FirebaseManager.shared.firestore
              let commentRef = db.collection("comments").document(comment.id)    // Reference to the comment document in Firestore
              
              // Fetch current comment data from Firestore
              commentRef.getDocument { documentSnapshot, error in
                  if let error = error {
                      print("Failed to fetch comment data: \(error)")   // Handle error if there's an issue fetching comment data
                      return
                  }
                  
                  guard let documentSnapshot = documentSnapshot, let commentData = documentSnapshot.data() else {
                      print("Document does not exist or data is missing")    // Handle missing data or document
                      return
                  }
                  
                  // Retrieve the current like count and likedByCurrentUser dictionary
                  var currentLikeCount = commentData["likeCount"] as? Int ?? 0  // Default to 0 if 'likeCount' is not available
                  var likedByCurrentUser = commentData["likedByCurrentUser"] as? [String: Bool] ?? [:]      // Default to an empty dictionary if 'likedByCurrentUser' is missing
                  
                  // Check if the current user has already liked the comment
                  if likedByCurrentUser[currentUserId] == true {
                      // User has liked the comment, so we'll remove their like
                      currentLikeCount -= 1
                      likedByCurrentUser[currentUserId] = nil // Remove the user from the likedByCurrentUser dictionary
                  } else {
                      // User hasn't liked the comment, so we'll add their like
                      currentLikeCount += 1      // Increase the like count
                      likedByCurrentUser[currentUserId] = true // Add the user to the likedByCurrentUser dictionary
                  }
                  
                  // Update the comment's data in Firestore
                  commentRef.updateData([                // Calls Firestore to update the document data
                      "likeCount": currentLikeCount,        // Update the like count for the comment
                      "likedByCurrentUser": likedByCurrentUser      // Update the dictionary of users who liked the comment
                  ]) { error in         // Completion handler to handle success or failure after Firestore update
                      if let error = error {    // Check if there was an error during the update
                          print("Error updating like data: \(error)")   // Print error message if the update fails
                      } else {
                          // After successfully updating the data, update the local state (UI)
                          if let index = self.comments.firstIndex(where: { $0.id == comment.id }) {
                              // Find the index of the updated comment in the local state
                              self.comments[index].likeCount = currentLikeCount
                              // Update the like count in the local state
                              self.comments[index].likedByCurrentUser = likedByCurrentUser[currentUserId] ?? false
                              // Update the 'likedByCurrentUser' status in the local state
                          }
                          
                          // Optionally, send a notification when the comment is liked or unliked
                          self.userManager.sendCommentLikeNotification(
                            // Calls a function from userManager to send a notification about the like/unlike action on the comment
                            commenterId: comment.userID,    // Passes the user ID of the person who posted the comment (comment.userID) to notify the commenter
                            post: self.post,        // Passes the post object to include in the notification (e.g., the post that the comment belongs to)
                            commentMessage: comment.text    // Passes the text of the comment to include in the notification message
                          )    { success, error in  // Completion handler to check if the notification was sent successfully or if there was an error
                              if success {  // If the notification was sent successfully
                                  print("Comment-like notification sent successfully!")  // Print a success message
                              } else {
                                  if let error = error {
                                      // If there was an error while sending the notification
                                      print("Failed to send Comment-like notification: \(error.localizedDescription)")  // Print the error message if an error occurred
                                  } else {
                                      print("Failed to send Comment-like notification for an unknown reason.")   // Print a generic error message if no specific error was found
                                  }
                              }
                          }
                      }
                  }
              }
          }

    // MARK: - Comments Management
    
    // Function to add a new comment to the post
    func addComment() {                 // Defines the function to add a new comment
        guard !commentText.isEmpty else { return }       // Checks if the comment text is not empty. If empty, exit the function
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return } // Retrieves the current user's ID from Firebase. If the user is not logged in, exit the function
        let commentData: [String: Any] = [      // Creates a dictionary to hold the comment's data
            "pid": post.id,         // The post ID that the comment is attached to
            "uid": userID,          // The user ID of the person who is posting the comment
            "comment": commentText,     // The content of the comment itself

            "timestamp": FieldValue.serverTimestamp(),      // The timestamp when the comment is posted, using Firebase's server timestamp
            "likeCount": 0,     // Initializes the like count for the comment to 0
            "likedByCurrentUser": false     // Sets whether the current user has liked the comment (initially false)
        ]
        let db = FirebaseManager.shared.firestore       // References the Firestore database instance
        db.collection("comments").addDocument(data: commentData) { error in // Adds the new comment to the "comments" collection in Firestore
            if let error = error {      // If there was an error while adding the comment
                print("Error adding comment: \(error)")     // Prints the error message to the console
            } else {
                self.commentText = ""           // Clears the comment input field after successful comment submission
                self.fetchComments()             // Fetches the updated list of comments for the post
            }
        }
        
        // Send notification
             userManager.sendCommentNotification(commenterId: userManager.currentUser?.uid ?? "", post: post, commentMessage: commentText) { success, error in
                 if success {       // Checks if the notification was sent successfully
                     print("Comment notification sent successfully!")       // Logs a success message if the notification was sent without errors

                 } else {
                     if let error = error {         // Checks if there was an error while sending the notification
                         print("Failed to send Comment notification: \(error.localizedDescription)")        // Logs the error message if there was an issue sending the notification
                     } else {
                         print("Failed to send Comment notification for an unknown reason.") // Logs a fallback error message if no specific error was provided
                     }
                 }
             }
    }

    // Function to change the comment view when liked
        private func updateCommentUI() {
            // Iterates over each comment in the list of comments
               for comment in self.comments {
                   // Finds the index of the comment in the list based on its unique ID
                   if let index = self.comments.firstIndex(where: { $0.id == comment.id }) {
                       // Checks if the current user has liked the comment
                       let isLiked = comment.likedByCurrentUser
                       // Updates the appearance of the like button based on whether the comment is liked
                       updateLikeButtonAppearance(for: comment, isLiked: isLiked)
                   }
               }
           }
    
    // Function to delete a comment added by the current user in session
    func deleteComment(_ comment: Comment) {
        // Accesses the Firestore collection of comments and deletes the comment by its unique ID
        FirebaseManager.shared.firestore.collection("comments").document(comment.id).delete { error in
            if let error = error {
                // If an error occurs during the deletion process, log the error
                print("Error deleting comment: \(error)")
            } else {
                // If deletion is successful, remove the comment from the local array
                self.comments.removeAll { $0.id == comment.id }
            }
        }
    }
    
    // Function to change the like heart colour to red from default when liked
     private func updateLikeButtonAppearance(for comment: Comment, isLiked: Bool) {
           
         // Retrieves the like button or image view associated with the specific comment
            let likeButton = getLikeButton(for: comment) // A method to get the button or image view for the specific comment
         // Changes the image of the button based on whether the comment is liked
            if isLiked {
                // If liked, set the heart image to red
                likeButton.setImage(UIImage(named: "red_heart"), for: .normal)
            } else {
                // If not liked, set the heart image to the default state
                likeButton.setImage(UIImage(named: "default_heart"), for: .normal)
            }
        }

    // Function to get the like button for a specific comment
    private func getLikeButton(for comment: Comment) -> UIButton {
        // This function currently returns a new UIButton instance.
        return UIButton()
    }

    // MARK: - User and Block Data
    // Function to fetch the current user's profile data from Firestore
    private func fetchCurrentUserProfile() {
        // Ensure the current user is authenticated and retrieve their user ID

        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        // Access Firestore to get the user's document from the "users" collection using their user ID
        FirebaseManager.shared.firestore.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                // If there’s an error fetching the document, print the error
                print("Error fetching current user profile: \(error)")
            } else if let document = document, document.exists,
                      let data = document.data(),
                      let profileImageUrl = data["profileImageUrl"] as? String {
                // If the document exists and contains data, retrieve the profile image URL
                self.currentUserProfileImageUrl = profileImageUrl
            }
        }
    }

    // Function to get the list of blocked user ids
    private func setupBlockedUsersListener() {
        // Ensure the current user is authenticated and retrieve their user ID
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        // Access Firestore to get the user's document from the "blocks" collection using their user ID
        FirebaseManager.shared.firestore.collection("blocks").document(userID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                // If there’s an error fetching the blocked users, print the error
                print("Error fetching blocked users: \(error)")
            } else if let document = documentSnapshot, document.exists {
                // If the document exists, retrieve the list of blocked user IDs from the "blockedUserIds" field
                let blockedUserIds = document.data()?["blockedUserIds"] as? [String] ?? []
                // Store the blocked user IDs in a Set for efficient lookup
                self.blockedUserIds = Set(blockedUserIds)
            }
        }
    }

    // Function to get the list of users that blocked the current logged-in user
    private func fetchBlockedByUsers() {
        // Ensure the current user is authenticated and retrieve their user ID
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        // Access Firestore to get the user's document from the "blocks" collection using their user ID
        FirebaseManager.shared.firestore.collection("blocks").document(userID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                // If there’s an error fetching the list of users that blocked the current user, print the error
                print("Error fetching blockedBy users: \(error)")
            } else if let document = documentSnapshot, document.exists {
                // If the document exists, retrieve the list of user IDs who blocked the current user from the "blockedByIds" field
                let blockedByUserIds = document.data()?["blockedByIds"] as? [String] ?? []
                // Store the user IDs of those who blocked the current user in a Set for efficient lookup
                self.blockedByIds = Set(blockedByUserIds)
            }
        }
    }

    
    // Function to fetch comments of non-blocked users
    private func fetchComments() {
        // Get a reference to the Firestore database
        let db = FirebaseManager.shared.firestore
        // Access the "comments" collection, filter by the post ID, and order the comments by timestamp in descending order
        db.collection("comments")
            .whereField("pid", isEqualTo: post.id)          // Filter by the post ID (matching comments to the current post)
            .order(by: "timestamp", descending: true)      // Order comments by timestamp in descending order (newest first)
            .getDocuments { snapshot, error in
                if let error = error {
                    // If there’s an error fetching the comments, print the error and return early
                    print("Error fetching comments: \(error)")
                    return
                }
                
                // Create a temporary array to hold comments while we fetch user data
                var newComments: [Comment] = []
                
                // Initialize a DispatchGroup to handle asynchronous fetching of user data
                let group = DispatchGroup()
               
                // Iterate over all the documents (comments) in the snapshot
                for document in snapshot?.documents ?? [] {
                    // Enter the dispatch group for each comment fetch operation
                    group.enter()
                    
                    // Initialize the comment from the document data (if valid)
                    if var comment = Comment(document: document) {
                        // Check if the comment contains a valid timestamp and format it
                        if let timestamp = document.data()["timestamp"] as? Timestamp {
                            let timestampDate = timestamp.dateValue()   // Convert the timestamp to a Date object
                            // Format the timestamp and assign the result to the comment
                            comment.timestampString = self.formatCommentTimestamp(timestampDate)
                        }
                        
                        // Handle liked status
                        if let currentUserId = FirebaseManager.shared.auth.currentUser?.uid,    // Get the current user's ID if the user is logged in
                           let likedByCurrentUser = document.data()["likedByCurrentUser"] as? [String: Bool] {  // Check if the document contains the "likedByCurrentUser" data, which is a dictionary of user IDs and their like statuses
                            comment.likedByCurrentUser = likedByCurrentUser[currentUserId] ?? false     // Check if the current user has liked the comment; if not, default to false
                        }
                        
                        // Filter comments by blocked users
                        if (!self.blockedUserIds.contains(comment.userID) && !self.blockedByIds.contains(comment.userID)) { // Ensure the comment's user is not blocked by the current user and hasn't blocked the current user
                            // Fetch user data for this comment
                            self.fetchUserData(for: comment.userID) { username, profileImageUrl in
                                // Fetch user data (username and profile image) asynchronously for the user who made the comment
                                // Store user data in the cache
                                self.userData[comment.userID] = (username, profileImageUrl) // Cache the user data (username and profile image URL) in a dictionary
                                newComments.append(comment)     // Add the comment (with user data) to the new comments array
                                group.leave()        // Mark the completion of the asynchronous operation for this comment
                            }
                        } else {
                            group.leave()    // If the comment's user is blocked, immediately leave the DispatchGroup (don't fetch user data for this comment)
                        }
                    } else {
                        group.leave()        // If the comment couldn't be initialized properly, immediately leave the DispatchGroup
                    }
                }
                
                // When all user data is fetched
                group.notify(queue: .main) {        // Once all asynchronous operations for fetching user data are finished, execute the following code on the main thread
                    self.comments = newComments.sorted { $0.timestamp > $1.timestamp }   // Sort the comments array by timestamp (newest first)
                    self.updateCommentUI()          // Update the UI with the new sorted comments and refresh the appearance of the comments (like button, etc.)
                }
            }
    }
    
    // Function to fetch user data
    private func fetchUserData(for userID: String, completion: @escaping (String, String?) -> Void) {
        // First check the cache
        if let cachedData = userData[userID] {      // Check if the user data for the given userID is already cached
            completion(cachedData.username, cachedData.profileImageUrl)     // If cached, return the cached username and profile image URL via the completion handler
            return       // Exit the function early since the data was fetched from the cache
        }
        
        // If not in cache, fetch from Firestore
        let db = FirebaseManager.shared.firestore        // Get a reference to Firestore database from FirebaseManager
        db.collection("users").document(userID).getDocument { document, error in    // Fetch the document for the user from the "users" collection by their userID
            if let error = error {       // If an error occurs while fetching the document
                print("Error fetching user data: \(error)")      // Print the error message to the console
                completion("Unknown", nil)       // Call the completion handler with default values ("Unknown" for username and nil for profile image URL)
                return          // Exit the function early due to the error
            }
            
            if let document = document,         // Check if the document is valid
               document.exists,                  // Check if the document exists in the Firestore database
               let data = document.data() {         // Extract the data from the document
                let username = data["username"] as? String ?? "Unknown" // Get the username from the data dictionary, default to "Unknown" if it's nil
                let profileImageUrl = data["profileImageUrl"] as? String    // Get the profile image URL from the data dictionary (could be nil)
                
                // Store in cache
                self.userData[userID] = (username, profileImageUrl)  // Cache the fetched user data (username and profileImageUrl) for later use
                
                // Return the data
                completion(username, profileImageUrl)   // Call the completion handler with the fetched username and profile image URL
            } else {    // If no document was found or the document data is invalid
                print("No user document found for ID: \(userID)")   // Print a message indicating that no document was found for the userID
                completion("Unknown", nil)      // Call the completion handler with default values ("Unknown" for username and nil for profile image URL)
            }
        }
    }

    // Fetch Likes
    private func fetchLikes() {
        // Access the "likes" collection from Firestore
        FirebaseManager.shared.firestore.collection("likes")
        // Filter the "likes" collection where the "postId" field matches the current post's ID
            .whereField("postId", isEqualTo: post.id)
        // Perform the query and get documents
            .getDocuments { snapshot, error in
                // If there is an error fetching the likes
                if let error = error {
                    // Print the error message to the console
                    print("Error fetching likes: \(error)")
                } else {
                    // If there is no error, calculate the number of likes
                    self.likesCount = snapshot?.documents.count ?? 0    // Set the likes count to the number of documents in the snapshot, defaulting to 0 if nil
                    // Check if the current user has liked the post by searching for their userId in the "likes" collection
                    self.liked = snapshot?.documents.contains(where: {
                        // Compare the "userId" field in the document data with the current user's ID
                        $0.data()["userId"] as? String == FirebaseManager.shared.auth.currentUser?.uid
                    }) ?? false  // If a match is found, set "liked" to true, otherwise false
                }
            }
    }
}

