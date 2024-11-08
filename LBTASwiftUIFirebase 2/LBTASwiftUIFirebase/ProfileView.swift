import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore


struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var profileUser: User? // User object to represent the profile being viewed
    @State private var userPosts: [Post] = []
    @State private var isLoading = false
    @State private var showProfileSettings = false
    @State private var showAddPost = false
    @State private var viewingOtherProfile = true
    @State private var isRequestSentToOtherUser = false
    @State private var didUserSendMeRequest = false
    @State private var isFriends = false
    @State private var friendshipLabelText = "Add Friend..."
    @State private var friendsList: [String] = []
    
    var user_uid: String // The UID (or username) of the user whose profile is being viewed
 //   var profileImageUrl: String?
 //   var name: String

    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                
                ScrollView {
                    
                    VStack {
                        Text ("")
                    }
                    .padding(.top, 20)  // Optional: Add horizontal padding to give some space on the sides
                    
                // Profile Info Section
                HStack {
                    WebImage(url: URL(string: profileUser?.profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(40)
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1))
                        .padding(.horizontal, 1)
                        .shadow(radius: 5)
                    
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
                    }.padding(.horizontal, 10)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Username and Description
                VStack(alignment: .leading, spacing: 4) {
                    //! forces unwrap and aborts if nil is returned
                    if let profileUser = profileUser {
                        Text(profileUser.name)
                            .font(.system(size: 24, weight: .bold))
                        Text(profileUser.bio)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    } else {
                        // Fallback UI while the data is being loaded
                        Text("Loading...")
                            .font(.system(size: 24, weight: .bold))
                    }
                    /*
                    if let bio = profileUser?.bio {
                        Text(bio)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    }*/
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 21)
                .padding(.top, 8)
                
                //Friendship status - add friend, friends
                if viewingOtherProfile{
                    Button(action: {
                        // Call the function to send the friend request
                        if let receiver_id = profileUser?.uid{
                            userManager.sendFriendRequest(to: receiver_id) { success, error in
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
                            .background((isRequestSentToOtherUser || isFriends) ? Color.gray : Color(red: 140/255, green: 82/255, blue: 255/255))// Red for "Unfriend", blue for "Add Friend"
                            .cornerRadius(25) // Rounded corners
                            .shadow(radius: 5) // Optional shadow for depth
                    }
                    .padding (.top, 10)
                    .padding(10) // Padding outside the button
                }
                
                // Posts Section
               
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if !viewingOtherProfile && userPosts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                                .padding(.top, 40)
                            
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
                                .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                                .cornerRadius(25)
                                .shadow(color: Color(red: 140/255, green: 82/255, blue: 255/255).opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                        //you should only see posts if its your profile or if you're their friend
                    } else if isFriends || !viewingOtherProfile {
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
                    if viewingOtherProfile && isFriends && userPosts.count == 0 {
                        Text ("No posts yet")
                            .padding(.top, 50)
                    }
                }
                Spacer()
            }
            .navigationBarBackButtonHidden(false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Toolbar with the username and gear icon
                ToolbarItem(placement: .principal) {
                    if !viewingOtherProfile {
                    HStack {
                        //Spacer() // To center the content
                        /*
                        if let username = profileUser?.username {
                            Button(action: {
                                // Set the navigation state to true when the email is tapped
                                
                            }) {
                                Text(username) // Make the email clickable
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.customPurple)
                            }
                        }*/
                        //Spacer() // To center the content
                        // Gear icon to the right (if viewing the user's own profile)
                                Spacer()
                                Button(action: {
                                    print("Gear icon tapped")
                                    // Handle gear icon action here
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                                }
                        }
                        
                    }
                }

            }
            .navigationBarTitleDisplayMode(.inline) // This makes the username appear inline, like a title
            
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
                checkIfRequestedUser ()
                fetchUserData  ()
                fetchUserPosts (uid: user_uid)
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
            
            .onChange(of: showProfileSettings) { newValue in
                if !newValue {
                    // When the full screen cover is dismissed (isProfileViewPresented becomes false)
                    print("Full screen cover dismissed, resetting user values")
                    // Perform necessary actions after dismissal
                    fetchUserData()
                    fetchUserPosts (uid: user_uid)
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
        }
    }
    
    private func checkIfRequestedUser (){
        //updates "add friend" label to "requested" if a request was sent by setting isRequestSent
        isRequestSentToOtherUser = true
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
                
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        
                        guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                        
                        // Fetch location details
                        locationRef.getDocument { locationSnapshot, locationError in
                            if let locationData = locationSnapshot?.data(),
                               let address = locationData["address"] as? String {
                                
                                let post = Post(
                                    id: change.document.documentID,
                                    description: data["description"] as? String ?? "",
                                    rating: data["rating"] as? Int ?? 0,
                                    locationRef: locationRef,
                                    locationAddress: address,
                                    imageUrls: data["images"] as? [String] ?? [],
                                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                    uid: data["uid"] as? String ?? "",
                                    username: profileUser?.name ?? "",
                                    userProfileImageUrl: profileUser?.profileImageUrl ?? ""
                                )
                                
                                // Update on main thread since we're modifying @State
                                DispatchQueue.main.async {
                                    if !userPosts.contains(where: { $0.id == post.id }) {
                                        userPosts.append(post)
                                        userPosts.sort { $0.timestamp > $1.timestamp }
                                    }
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
    
    // Fetch user data from Firestore
    private func fetchUserData()
        {
        //if viewing your own profile
        print ("current user uid: \(userManager.currentUser?.uid)")
        print ("profile user uid: \(user_uid)")
        if user_uid == self.userManager.currentUser?.uid
            {
            print ("Setting profile user to current user")
            self.profileUser = self.userManager.currentUser
            viewingOtherProfile = false
            
            return
            }

        //else go fetch information for the selected user
        isLoading = true
        FirebaseManager.shared.firestore
            .collection("users")
            .document(user_uid) // Fetch the user by their UID
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Failed to fetch user data:", error.localizedDescription)
                    return
                }

                guard let data = snapshot?.data() else {
                    print("No data found")
                    return
                }
                
                // Initialize the User object with the data
                self.profileUser = User(data: data, uid: user_uid)
                //print ("profile user username: \(profileUser?.username)")
            }
        //check friendship status from user1 - current user to user 2 - other user
        checkFriendshipStatus(user1Id: userManager.currentUser?.uid ?? "ERROR", user2Id: user_uid)
    }
    
    
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
                        friendshipLabelText = "Add Friend"
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
    
    
}


// Updated PostCard to show actual post data
struct UserPostCard: View {
    let post: Post
    let onDelete: (Post) -> Void
    @State private var showingAlert = false
    @State private var currentImageIndex = 0
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
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
                        WebImage(url: URL(string: post.imageUrls[index]))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 172)
                            .clipped()
                            .tag(index)
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
                Image(systemName: "bubble.right").foregroundColor(Color.customPurple)
                Text("600")
                
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
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}
