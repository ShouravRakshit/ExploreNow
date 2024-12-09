import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    let settingsManager = UserSettingsManager()
    
    @State private var profileUser: User? // Holds the profile being viewed (other user)
    @State private var userPosts: [Post] = []
    @State private var isLoading = false
    @State private var showAddPost = false
    @State private var viewingOtherProfile = true
    @State private var isRequestSentToOtherUser = false
    @State private var didUserSendMeRequest = false
    @State private var isFriends = false
    @State private var isPublic  = false
    @State private var friendshipLabelText = "Add Friend..."
    @State private var friendsList: [String] = []
    //for navigating to different pages
    @State private var shouldShowLogOutOptions = false
    @State private var shouldShowMoreOptions = false //block user
    @State private var showProfileSettings = false
    @State private var showFriendsList = false
    //for removing friend
    @State private var showingAlert = false
    @State private var isBlocked: Bool = false
    @State private var didBlockUser: Bool = false  //if you blocked the user
    @State private var isCheckingBlockedStatus: Bool = true // Track the status check
    //for deleting post
    @State private var showDeleteConfirmation = false
    @State private var selectedPost: Post? = nil // To track which post is being deleted

    
    var user_uid: String // The UID of the user whose profile is being viewed
    
    @State private var activeActionSheet: ActiveSheet? = nil

    enum ActiveSheet: Identifiable {
        case settings
        case moreOptions

        var id: String {
            switch self {
            case .settings:
                return "settings"
            case .moreOptions:
                return "moreOptions"
            }
        }
    }
    
    var body: some View {
      //  NavigationView {
            VStack {
                if isCheckingBlockedStatus {
                                // Show a loading indicator while checking the blocked status
                                ProgressView()
                                    .scaleEffect(1.5)
                } else if isBlocked {
                    // If blocked, show "Can't Find this Person" view
                    VStack {
                        Spacer()
                        Text("Can't Find this Person")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                } else {
                    // Render the actual profile content if not blocked
                    profileContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Check if the user is blocked
                checkBlockedStatus()
            }
       // }
    }
    
    // Profile content for when the user is not blocked
    private var profileContent: some View {
            
            VStack(alignment: .leading) {
                
                //block user option
                if viewingOtherProfile{
                    HStack {
                        Spacer()
                        Image(systemName: "ellipsis.circle") // 3-dots icon
                            .font(.title)
                            .foregroundColor(.primary)
                            .onTapGesture {
                                activeActionSheet = .moreOptions
                            }
                    }
                    .padding (.trailing, 10)
                }
                
               else { //viewing your own profile
                    HStack {
                        Spacer()
                        Button(action: {
                            activeActionSheet = .settings
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 25))
                                .foregroundColor(Color.customPurple)
                        }
                    }
                    .padding (.trailing, 10)
                }
                
                
                ScrollView {

                    // Profile Info Section
                    HStack {
                        let imageUrl = viewingOtherProfile ? (profileUser?.profileImageUrl ?? "") : (userManager.currentUser?.profileImageUrl ?? "")
        
                        if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(40)
                                .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1))
                                .padding(.horizontal, 1)
                                .shadow(radius: 5)
                        } else {
                            // Placeholder Image
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(40)
                                .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1))
                                .padding(.horizontal, 1)
                                .shadow(radius: 5)
                            
                        }
                        
                        // Post Counts
                        VStack {
                            
                            if didBlockUser {
                                Text("0")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Posts")
                                    .font(.system(size: 16))   
                            }
                            else {
                                Text("\(userPosts.count)")
                                    .font(.system(size: 20, weight: .bold))
                                Text("\(userPosts.count == 1 ? "Post" : "Posts")")
                                    .font(.system(size: 16))
                            }
                        }.padding(.horizontal, 40)
                        
                        
                            // Friends Counts
                            VStack {
                                if didBlockUser {
                                    Text("0")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Friends")
                                        .font(.system(size: 16))
                                }
                                else{
                                    Text("\(friendsList.count)")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("\(friendsList.count == 1 ? "Friend" : "Friends")")
                                        .font(.system(size: 16))
                                }
                            
                            }
                            .padding(.horizontal, 10)
                            .onTapGesture {
                                //show friends list if you're their friend, they're public, or its your own profile
                                if (isFriends || isPublic) || !viewingOtherProfile
                                    {
                                    print ("Showing friends list")
                                    showFriendsList = true
                                    }
                                }
                        
                        Spacer()

                    }
                    .padding(.horizontal)
                    
                    // Username and Description
                    VStack(alignment: .leading, spacing: 4) {
                        if viewingOtherProfile {
                            if let profileUser = profileUser {
                                Text(profileUser.name)
                                    .font(.system(size: 24, weight: .bold))
                                Text("@\(profileUser.username)")
                                    .font(.system(size: 16, weight: .bold))
                                Text(profileUser.bio)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            } else {
                                Text("Loading...")
                                    .font(.system(size: 24, weight: .bold))
                            }
                        } else {
                            if let currentUser = userManager.currentUser {
                                Text(currentUser.name)
                                    .font(.system(size: 24, weight: .bold))
                                Text("@\(currentUser.username)")
                                    .font(.system(size: 16, weight: .bold))
                                Text(currentUser.bio)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            } else {
                                Text("Loading...")
                                    .font(.system(size: 24, weight: .bold))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 21)
                    .padding(.top, 8)
                    
                    // Friendship status - add friend, friends + Message btn
                    if viewingOtherProfile {
                        HStack{
                            Button(action: {
                                if (self.didBlockUser) {
                                    userManager.unblockUser (userId: user_uid)
                                    self.didBlockUser = false
                                    self.friendshipLabelText = "Add Friend"
                                }
                                //if request tapped -> remove friend request
                                else if (self.isRequestSentToOtherUser)
                                {
                                    userManager.deleteFriendRequest (user_uid: user_uid)
                                    self.isRequestSentToOtherUser = false
                                    self.friendshipLabelText = "Add Friend"
                                }

                                else if (self.didUserSendMeRequest)
                                {
                                    let senderId   = user_uid
                                    
                                    if let receiverId = userManager.currentUser?.uid {
                                        let requestId = senderId + "_" + receiverId
                                        userManager.acceptFriendRequest (requestId: requestId, receiverId: receiverId, senderId: senderId)
                                        //__ accepted your friend request
                                        userManager.sendNotificationToAcceptedUser(receiverId: senderId, senderId: receiverId) { success, error in
                                            if success {
                                                print("Notification sent successfully")
                                                //can be combined with updateNotificationStatus for efficiency
                                                //You and __ are now friends
                                                userManager.updateNotificationAccepted (senderId: user_uid)
                                            } else {
                                                print("Error sending notification: \(String(describing: error))")
                                            }
                                        }
                                        self.friendshipLabelText = "Friends"
                                        self.isFriends = true
                                        //make friends count go up by 1
                                        friendsList.append(userManager.currentUser?.uid ?? "Friend")
                                    }
                                }
                                else if !isFriends
                                {
                                    // Call the function to send the friend request
                                    userManager.sendFriendRequest(to: user_uid) { success, error in
                                        if success {
                                            self.isRequestSentToOtherUser = true
                                            self.friendshipLabelText = "Requested"
                                            print("Friend request and notification sent successfully.")
                                        } else {
                                            print("Failed to send friend request: \(error?.localizedDescription ?? "Unknown error")")
                                        }
                                    }
                                }
                                else if isFriends{
                                    showingAlert = true
                                }
                            }) {
                                Text(friendshipLabelText)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white) // White text color
                                    .padding() // Add padding inside the button
                                    .frame(maxWidth: .infinity) // Make the button expand to full width
                                    .background(
                                        self.didBlockUser
                                        ? Color.red // Red if the user is blocked
                                        : (isRequestSentToOtherUser || isFriends ? Color.gray : Color.customPurple) // Gray if requested or friends, else purple
                                    )
                                    .cornerRadius(25) // Rounded corners
                                    .shadow(radius: 5) // Optional shadow for depth
                            }
                            
                            if (isFriends)
                                {
                                
                                    //Link to Messages page
                            NavigationLink(
                            destination: ChatLogView(
                                chatUser: ChatUser(
                                    data: [
                                        "uid": profileUser?.uid ?? "",
                                        "email": profileUser?.email ?? "",
                                        "username": profileUser?.username ?? "",
                                        "profileImageUrl": profileUser?.profileImageUrl ?? "",
                                        "name": profileUser?.name ?? ""
                                    ]
                                )
                            )
                        )
                                 {
                                    Text("Message")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white) // White text color
                                        .padding() // Add padding inside the button
                                        .frame(maxWidth: .infinity) // Make the button expand to full width
                                        .background(Color.customPurple) // Gray if requested or friends, else purple
                                        .cornerRadius(25) // Rounded corners
                                        .shadow(radius: 5) // Optional shadow for depth
                                }
                                }
                        }
                        .padding (2)
                    }
                    
                    // Posts Section
                   
                        if isLoading {
                            ProgressView()
                                .padding()
                        }
    
                        // If viewing your own profile or a friend's profile with no posts
                        else if (!viewingOtherProfile || isFriends || isPublic) && userPosts.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.customPurple)
                                    .padding(.top, 40)
                                
                                if (!viewingOtherProfile) {
                                    Text("Share Your First Adventure!")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        showAddPost = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 20))
                                            Text("Add Your First Post")
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.customPurple)
                                        .cornerRadius(25)
                                        .shadow(color: Color.customPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                                    }
                                    .padding(.top, 10)
                                }
                                else {
                                    Text("No Posts Yet.")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                        }
                    //show posts if you're friends with the person, they're public, or its your own profile
                    else if (isFriends || isPublic) || !viewingOtherProfile {
                            LazyVStack {
                                ForEach(userPosts) { post in
                                    PostCard(post: post, onDelete: { selectedPost in
                                        self.selectedPost = selectedPost
                                        self.showDeleteConfirmation = true
                                    })
                                        .environmentObject(userManager)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
    
                    }
                    Spacer()

                    // NavigationLink is always part of the hierarchy
                    NavigationLink(
                        destination: FriendsView(user_uid: profileUser?.uid ?? "", viewingOtherProfile: self.viewingOtherProfile),
                        isActive: $showFriendsList
                    ) {
                        EmptyView() // Keeps it invisible in the UI
                    }
                    .hidden()
                }
                .navigationBarBackButtonHidden(false)
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.white)
                .fullScreenCover(isPresented: $showProfileSettings) {
                    ProfileSettingsView()
                        .environmentObject(userManager)
                        .environmentObject(appState)
                }
                .fullScreenCover(isPresented: $showAddPost) {
                    AddPostView()
                }
                .onAppear {
                    print ("Profile view appeared")
                    checkBlockedStatus() // Check if either user is blocked
                    fetchUserData()
                    fetchUserPosts(uid: user_uid)
                    fetchUserFriends(userId: user_uid) { friends, error in
                        if let error = error {
                            print("Failed to fetch friends: \(error.localizedDescription)")
                        } else if let friends = friends {
                            print("User's friends: \(friends.count)")
                        } else {
                            print("No friends found for the user.")
                        }
                    }
                }
                //.navigationBarTitle("@\(profileUser?.username)", displayMode: .inline)
                .onChange(of: showProfileSettings) { newValue in
                    if !newValue {
                        // When the full screen cover is dismissed
                        print("Full screen cover dismissed, resetting user values")
                        fetchUserData()
                        fetchUserPosts(uid: user_uid)
                        fetchUserFriends(userId: user_uid) { friends, error in
                            if let error = error {
                                print("Failed to fetch friends: \(error.localizedDescription)")
                            } else if let friends = friends {
                                print("User's friends: \(friends.count)")
                            } else {
                                print("No friends found for the user.")
                            }
                        }
                    }
                }
                
                .actionSheet(item: $activeActionSheet) { sheet in
                    switch sheet {
                    case .settings:
                        return ActionSheet(
                            title: Text("Settings"),
                            message: Text("What do you want to do?"),
                            buttons: [
                                .default(Text("Edit Profile"), action: {
                                    showProfileSettings = true
                                }),
                                .destructive(Text("Sign Out"), action: {
                                    handleSignOut()
                                }),
                                .cancel()
                            ]
                        )
                        
                    case .moreOptions:
                        return ActionSheet(
                            title: Text("User Actions"),
                            buttons: [
                                .destructive(Text(didBlockUser ? "Unblock" : "Block"), action: {
                                    if didBlockUser {
                                        // Call function to unblock user here
                                        userManager.unblockUser(userId: user_uid)
                                        self.didBlockUser = false
                                        self.friendshipLabelText = "Add Friend"
                                    } else {
                                        // Call function to block user here
                                        userManager.blockUser(userId: user_uid)
                                        //clear all possible friendship statuses
                                        self.isFriends = false
                                        self.didUserSendMeRequest = false
                                        self.isRequestSentToOtherUser = false
                                        self.didBlockUser = true
                                        self.friendshipLabelText = "Unblock"
                                        
                                        self.removeFriend (currentUserUID: userManager.currentUser?.uid ?? "", user_uid)
                                    }
                                }),
                                .cancel()
                            ]
                        )

                        
                    }
                }
                .alert(isPresented: $showingAlert) {
                     Alert(
                        title: Text("Unfriend \(self.profileUser?.username ?? "")?"),
                         message: Text("Are you sure you want to unfriend this person?"),
                         primaryButton: .destructive(Text("Unfriend")) {
                             // Unfriend action: Add your unfriending logic here
                             removeFriend (currentUserUID: userManager.currentUser?.uid ?? "", profileUser?.uid ?? "")
                             self.friendshipLabelText = "Add Friend"
                             self.isFriends = false
                             self.friendsList.removeLast()
                         },
                         secondaryButton: .cancel {
                             // Cancel action (dismiss the alert)
                             print("Unfriend canceled.")
                         }
                     )
                 }
                .alert(isPresented: $showDeleteConfirmation) {
                    Alert(
                        title: Text("Delete Post"),
                        message: Text("Are you sure you want to delete this post?"),
                        primaryButton: .destructive(Text("Delete")) {
                            if let post = selectedPost {
                                deletePost_db { success in
                                    if success {
                                        userPosts.removeAll { $0.id == post.id }
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            
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
        
    // Remove a friend from both users' friend lists
    func removeFriend(currentUserUID: String, _ friend_uid: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("friends").document(currentUserUID)
        let friendUserRef = db.collection("friends").document(friend_uid)
        
        // Fetch the current user's friend list and the friend's list
        db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                // Fetch current user's friend list
                let currentUserDoc = try transaction.getDocument(currentUserRef)
                guard let currentUserFriends = currentUserDoc.data()?["friends"] as? [String] else {
                    return nil
                }
                
                // Fetch the friend's friend list
                let friendUserDoc = try transaction.getDocument(friendUserRef)
                guard let friendUserFriends = friendUserDoc.data()?["friends"] as? [String] else {
                    return nil
                }
                
                // Remove friend from both lists
                var updatedCurrentUserFriends = currentUserFriends
                var updatedFriendUserFriends = friendUserFriends
                
                // Remove each other from the respective lists
                updatedCurrentUserFriends.removeAll { $0 == friend_uid }
                updatedFriendUserFriends.removeAll { $0 == currentUserUID }
                
                // Update the database with the new lists
                transaction.updateData(["friends": updatedCurrentUserFriends], forDocument: currentUserRef)
                transaction.updateData(["friends": updatedFriendUserFriends], forDocument: friendUserRef)
                
            } catch {
                print("Error during transaction: \(error)")
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        } completion: { (result, error) in
            if let error = error {
               // self.error = error
                return
            }
            
            print("Successfully removed friend!")

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
                    isFriends = true
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
                    isRequestSentToOtherUser = true
                    friendshipLabelText = "Requested"
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
                        didUserSendMeRequest = true
                        friendshipLabelText = "Accept Friend"
                        print ("Status: other user sent me request")
                    }
                    else{
                        print ("Other user did not send me a request")
                    }
                    
                    // Return the results once both checks are done
                    //completion(isRequestSentToOtherUser, isFriends)
                }
            }
            if didBlockUser {
                friendshipLabelText = "Unblock"
                print ("Setting friendship label to Unblock")
                return
            }
            
            if !isRequestSentToOtherUser && !isFriends{
                friendshipLabelText = "Add Friend"
                print ("Setting friendship label to Add friend")
            }
            else if isFriends{
                friendshipLabelText = "Friends"
                print ("Status: friends")
            }
            else if isRequestSentToOtherUser{
                friendshipLabelText = "Requested"
                print ("Status: requested")
            }
        }

    }
        
        // Function to fetch user data
        private func fetchUserData() {
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
                        self.profileUser = User(data: data, uid: self.user_uid)
                        settingsManager.fetchUserSettings(userId: profileUser?.uid ?? "") { isPublic in
                            print("Is public account: \(isPublic)")
                            // You can now use the `publicAccount` value
                            self.isPublic = isPublic
                        }
                        // After fetching profile user, check friendship status
                        checkFriendshipStatus(user1Id: userManager.currentUser?.uid ?? "ERROR", user2Id: user_uid)
                        // Posts will be fetched separately
                    }
                }
            }
        }
        
    func checkBlockedStatus() {
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
                isCheckingBlockedStatus = false
                return
            }

            let currentUserBlockedList = document?.data()?["blockedUserIds"] as? [String] ?? []

            profileBlocksRef.getDocument { profileDocument, error in
                if let error = error {
                    print("Error fetching profile user's blocked list: \(error.localizedDescription)")
                    isCheckingBlockedStatus = false
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

                isCheckingBlockedStatus = false
            }
        }
    }

    
        private func fetchUserPosts(uid: String) {
            isLoading = true
            
            FirebaseManager.shared.firestore
                .collection("user_posts")
                .whereField("uid", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    isLoading = false
                    
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
                                    username: viewingOtherProfile ? (profileUser?.name ?? "") : (userManager.currentUser?.name ?? ""),
                                    userProfileImageUrl: viewingOtherProfile ? (profileUser?.profileImageUrl ?? "") : (userManager.currentUser?.profileImageUrl ?? "")
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
        
        
        
        
        
        private func fetchUserFriends(userId: String, completion: @escaping ([String]?, Error?) -> Void) {
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
        
        private func handleSignOut() {
            do {
                try FirebaseManager.shared.auth.signOut()
                appState.isLoggedIn = false // Update authentication state
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError.localizedDescription)
            }
        }
    

    
}
