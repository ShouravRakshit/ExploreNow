//import SwiftUI
//import SDWebImageSwiftUI
//import Firebase
//import FirebaseFirestore
//
//
//struct ProfileView: View {
//    @EnvironmentObject var userManager: UserManager
//    @State private var userPosts: [Post] = []
//    @State private var isLoading = false
//    @State private var showProfileSettings = false
//    @State private var showAddPost = false
//    @State private var viewingOtherProfile = true
//    @State private var isRequestSentToOtherUser = false
//    @State private var didUserSendMeRequest = false
//    @State private var isFriends = false
//    @State private var friendshipLabelText = "Add Friend..."
//    @State private var friendsList: [String] = []
//    @State private var shouldShowLogOutOptions = false
//    @EnvironmentObject var appState: AppState
//    var user_uid: String // The UID of the user whose profile is being viewed
//
//    
//    var body: some View {
//        NavigationView {
//            VStack(alignment: .leading) {
//                
//                ScrollView {
//                    
//                    VStack {
//                        Text ("")
//                    }
//                    .padding(.top, 20)  // Optional: Add horizontal padding to give some space on the sides
//                    
//                // Profile Info Section
//                HStack {
//                    let imageUrl = viewingOtherProfile ? (userManager.getUser(by: user_uid)?.profileImageUrl ?? "") : (userManager.currentUser?.profileImageUrl ?? "")
//
//                    WebImage(url: URL(string: imageUrl))
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 80, height: 80)
//                        .clipped()
//                        .cornerRadius(40)
//                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1))
//                        .padding(.horizontal, 1)
//                        .shadow(radius: 5)
//                    
//                    // Post Counts
//                    VStack {
//                        Text("\(userPosts.count)")
//                            .font(.system(size: 20, weight: .bold))
//                        Text("\(userPosts.count == 1 ? "Post" : "Posts")")
//                            .font(.system(size: 16))
//                    }.padding(.horizontal, 40)
//                    
//                    // Friends Counts
//                    VStack {
//                        Text("\(friendsList.count)")
//                            .font(.system(size: 20, weight: .bold))
//                        Text("\(friendsList.count == 1 ? "Friend" : "Friends")")
//                            .font(.system(size: 16))
//                    }.padding(.horizontal, 10)
//                    
//                    Spacer()
//                }
//                .padding(.horizontal)
//                
//                // Username and Description
//                VStack(alignment: .leading, spacing: 4) {
//                    if viewingOtherProfile {
//                        if let profileUser = userManager.getUser(by: user_uid) {
//                            Text(profileUser.name)
//                                .font(.system(size: 24, weight: .bold))
//                            Text("@\(profileUser.username)")
//                                .font(.system(size: 16, weight: .bold))
//                            Text(profileUser.bio)
//                                .font(.system(size: 14, weight: .medium))
//                                .foregroundColor(.black)
//                        } else {
//                            Text("Loading...")
//                                .font(.system(size: 24, weight: .bold))
//                        }
//                    } else {
//                        if let currentUser = userManager.currentUser {
//                            Text(currentUser.name)
//                                .font(.system(size: 24, weight: .bold))
//                            Text("@\(currentUser.username)")
//                                .font(.system(size: 16, weight: .bold))
//                            Text(currentUser.bio)
//                                .font(.system(size: 14, weight: .medium))
//                                .foregroundColor(.black)
//                        } else {
//                            Text("Loading...")
//                                .font(.system(size: 24, weight: .bold))
//                        }
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal, 21)
//                .padding(.top, 8)
//                
//                //Friendship status - add friend, friends
//                if viewingOtherProfile{
//                    Button(action: {
//                        // Call the function to send the friend request
//                        if let receiver_id = userManager.currentUser?.uid, viewingOtherProfile {
//                            userManager.sendFriendRequest(to: receiver_id) { success, error in
//                                if success {
//                                    self.isRequestSentToOtherUser = true
//                                    self.friendshipLabelText = "Requested"
//                                    print("Friend request and notification sent successfully.")
//                                } else {
//                                    print("Failed to send friend request: \(error?.localizedDescription ?? "Unknown error")")
//                                }
//                            }
//                        }
//                    }) {
//                        Text(friendshipLabelText)
//                            .font(.system(size: 15, weight: .bold))
//                            .foregroundColor(.white) // White text color
//                            .padding() // Add padding inside the button
//                            .frame(maxWidth: .infinity) // Make the button expand to full width
//                            .background((isRequestSentToOtherUser || isFriends) ? Color.gray : Color(red: 140/255, green: 82/255, blue: 255/255))// Red for "Unfriend", blue for "Add Friend"
//                            .cornerRadius(25) // Rounded corners
//                            .shadow(radius: 5) // Optional shadow for depth
//                    }
//                    .padding (.top, 10)
//                    .padding(10) // Padding outside the button
//                }
//                
//                // Posts Section
//               
//                    if isLoading {
//                        ProgressView()
//                            .padding()
//                    }
//
//                    //if viewing your own profile or a friends profile with no posts
//                    else if (!viewingOtherProfile || isFriends) && userPosts.isEmpty {
//                        VStack(spacing: 20) {
//                            Image(systemName: "camera.fill")
//                                .font(.system(size: 50))
//                                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
//                                .padding(.top, 40)
//                            
//                            if (!viewingOtherProfile)
//                            {
//                                Text("Share Your First Adventure!")
//                                    .font(.headline)
//                                    .foregroundColor(.gray)
//                                
//                                
//                                Button(action: {
//                                    showAddPost = true
//                                }) {
//                                    HStack {
//                                        Image(systemName: "plus.circle.fill")
//                                            .font(.system(size: 20))
//                                        Text("Add Your First Post")
//                                    }
//                                    .foregroundColor(.white)
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 12)
//                                    .background(Color(red: 140/255, green: 82/255, blue: 255/255))
//                                    .cornerRadius(25)
//                                    .shadow(color: Color(red: 140/255, green: 82/255, blue: 255/255).opacity(0.3), radius: 10, x: 0, y: 5)
//                                }
//                                .padding(.top, 10)
//                            }
//                            else {
//                                Text("No Posts Yet.")
//                                    .font(.headline)
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 50)
//                        //you should only see posts if its your profile or if you're their friend
//                    } else if isFriends || !viewingOtherProfile {
//                        LazyVStack {
//                            ForEach(userPosts) { post in
//                                UserPostCard(post: post, onDelete: { deletedPost in
//                                    deletePost(deletedPost)
//                                })
//                                .padding(.top, 10)
//                                .padding(.horizontal, 5)  // Add horizontal padding to each post
//                            }
//                        }
//                        .padding(.horizontal, 2)
//                        
//                    }
//
//                }
//                Spacer()
//            }
//            .navigationBarBackButtonHidden(false)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                // Toolbar with the username and gear icon
//                ToolbarItem(placement: .principal) {
//                    if !viewingOtherProfile {
//                    HStack {
//                        Spacer() // To center the content
//                        /*
//                        if let username = profileUser?.username {
//                            Button(action: {
//                                // Set the navigation state to true when the email is tapped
//                                
//                            }) {
//                                Text(username) // Make the email clickable
//                                    .font(.system(size: 20, weight: .bold))
//                                    .foregroundColor(.customPurple)
//                            }
//                        }*/
//                        //Spacer() // To center the content
//                        // Gear icon to the right (if viewing the user's own profile)
//                                Spacer()
//                                Button(action: {
//                                    shouldShowLogOutOptions = true
//                                    
//                                }) {
//                                    Image(systemName: "gearshape.fill")
//                                        .font(.system(size: 20))
//                                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
//                                }
//                        }
//                        
//                    }
//                }
//
//            }
//            .navigationBarTitleDisplayMode(.inline) // This makes the username appear inline, like a title
//            
//            .background(Color.white)
//            .fullScreenCover(isPresented: $showProfileSettings) {
//                ProfileSettingsView()
//                    .environmentObject(userManager)
//            }
//            .fullScreenCover(isPresented: $showAddPost) {
//                AddPostView()
//            }
//            .onAppear {
//                print ("Profile view appeared")
//                checkIfRequestedUser ()
//                fetchUserData  ()
//                fetchUserPosts (uid: user_uid)
//                fetchUserFriends(userId: user_uid) { friends, error in
//                    if let error = error {
//                        print("Failed to fetch friends: \(error.localizedDescription)")
//                    } else if let friends = friends {
//                        print("User's friends: \(friends.count)")
//                    } else {
//                        print("No friends found for the user.")
//                    }
//                }
//            }
//            
//            .onChange(of: showProfileSettings) { newValue in
//                if !newValue {
//                    // When the full screen cover is dismissed (isProfileViewPresented becomes false)
//                    print("Full screen cover dismissed, resetting user values")
//                    // Perform necessary actions after dismissal
//                    fetchUserData()
//                    fetchUserPosts (uid: user_uid)
//                    fetchUserFriends(userId: user_uid) { friends, error in
//                        if let error = error {
//                            print("Failed to fetch friends: \(error.localizedDescription)")
//                        } else if let friends = friends {
//                            print("User's friends: \(friends.count)")
//                        } else {
//                            print("No friends found for the user.")
//                        }
//                    }
//                }
//            }
//            
//            .actionSheet(isPresented: $shouldShowLogOutOptions) {
//                ActionSheet(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
//                    .default(Text("Edit Profile"), action: {
//                        showProfileSettings = true
//                    }),
//                    .destructive(Text("Sign Out"), action: {
//                        handleSignOut()
//                    }),
//                    .cancel()
//                ])
//            }
//        }
//    }
//    
//    private func checkIfRequestedUser (){
//        //updates "add friend" label to "requested" if a request was sent by setting isRequestSent
//        isRequestSentToOtherUser = true
//    }
//    
//    // Fetch user data
//    private func fetchUserData() {
//                // Determine if viewing own profile or another user's profile
//                if user_uid == userManager.currentUser?.uid {
//                    viewingOtherProfile = false
//                    // No need to fetch data; currentUser is already available
//                    return
//                } else {
//                    viewingOtherProfile = true
//                    // Data for other users is fetched via userManager.getUser(by:)
//                }
//    }
//    
//    private func fetchUserPosts(uid: String) {
//                isLoading = true
//                
//                FirebaseManager.shared.firestore
//                    .collection("user_posts")
//                    .whereField("uid", isEqualTo: uid)
//                    .order(by: "timestamp", descending: true)
//                    .addSnapshotListener { [weak self] querySnapshot, error in
//                        guard let self = self else { return }
//                        self.isLoading = false
//                        
//                        if let error = error {
//                            print("Failed to fetch user posts:", error)
//                            return
//                        }
//                        
//                        self.userPosts = querySnapshot?.documents.compactMap { doc in
//                            let data = doc.data()
//                            guard let locationRef = data["locationRef"] as? DocumentReference,
//                                  let description = data["description"] as? String,
//                                  let rating = data["rating"] as? Int,
//                                  let imageUrls = data["images"] as? [String],
//                                  let timestamp = data["timestamp"] as? Timestamp,
//                                  let uid = data["uid"] as? String else {
//                                return nil
//                            }
//                            
//                            // Fetch location details synchronously (not recommended for production)
//                            // Consider using asynchronous fetching or storing locationAddress directly
//                            var locationAddress = ""
//                            locationRef.getDocument { locationSnapshot, locationError in
//                                if let locationError = locationError {
//                                    print("Error fetching location: \(locationError.localizedDescription)")
//                                    return
//                                }
//                                
//                                if let locationData = locationSnapshot?.data(),
//                                   let address = locationData["address"] as? String {
//                                    locationAddress = address
//                                    
//                                    // Create Post object
//                                    let post = Post(
//                                        id: doc.documentID,
//                                        description: description,
//                                        rating: rating,
//                                        locationRef: locationRef,
//                                        locationAddress: address,
//                                        imageUrls: imageUrls,
//                                        timestamp: timestamp.dateValue(),
//                                        uid: uid,
//                                        username: self.userManager.currentUser?.name ?? "",
//                                        userProfileImageUrl: self.userManager.currentUser?.profileImageUrl ?? ""
//                                    )
//                                    
//                                    // Update posts on main thread
//                                    DispatchQueue.main.async {
//                                        if !self.userPosts.contains(where: { $0.id == post.id }) {
//                                            self.userPosts.append(post)
//                                            self.userPosts.sort { $0.timestamp > $1.timestamp }
//                                        }
//                                    }
//                                }
//                            }
//                            
//                            return nil // Return nil initially; actual posts are appended in the locationRef callback
//                        } ?? []
//                    }
//            }
//
//    private func deletePost(_ post: Post) {
//        // Remove from local array first for immediate UI update
//        userPosts.removeAll { $0.id == post.id }
//        
//        // Delete images from Storage
//        for imageUrl in post.imageUrls {
//            let imageRef = FirebaseManager.shared.storage.reference(forURL: imageUrl)
//            imageRef.delete { error in
//                if let error = error {
//                    print("Error deleting image: \(error.localizedDescription)")
//                }
//            }
//        }
//        
//        // Delete post document from Firestore
//        FirebaseManager.shared.firestore
//            .collection("user_posts")
//            .document(post.id)
//            .delete { error in
//                if let error = error {
//                    print("Error deleting post: \(error.localizedDescription)")
//                    return
//                }
//                
//                // Update location's average rating
//                updateLocationRating(locationRef: post.locationRef)
//            }
//    }
//    
//    private func updateLocationRating(locationRef: DocumentReference) {
//        let db = FirebaseManager.shared.firestore
//        
//        // Get all remaining posts for this location
//        db.collection("user_posts")
//            .whereField("locationRef", isEqualTo: locationRef)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error getting posts for rating update: \(error.localizedDescription)")
//                    return
//                }
//                
//                // Calculate new average
//                var totalRating = 0
//                var count = 0
//                
//                snapshot?.documents.forEach { doc in
//                    if let rating = doc.data()["rating"] as? Int {
//                        totalRating += rating
//                        count += 1
//                    }
//                }
//                
//                if count > 0 {
//                    let newAverageRating = Double(totalRating) / Double(count)
//                    // Update location with new average rating
//                    locationRef.updateData([
//                        "average_rating": newAverageRating
//                    ])
//                } else {
//                    // Either delete the location or set rating to 0
//                    locationRef.updateData([
//                        "average_rating": 0
//                    ])
//                }
//            }
//    }
//    
//    // Fetch user data from Firestore
////    private func fetchUserData()
////        {
////        //if viewing your own profile
////        print ("current user uid: \(userManager.currentUser?.uid)")
////        print ("profile user uid: \(user_uid)")
////        if user_uid == self.userManager.currentUser?.uid
////            {
////            print ("Setting profile user to current user")
////            self.profileUser = self.userManager.currentUser
////            viewingOtherProfile = false
////            
////            return
////        }
//
//        //else go fetch information for the selected user
//        isLoading = true
//        FirebaseManager.shared.firestore
//            .collection("users")
//            .document(user_uid) // Fetch the user by their UID
//            .addSnapshotListener { snapshot, error in
//                isLoading = false
//                if let error = error {
//                    print("Failed to fetch user data:", error.localizedDescription)
//                    return
//                }
//
//                guard let data = snapshot?.data() else {
//                    print("No data found")
//                    return
//                }
//                
//                // Initialize the User object with the data
//                self.profileUser = User(data: data, uid: user_uid)
//                //print ("profile user username: \(profileUser?.username)")
//            }
//        //check friendship status from user1 - current user to user 2 - other user
//        checkFriendshipStatus(user1Id: userManager.currentUser?.uid ?? "ERROR", user2Id: user_uid)
//    }
//    
//    
//    func checkFriendshipStatus(user1Id: String, user2Id: String) {
//        print ("Calling checkFriendshipStatus")
//        friendshipLabelText = "Loading..."
//        isFriends = false
//        isRequestSentToOtherUser = false
//        didUserSendMeRequest = false
//        
//        let db = Firestore.firestore()
// 
//        // 1. Check if they are friends by looking at the user's "friends" field
//        let friendsRef = db.collection("friends")
//        
//        // Query for user1's friends list
//        let user1FriendsQuery = friendsRef.document(user1Id).getDocument { (document, error) in
//            if let error = error {
//                print("Error checking user1's friends list: \(error)")
//            } else if let document = document, document.exists {
//                // Check if user2Id is in user1's friends list
//                if let friendsList = document.data()?["friends"] as? [String], friendsList.contains(user2Id) {
//                    isFriends = true
//                }
//                else{
//                    print ("Not friends")
//                }
//            }
//            
//            // 2. Now check if a friend request has been sent with "pending" status
//            let friendRequestsRef = db.collection("friendRequests")
//            
//            // Query for a pending request from user1 to user2
//            let requestQuery1 = friendRequestsRef.whereField("senderId", isEqualTo: user1Id)
//                                                .whereField("receiverId", isEqualTo: user2Id)
//                                                .whereField("status", isEqualTo: "pending")
//            
//            // Query for a pending request from user2 to user1
//            let requestQuery2 = friendRequestsRef.whereField("senderId", isEqualTo: user2Id)
//                                                .whereField("receiverId", isEqualTo: user1Id)
//                                                .whereField("status", isEqualTo: "pending")
//            
//            // Execute both requests queries
//            requestQuery1.getDocuments { (snapshot1, error) in
//                if let error = error {
//                    print("Error checking first request query: \(error)")
//                } else if !snapshot1!.isEmpty {
//                    // If we find any document with status "pending", a request has been sent
//                    isRequestSentToOtherUser = true
//                    friendshipLabelText = "Requested"
//                    print ("Status: friends")
//                }
//                else{
//                    print ("Did not send friend request to other user")
//                }
//                
//                // Execute the second query (for the reverse direction)
//                requestQuery2.getDocuments { (snapshot2, error) in
//                    if let error = error {
//                        print("Error checking second request query: \(error)")
//                    } else if !snapshot2!.isEmpty {
//                        // If we find any document with status "pending", a request has been sent
//                        didUserSendMeRequest = true
//                        friendshipLabelText = "Add Friend"
//                        print ("Status: other user sent me request")
//                    }
//                    else{
//                        print ("Other user did not send me a request")
//                    }
//                    
//                    // Return the results once both checks are done
//                    //completion(isRequestSentToOtherUser, isFriends)
//                }
//            }
//            if !isRequestSentToOtherUser && !isFriends{
//                friendshipLabelText = "Add Friend"
//                print ("Setting friendship label to Add friend")
//            }
//            else if isFriends{
//                friendshipLabelText = "Friends"
//                print ("Status: friends")
//            }
//            else if isRequestSentToOtherUser{
//                friendshipLabelText = "Requested"
//                print ("Status: requested")
//            }
//        }
//
//    }
    
//    func fetchUserFriends(userId: String, completion: @escaping ([String]?, Error?) -> Void) {
//        let db = Firestore.firestore()
//        
//        // Reference to the user's document in the 'friends' collection
//        let friendsRef = db.collection("friends").document(userId)
//        
//        // Fetch the document for the user
//        friendsRef.getDocument { (document, error) in
//            if let error = error {
//                // Handle any errors that occurred during the fetch
//                print("Error fetching friends for user \(userId): \(error.localizedDescription)")
//                completion(nil, error)
//            } else if let document = document, document.exists {
//                // Document exists, extract the 'friends' field (assuming it's an array of friend IDs)
//                if let friendsList = document.data()?["friends"] as? [String] {
//                    self.friendsList = friendsList
//                    // Return the list of friend IDs
//                    completion(friendsList, nil)
//                } else {
//                    // No friends list or the 'friends' field is missing
//                    print("No friends list found for user \(userId).")
//                    completion([], nil) // Returning an empty list if no friends are found
//                }
//            } else {
//                // The document doesn't exist (no friends found for the user)
//                print("No document found for user \(userId).")
//                completion([], nil) // Returning an empty list if no document exists
//            }
//        }
//    }
//    
//    private func handleSignOut() {
//        do {
//            try FirebaseManager.shared.auth.signOut()
//            appState.isLoggedIn = false // Update authentication state
//        } catch let signOutError as NSError {
//            print("Error signing out: %@", signOutError.localizedDescription)
//        }
//    }
//
//    
//    
//}
//
//
//// Updated PostCard to show actual post data
//struct UserPostCard: View {
//    let post: Post
//    let onDelete: (Post) -> Void
//    @State private var showingAlert = false
//    @State private var currentImageIndex = 0
//    @State private var showingError = false
//    @State private var errorMessage = ""
//    
//    var body: some View {
//        NavigationLink(destination: PostView(post: post, likesCount: post.likesCount, liked: post.liked)) {
//            VStack(alignment: .leading, spacing: 0) {
//                HStack {
//                    Spacer()
//                    Button(action: {
//                        showingAlert = true
//                    }) {
//                        Image(systemName: "trash")
//                            .foregroundColor(.red)
//                    }
//                }
//                .padding([.top, .trailing])
//                
//                if !post.imageUrls.isEmpty {
//                    TabView(selection: $currentImageIndex) {
//                        ForEach(post.imageUrls.indices, id: \.self) { index in
//                            WebImage(url: URL(string: post.imageUrls[index]))
//                                .resizable()
//                                .scaledToFill()
//                                .frame(height: 172)
//                                .clipped()
//                                .tag(index)
//                        }
//                    }
//                    .tabViewStyle(PageTabViewStyle())
//                    .frame(height: 172)
//                    .padding(.horizontal, 10)
//                    .padding(.top, 6)
//                }
//                
//                Text(post.description)
//                    .font(.system(size: 14))
//                    .padding(.horizontal)
//                    .padding(.top, 8)
//                
//                HStack {
//                    Image(systemName: "bubble.right").foregroundColor(Color.customPurple)
//                    Text("600")
//                    
//                    Spacer()
//                    
//                    HStack(spacing: 10) {
//                        Image(systemName: "star.fill").foregroundColor(Color.customPurple)
//                        Text("\(post.rating)")
//                        
//                        Image(systemName: "mappin.and.ellipse").foregroundColor(Color.customPurple)
//                        Text(post.locationAddress)
//                            .lineLimit(1)
//                    }
//                }
//                .font(.system(size: 14))
//                .foregroundColor(.gray)
//                .padding(.horizontal)
//                .padding(.vertical, 8)
//            }
//            .background(Color.white)
//            .cornerRadius(12)
//            .shadow(radius: 5)
//            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.customPurple, lineWidth: 1))
//            .alert(isPresented: $showingAlert) {
//                Alert(
//                    title: Text("Delete Post"),
//                    message: Text("Are you sure you want to delete this post? This action cannot be undone."),
//                    primaryButton: .destructive(Text("Delete")) {
//                        onDelete(post)
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//            .alert("Error", isPresented: $showingError) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(errorMessage)
//            }
//        }
//    }
//}














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
    @State private var showProfileSettings = false
    @State private var showFriendsList = false
    
    @State private var isBlocked: Bool = false
    @State private var isCheckingBlockedStatus: Bool = true // Track the status check

    
    var user_uid: String // The UID of the user whose profile is being viewed
    
    var body: some View {
        NavigationView {
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
        }
    }
    
    // Profile content for when the user is not blocked
    private var profileContent: some View {
        NavigationView {
            
            VStack(alignment: .leading) {
                
                if !viewingOtherProfile {
                    HStack {
                        Spacer()
                        Button(action: {
                            shouldShowLogOutOptions = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 25))
                                .foregroundColor(Color.customPurple)
                        }
                    }
                    .padding (.trailing, 10)
                }
                
                ScrollView {
                    
                    VStack {
                        Text ("")
                    }
                    .padding(.top, 5)  // Optional: Add horizontal padding to give some space on the sides
                    
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
                            Image(systemName: "person.fill")
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
                            Text("\(userPosts.count)")
                                .font(.system(size: 20, weight: .bold))
                            Text("\(userPosts.count == 1 ? "Post" : "Posts")")
                                .font(.system(size: 16))
                        }.padding(.horizontal, 40)
                        
                        // Friends Counts
                        VStack {
                            Text("\(friendsList.count)")
                                .font(.system(size: 20, weight: .bold))
                            Text("\(friendsList.count == 1 ? "Friend" : "Friends")")
                                .font(.system(size: 16))
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
                                
                                if (self.didUserSendMeRequest)
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
                            }) {
                                Text(friendshipLabelText)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white) // White text color
                                    .padding() // Add padding inside the button
                                    .frame(maxWidth: .infinity) // Make the button expand to full width
                                    .background((isRequestSentToOtherUser || isFriends) ? Color.gray : Color.customPurple) // Gray if requested or friends, else purple
                                    .cornerRadius(25) // Rounded corners
                                    .shadow(radius: 5) // Optional shadow for depth
                            }
                            
                            if (isFriends || isPublic)
                                {
                                Button(action: {
                                    //Link to Messages page
                                }) {
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
                                    UserPostCard(post: post, onDelete: { deletedPost in
                                        deletePost(deletedPost)
                                    })
                                    .padding(.top, 10)
                                    .padding(.horizontal, 5)  // Add horizontal padding to each post
                                }
                            }
                            .padding(.horizontal, 2)
                        }
    
                    }
                    Spacer()
                    
                    // Conditional NavigationLink
                    if showFriendsList {
                        NavigationLink(
                            destination: FriendsView (user_uid: profileUser?.uid ?? ""),
                            isActive: $showFriendsList,
                            label: { EmptyView() }
                        )
                        .hidden() // Hide the NavigationLink in the UI
                    }
                }
                .navigationBarBackButtonHidden(false)
                .navigationBarTitleDisplayMode(.inline)
                /*
                .toolbar {
                    // Toolbar with the gear icon
                    ToolbarItem(placement: .principal) {
                        if !viewingOtherProfile {
                            HStack {
                                Spacer()
                                Button(action: {
                                    shouldShowLogOutOptions = true
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color.customPurple)
                                }
                            }
                        }
                    }
                }*/
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.white)
                .fullScreenCover(isPresented: $showProfileSettings) {
                    ProfileSettingsView()
                        .environmentObject(userManager)
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
                
                .actionSheet(isPresented: $shouldShowLogOutOptions) {
                    ActionSheet(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                        .default(Text("Edit Profile"), action: {
                            showProfileSettings = true
                        }),
                        .destructive(Text("Sign Out"), action: {
                            handleSignOut()
                        }),
                        .cancel()
                    ])
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
        let currentUserId = userManager.currentUser?.uid ?? ""
        let userBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        let profileBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(user_uid)

        // Fetch block status for both users
        userBlocksRef.getDocument { document, error in
            if let error = error {
                print("Error fetching current user's blocked list: \(error.localizedDescription)")
                isCheckingBlockedStatus = false // Stop loading even if there's an error
                return
            }

            let currentUserBlockedList = document?.data()?["blockedUserIds"] as? [String] ?? []

            profileBlocksRef.getDocument { profileDocument, error in
                if let error = error {
                    print("Error fetching profile user's blocked list: \(error.localizedDescription)")
                    isCheckingBlockedStatus = false // Stop loading even if there's an error
                    return
                }

                let profileUserBlockedList = profileDocument?.data()?["blockedUserIds"] as? [String] ?? []

                // Check if either user is blocked
                if currentUserBlockedList.contains(user_uid) || profileUserBlockedList.contains(currentUserId) {
                    self.isBlocked = true
                } else {
                    self.isBlocked = false
                }

                isCheckingBlockedStatus = false // Status check complete
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
        
        private func deletePost(_ post: Post) {
            // Remove from local array first for immediate UI update
            userPosts.removeAll { $0.id == post.id }
            
            // Delete images from Storage
            for imageUrl in post.imageUrls {
                let imageRef = FirebaseManager.shared.storage.reference(forURL: imageUrl)
                imageRef.delete { error in
                    if let error = error {
                        print("Error deleting image: \(error.localizedDescription)")
                    }
                }
            }
            
            // Delete post document from Firestore
            FirebaseManager.shared.firestore
                .collection("user_posts")
                .document(post.id)
                .delete { error in
                    if let error = error {
                        print("Error deleting post: \(error.localizedDescription)")
                        return
                    }
                    
                    // Update location's average rating
                    updateLocationRating(locationRef: post.locationRef)
                }
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
    
struct UserPostCard: View {
    let post: Post
    let onDelete: (Post) -> Void
    @State private var showingAlert = false
    @State private var currentImageIndex = 0
    @State private var comments: [Comment] = []
    @State private var likesCount: Int = 0  // Track the like count
    @State private var likedByUserIds: [String] = []  // Track the list of users who liked the post
    @State private var liked: Bool = false  // Track if the current user has liked the post
    
    var body: some View {
        NavigationLink(destination: PostView(post: post, likesCount: post.likesCount, liked: post.liked)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        showingAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding([.top, .trailing])
                
                if !post.imageUrls.isEmpty {
                    TabView(selection: $currentImageIndex) {
                        ForEach(post.imageUrls.indices, id: \.self) { index in
                            if let url = URL(string: post.imageUrls[index]), !post.imageUrls[index].isEmpty {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 172)
                                    .clipped()
                                    .tag(index)
                            } else {
                                // Placeholder Image
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 172)
                                    .clipped()
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 172)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                }
                
                Text(post.description)
                    .font(.system(size: 14))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                HStack {
                    Button(action: {
                        toggleLike()
                    }) {
                        HStack(spacing: 4) {
                            // Heart icon that changes based on whether the post is liked
                            Image(systemName: liked ? "heart.fill" : "heart")  // Filled heart if liked, empty if not
                                .foregroundColor(liked ? .red : .gray)  // Red if liked, gray if not
                                .padding(5)
                            
                            // Display like count
                            Text("\(likesCount)")
                                .foregroundColor(.gray)  // Like count in gray
                        }
                    }
                    
                    Spacer()
                        .frame(width: 20)
                    
                    HStack {
                        Image(systemName: "bubble.right").foregroundColor(Color.customPurple)
                        Text("\(comments.count)") // Display comment count
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill").foregroundColor(Color.customPurple)
                        Text("\(post.rating)")
                        Image(systemName: "mappin.and.ellipse").foregroundColor(Color.customPurple)
                        Text(post.locationAddress)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.customPurple, lineWidth: 1))
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Delete Post"),
                    message: Text("Are you sure you want to delete this post? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        onDelete(post)
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                fetchLikes()
                fetchComments() // Fetch comments when the view appears
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
        
        if liked {
            // If the post is already liked by the current user, remove the like
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
                }
            }
    }
}
