//
//  ProfileViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation
import Firebase
import SDWebImage

class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileUser: User? // Holds the profile being viewed (other user)
    @Published var userPosts: [Post] = [] // Array of posts by the profile user.
    @Published var isLoading = false // Indicates if data is currently being loaded.
    @Published var viewingOtherProfile = true  // Tracks whether the profile being viewed belongs to another user.
    @Published var isRequestSentToOtherUser = false // Tracks if a friend request has been sent.
    @Published var didUserSendMeRequest = false // Tracks if the other user sent a friend request.
    @Published var isFriends = false  // Tracks the friendship status with the profile user.
    @Published var isPublic  = false // Indicates if the profile is public.
    @Published var friendshipLabelText = "Add Friend..." // Label text for the friendship button.
    @Published var friendsList: [String] = [] // List of friends for the profile user.

    @Published var isBlocked: Bool = false // Indicates if the current user is blocked by the profile user.
    @Published var didBlockUser: Bool = false  // Tracks whether the current user has blocked the profile user.
    @Published var isCheckingBlockedStatus: Bool = true  // Indicates if the app is still checking the blocked status.

    @Published var selectedPost: Post? = nil // Tracks the post selected for deletion.
    
    // MARK: - Dependency Injection
    
    @Published var appState: AppState // Tracks global app state.
    @Published var userManager: UserManager // Manages user-related logic and actions.
    @Published var settingsManager: UserSettingsManager // Manages user settings and preferences.
    
    init() {
    // Initialize with default instances
    self.appState = AppState() // Default instance, replace with actual initialization if needed
    self.userManager = UserManager() // Default instance, replace as needed
    self.settingsManager = UserSettingsManager() // Default instance, replace as needed
    }
    
    // MARK: - Delete Post
    /// Deletes the selected post from the Firestore database.
    /// - Parameter completion: A closure that indicates success (true) or failure (false) of the deletion.
    func deletePost_db(completion: @escaping (Bool) -> Void) {
        // Ensure a post is selected before attempting deletion.
        guard let postId = selectedPost?.id else {
            completion(false) // Ensure a post is selected before attempting deletion.
            return
        }
        
        // Access the Firestore database.
        let db = Firestore.firestore()
        db.collection("user_posts").document(postId).delete { error in
            if let error = error {
                // Log the error if the deletion fails.
                print("Error deleting post: \(error.localizedDescription)")
                completion(false)  // Notify failure.
            } else {
                // Log success message upon successful deletion.
                print("Post successfully deleted")
                completion(true) // Notify success.
            }
        }
    }
 
        // Function to check friendship status
    func checkFriendshipStatus(user1Id: String, user2Id: String) {
        print ("Calling checkFriendshipStatus")
        
        // Initializing the state
        friendshipLabelText = "Loading..."
        isFriends = false
        isRequestSentToOtherUser = false
        didUserSendMeRequest = false
        
        // Firestore instance
        let db = Firestore.firestore()
 
        // 1. Check if they are friends by looking at the user's "friends" field
        let friendsRef = db.collection("friends")
        
        // Query for user1's friends list
        let user1FriendsQuery = friendsRef.document(user1Id).getDocument { (document, error) in
            if let error = error {
                // Handle any errors that occur while fetching the document
                print("Error checking user1's friends list: \(error)")
            } else if let document = document, document.exists {
                // Successfully retrieved the document and it exists
                // Check if "friends" field exists and contains user2Id
                if let friendsList = document.data()?["friends"] as? [String], friendsList.contains(user2Id) {
                    self.isFriends = true
                }
                else{
                    // If user2Id is not found in the friends list, log the status
                    print ("Not friends")
                }
            }
            
            // 2. Now check if a friend request has been sent with "pending" status
            let friendRequestsRef = db.collection("friendRequests")
            
            // Query for a pending request from user1 to user2
            let requestQuery1 = friendRequestsRef.whereField("senderId", isEqualTo: user1Id)
                                                .whereField("receiverId", isEqualTo: user2Id)
                                                .whereField("status", isEqualTo: "pending")
            
            // Query for a pending request from user2 to user1
            let requestQuery2 = friendRequestsRef.whereField("senderId", isEqualTo: user2Id)
                                                .whereField("receiverId", isEqualTo: user1Id)
                                                .whereField("status", isEqualTo: "pending")
            
            // Execute both requests queries
            requestQuery1.getDocuments { (snapshot1, error) in
                if let error = error {
                    // Handle any errors that occur while fetching documents
                    print("Error checking first request query: \(error)")
                } else if !snapshot1!.isEmpty {
                    // If we find any document with status "pending", a request has been sent
                    self.isRequestSentToOtherUser = true
                    self.friendshipLabelText = "Requested"
                    print ("Status: friends")
                }
                else{
                    // If no pending request is found from user1 to user2
                    print ("Did not send friend request to other user")
                }
                
                // Execute the second query (for the reverse direction)
                requestQuery2.getDocuments { (snapshot2, error) in
                    if let error = error {
                        print("Error checking second request query: \(error)")
                    } else if !snapshot2!.isEmpty {
                        // If we find any document with status "pending", a request has been sent
                        self.didUserSendMeRequest = true
                        self.friendshipLabelText = "Accept Friend"
                        print ("Status: other user sent me request")
                    }
                    else{
                        print ("Other user did not send me a request")
                    }
                    
                    // Return the results once both checks are done
                    //completion(isRequestSentToOtherUser, isFriends)
                }
            }
            if self.didBlockUser {
                // If the user has blocked the other user, set the friendship label text to "Unblock"
                self.friendshipLabelText = "Unblock"
                print ("Setting friendship label to Unblock")
                return // Exit early, no further checks are needed
            }
            
            if !self.isRequestSentToOtherUser && !self.isFriends{
                // If no friend request has been sent and they are not friends, display "Add Friend"
                self.friendshipLabelText = "Add Friend"
                print ("Setting friendship label to Add friend")
            }
            else if self.isFriends{
                // If the users are friends, display "Friends"
                self.friendshipLabelText = "Friends"
                print ("Status: friends")
            }
            else if self.isRequestSentToOtherUser{
                // If a friend request has been sent but not yet accepted, display "Requested"
                self.friendshipLabelText = "Requested"
                print ("Status: requested")
            }
        }

    }
        
        // Function to fetch user data
    func fetchUserData(user_uid: String) {
            // Determine if viewing own profile or another user's profile
            if user_uid == userManager.currentUser?.uid {
                viewingOtherProfile = false
                // No need to fetch data; currentUser is already available
                // Reset profileUser
                //self.profileUser = nil
                self.profileUser = self.userManager.currentUser
                // Fetch own friends list
                //checkFriendshipStatus(user1Id: userManager.currentUser?.uid ?? "ERROR", user2Id: user_uid)
            } else {
                viewingOtherProfile = true // Set flag to indicate the user is viewing another user's profile
                // Fetch the data of another user by creating a reference to their document in Firestore
                let userRef = FirebaseManager.shared.firestore.collection("users").document(user_uid)
                
                // Attach a snapshot listener to the user document to fetch live data updates
                userRef.addSnapshotListener { snapshot, error in
                    if let error = error {
                        // If there's an error fetching the user's data, print the error and exit
                        print("Failed to fetch profile user data:", error.localizedDescription)
                        return
                    }
                    
                    // Ensure that the snapshot contains valid data
                    guard let data = snapshot?.data() else {
                        print("No data found for profile user")  // Print an error message if no data exists
                        return // Exit early if no valid data is found
                    }
                    
                    // Switch to the main thread to perform UI updates
                    DispatchQueue.main.async {
                        // Create a User object using the fetched data and user UID
                        self.profileUser = User(data: data, uid: user_uid)
                        
                        // Fetch user settings for the profile user and check if the account is public
                        self.settingsManager.fetchUserSettings(userId: self.profileUser?.uid ?? "") { isPublic in
                            print("Is public account: \(isPublic)") // Log the account visibility status (public or private)
                            
                            // Set the `isPublic` property based on the fetched user settings
                            self.isPublic = isPublic
                        }
                        // After successfully fetching the profile user data, check the friendship status with the current user
                        self.checkFriendshipStatus(user1Id: self.userManager.currentUser?.uid ?? "ERROR", user2Id: user_uid)
                        // Posts will be fetched separately
                    }
                }
            }
        }
        
    // Function to check if the current user has blocked the profile user
    func checkBlockedStatus(user_uid: String) {
        // Safely unwrap the current user's ID from the user manager
        guard let currentUserId = userManager.currentUser?.uid else {
            // If the current user's ID is not available, set the flag to false and return
            isCheckingBlockedStatus = false
            return
        }
        
        // References to the "blocks" collection in Firestore for both the current user and the profile user
        let userBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        let profileBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(user_uid)

        // Fetch the current user's block status from the Firestore document
        userBlocksRef.getDocument { document, error in
            // If there was an error fetching the current user's blocked list, handle it
            if let error = error {
                print("Error fetching current user's blocked list: \(error.localizedDescription)") // Log the error
                self.isCheckingBlockedStatus = false // Indicate that checking has finished
                return // Exit the closure early if an error occurred
            }

            // Fetch the list of user IDs blocked by the current user from Firestore
            let currentUserBlockedList = document?.data()?["blockedUserIds"] as? [String] ?? []

            // Fetch the profile user's block status by checking the profile user's blocked list
            profileBlocksRef.getDocument { profileDocument, error in
                // If an error occurs while fetching the profile user's blocked list, handle it
                if let error = error {
                    // Print the error message to the console
                    print("Error fetching profile user's blocked list: \(error.localizedDescription)")
                    // Set the flag to indicate that the block status check is complete, even though it failed
                    self.isCheckingBlockedStatus = false
                    return // Exit early if there was an error
                }

                // If no error occurs, retrieve the list of user IDs blocked by the profile user
                let profileUserBlockedList = profileDocument?.data()?["blockedUserIds"] as? [String] ?? []

                // Check if either user has blocked the other
                if profileUserBlockedList.contains(currentUserId) {
                    // If the current user is in the profile user's blocked list, mark the status as blocked
                    self.isBlocked = true
                }
                else if currentUserBlockedList.contains(user_uid) {
                    // If the profile user is in the current user's blocked list, mark the status as blocked
                    self.didBlockUser = true
                }
                else {
                    // If neither user has blocked the other, reset the blocked status
                    self.isBlocked = false
                }

                // Set the flag indicating that the block status check is complete
                self.isCheckingBlockedStatus = false
            }
        }
    }

    // Function to fetch posts by a specific user, identified by their unique `uid`
        func fetchUserPosts(uid: String) {
            // Set the loading flag to true to indicate that the posts are being fetched
            isLoading = true
            
            // Query the "user_posts" collection in Firestore
            FirebaseManager.shared.firestore
                .collection("user_posts")
            // Filter the posts to only those where the user ID (uid) matches the specified `uid`
                .whereField("uid", isEqualTo: uid)
            // Order the posts by the timestamp in descending order, to get the most recent posts first
                .order(by: "timestamp", descending: true)
            // Add a snapshot listener to listen for updates to the collection in real time
                .addSnapshotListener { querySnapshot, error in
                    // Set the loading flag to false once the fetch operation is complete
                    self.isLoading = false
                    
                    // If an error occurs while fetching the posts, print the error and exit
                    if let error = error {
                        print("Failed to fetch user posts:", error)
                        return
                    }
                    
                    // Clear any existing posts before adding new ones
                    self.userPosts = []
                    
                    // Iterate over the documents in the query snapshot
                    querySnapshot?.documents.forEach { doc in
                        // Extract the data from the document
                        let data = doc.data()
                        // Safely extract the necessary fields from the document data
                        guard let locationRef = data["locationRef"] as? DocumentReference,
                              let description = data["description"] as? String,
                              let rating = data["rating"] as? Int,
                              let imageUrls = data["images"] as? [String],
                              let timestamp = data["timestamp"] as? Timestamp,
                              let uid = data["uid"] as? String else {
                            // If any of the fields are missing or have an incorrect type, return early and skip this document
                            return
                        }
                       
                        // Fetch location details using the reference to the location document
                        locationRef.getDocument { locationSnapshot, locationError in
                            // Check for any error while fetching the location data
                            if let locationError = locationError {
                                // If an error occurs, print the error message and exit
                                print("Error fetching location: \(locationError.localizedDescription)")
                                return
                            }
                            
                            // Safely unwrap the location data from the document snapshot
                            if let locationData = locationSnapshot?.data(),
                               let address = locationData["address"] as? String {
                
                                
                                // If location data exists and the address is successfully extracted, create a Post object
                                let post = Post(
                                    id: doc.documentID, // Post ID from the document
                                    description: description, // Description of the post
                                    rating: rating, // Rating associated with the post
                                    locationRef: locationRef, // Reference to the location document
                                    locationAddress: address, // Address fetched from the location document
                                    imageUrls: imageUrls, // List of image URLs associated with the post
                                    timestamp: timestamp.dateValue(),  // Convert timestamp to Date
                                    uid: uid,  // User ID of the post creator
                                    username: self.viewingOtherProfile ? (self.profileUser?.name ?? "") : (self.userManager.currentUser?.name ?? ""), // Username based on whether the profile is being viewed or not
                                    userProfileImageUrl: self.viewingOtherProfile ? (self.profileUser?.profileImageUrl ?? "") : (self.userManager.currentUser?.profileImageUrl ?? "") // User's profile image URL based on the profile being viewed
                                )
                                
                                // After creating the post, update the posts list on the main thread
                                DispatchQueue.main.async {
                                    // Check if the post already exists in the list (to avoid duplicates)
                                    if !self.userPosts.contains(where: { $0.id == post.id }) {
                                        // Append the new post to the list
                                        self.userPosts.append(post)
                                        // Sort the posts array by timestamp in descending order (most recent first)
                                        self.userPosts.sort { $0.timestamp > $1.timestamp }
                                    }
                                }
                            }
                        }
                    }
                }
        }
        
   
        func fetchUserFriends(userId: String, completion: @escaping ([String]?, Error?) -> Void) {
            let db = Firestore.firestore()
            
            // Reference to the user's document in the 'friends' collection
            let friendsRef = db.collection("friends").document(userId)
            
            // Fetch the document for the user
            friendsRef.getDocument { (document, error) in
                if let error = error {
                    // Handle any errors that occurred during the fetch
                    print("Error fetching friends for user \(userId): \(error.localizedDescription)")
                    completion(nil, error)
                } else if let document = document, document.exists {
                    // Document exists, extract the 'friends' field (assuming it's an array of friend IDs)
                    if let friendsList = document.data()?["friends"] as? [String] {
                        self.friendsList = friendsList
                        // Return the list of friend IDs
                        completion(friendsList, nil)
                    } else {
                        // No friends list or the 'friends' field is missing
                        print("No friends list found for user \(userId).")
                        completion([], nil) // Returning an empty list if no friends are found
                    }
                } else {
                    // The document doesn't exist (no friends found for the user)
                    print("No document found for user \(userId).")
                    completion([], nil) // Returning an empty list if no document exists
                }
            }
        }
    
        // Function to handle user sign-out from Firebase authentication
        func handleSignOut() {
            do {
                // Attempt to sign out the user using Firebase authentication
                try FirebaseManager.shared.auth.signOut()
                // If sign-out is successful, update the application's authentication state
                appState.isLoggedIn = false // Set the 'isLoggedIn' flag to false to reflect that the user is logged out
            } catch let signOutError as NSError {
                // If an error occurs during the sign-out process, catch the error and print the error message
                print("Error signing out: %@", signOutError.localizedDescription)
            }
        }
    
}
