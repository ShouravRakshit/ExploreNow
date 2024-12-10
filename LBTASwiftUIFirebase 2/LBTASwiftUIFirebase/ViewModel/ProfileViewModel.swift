//
//  ProfileViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation
import Firebase
import SDWebImage

class ProfileViewModel: ObservableObject {
    @Published var profileUser: User? // Holds the profile being viewed (other user)
    @Published var userPosts: [Post] = []
    @Published var isLoading = false
    @Published var viewingOtherProfile = true
    @Published var isRequestSentToOtherUser = false
    @Published var didUserSendMeRequest = false
    @Published var isFriends = false
    @Published var isPublic  = false
    @Published var friendshipLabelText = "Add Friend..."
    @Published var friendsList: [String] = []

    @Published var isBlocked: Bool = false
    @Published var didBlockUser: Bool = false  //if you blocked the user
    @Published var isCheckingBlockedStatus: Bool = true // Track the status check

    @Published var selectedPost: Post? = nil // To track which post is being deleted
    
    @Published var appState: AppState
    @Published var userManager: UserManager
    @Published var settingsManager: UserSettingsManager
    
    init() {
    // Initialize with default instances
    self.appState = AppState() // Default instance, replace with actual initialization if needed
    self.userManager = UserManager() // Default instance, replace as needed
    self.settingsManager = UserSettingsManager() // Default instance, replace as needed
    }
    
    func deletePost_db(completion: @escaping (Bool) -> Void) {
        guard let postId = selectedPost?.id else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("user_posts").document(postId).delete { error in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Post successfully deleted")
                completion(true)
            }
        }
    }
 
        // Function to check friendship status
    func checkFriendshipStatus(user1Id: String, user2Id: String) {
        print ("Calling checkFriendshipStatus")
        friendshipLabelText = "Loading..."
        isFriends = false
        isRequestSentToOtherUser = false
        didUserSendMeRequest = false
        
        let db = Firestore.firestore()
 
        // 1. Check if they are friends by looking at the user's "friends" field
        let friendsRef = db.collection("friends")
        
        // Query for user1's friends list
        let user1FriendsQuery = friendsRef.document(user1Id).getDocument { (document, error) in
            if let error = error {
                print("Error checking user1's friends list: \(error)")
            } else if let document = document, document.exists {
                // Check if user2Id is in user1's friends list
                if let friendsList = document.data()?["friends"] as? [String], friendsList.contains(user2Id) {
                    self.isFriends = true
                }
                else{
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
                    print("Error checking first request query: \(error)")
                } else if !snapshot1!.isEmpty {
                    // If we find any document with status "pending", a request has been sent
                    self.isRequestSentToOtherUser = true
                    self.friendshipLabelText = "Requested"
                    print ("Status: friends")
                }
                else{
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
                self.friendshipLabelText = "Unblock"
                print ("Setting friendship label to Unblock")
                return
            }
            
            if !self.isRequestSentToOtherUser && !self.isFriends{
                self.friendshipLabelText = "Add Friend"
                print ("Setting friendship label to Add friend")
            }
            else if self.isFriends{
                self.friendshipLabelText = "Friends"
                print ("Status: friends")
            }
            else if self.isRequestSentToOtherUser{
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
                viewingOtherProfile = true
                // Fetch other user's data with a snapshot listener
                let userRef = FirebaseManager.shared.firestore.collection("users").document(user_uid)
                userRef.addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Failed to fetch profile user data:", error.localizedDescription)
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        print("No data found for profile user")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.profileUser = User(data: data, uid: user_uid)
                        self.settingsManager.fetchUserSettings(userId: self.profileUser?.uid ?? "") { isPublic in
                            print("Is public account: \(isPublic)")
                            // You can now use the `publicAccount` value
                            self.isPublic = isPublic
                        }
                        // After fetching profile user, check friendship status
                        self.checkFriendshipStatus(user1Id: self.userManager.currentUser?.uid ?? "ERROR", user2Id: user_uid)
                        // Posts will be fetched separately
                    }
                }
            }
        }
        
    func checkBlockedStatus(user_uid: String) {
        guard let currentUserId = userManager.currentUser?.uid else {
            isCheckingBlockedStatus = false
            return
        }
        let userBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        let profileBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(user_uid)

        // Fetch block status for both users
        userBlocksRef.getDocument { document, error in
            if let error = error {
                print("Error fetching current user's blocked list: \(error.localizedDescription)")
                self.isCheckingBlockedStatus = false
                return
            }

            let currentUserBlockedList = document?.data()?["blockedUserIds"] as? [String] ?? []

            profileBlocksRef.getDocument { profileDocument, error in
                if let error = error {
                    print("Error fetching profile user's blocked list: \(error.localizedDescription)")
                    self.isCheckingBlockedStatus = false
                    return
                }

                let profileUserBlockedList = profileDocument?.data()?["blockedUserIds"] as? [String] ?? []

                // Check if either user is blocked
                if profileUserBlockedList.contains(currentUserId) {
                    self.isBlocked = true
                }
                else if currentUserBlockedList.contains(user_uid) {
                    self.didBlockUser = true
                }
                else {
                    self.isBlocked = false
                }

                self.isCheckingBlockedStatus = false
            }
        }
    }

    
        func fetchUserPosts(uid: String) {
            isLoading = true
            
            FirebaseManager.shared.firestore
                .collection("user_posts")
                .whereField("uid", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    self.isLoading = false
                    
                    if let error = error {
                        print("Failed to fetch user posts:", error)
                        return
                    }
                    
                    // Clear existing posts
                    self.userPosts = []
                    
                    // Iterate over documents
                    querySnapshot?.documents.forEach { doc in
                        let data = doc.data()
                        guard let locationRef = data["locationRef"] as? DocumentReference,
                              let description = data["description"] as? String,
                              let rating = data["rating"] as? Int,
                              let imageUrls = data["images"] as? [String],
                              let timestamp = data["timestamp"] as? Timestamp,
                              let uid = data["uid"] as? String else {
                            return
                        }
                        
                        // Fetch location details
                        locationRef.getDocument { locationSnapshot, locationError in
                            if let locationError = locationError {
                                print("Error fetching location: \(locationError.localizedDescription)")
                                return
                            }
                            
                            if let locationData = locationSnapshot?.data(),
                               let address = locationData["address"] as? String {
                                // Create Post object
                                let post = Post(
                                    id: doc.documentID,
                                    description: description,
                                    rating: rating,
                                    locationRef: locationRef,
                                    locationAddress: address,
                                    imageUrls: imageUrls,
                                    timestamp: timestamp.dateValue(),
                                    uid: uid,
                                    username: self.viewingOtherProfile ? (self.profileUser?.name ?? "") : (self.userManager.currentUser?.name ?? ""),
                                    userProfileImageUrl: self.viewingOtherProfile ? (self.profileUser?.profileImageUrl ?? "") : (self.userManager.currentUser?.profileImageUrl ?? "")
                                )
                                
                                // Update posts on main thread
                                DispatchQueue.main.async {
                                    if !self.userPosts.contains(where: { $0.id == post.id }) {
                                        self.userPosts.append(post)
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
        
        func handleSignOut() {
            do {
                try FirebaseManager.shared.auth.signOut()
                appState.isLoggedIn = false // Update authentication state
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError.localizedDescription)
            }
        }
    
}
