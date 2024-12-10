//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    
    //for deleting post
    @State var showDeleteConfirmation = false
    //for navigating to different pages
    @State var shouldShowLogOutOptions = false
    @State var shouldShowMoreOptions = false //block user
    @State var showProfileSettings = false
    @State var showFriendsList = false
    @State var showAddPost = false
    //for removing friend
    @State var showingAlert = false
    
    let settingsManager = UserSettingsManager()

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
    
    @StateObject private var viewModel = ProfileViewModel()
    private var user_uid: String

    // Pass appState and userManager to the ViewModel
    init(user_uid: String) {
        self.user_uid = user_uid
    }
    
    var body: some View {
      //  NavigationView {
            VStack {
                if viewModel.isCheckingBlockedStatus {
                                // Show a loading indicator while checking the blocked status
                                ProgressView()
                                    .scaleEffect(1.5)
                } else if viewModel.isBlocked {
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
                viewModel.checkBlockedStatus(user_uid: user_uid)
            }
       // }
    }
    
    // Profile content for when the user is not blocked
    private var profileContent: some View {
            
            VStack(alignment: .leading) {
                
                //block user option
                if viewModel.viewingOtherProfile{
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
                        let imageUrl = viewModel.viewingOtherProfile ? (viewModel.profileUser?.profileImageUrl ?? "") : (userManager.currentUser?.profileImageUrl ?? "")
        
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
                            
                            if viewModel.didBlockUser {
                                Text("0")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Posts")
                                    .font(.system(size: 16))   
                            }
                            else {
                                Text("\(viewModel.userPosts.count)")
                                    .font(.system(size: 20, weight: .bold))
                                Text("\(viewModel.userPosts.count == 1 ? "Post" : "Posts")")
                                    .font(.system(size: 16))
                            }
                        }.padding(.horizontal, 40)
                        
                        
                            // Friends Counts
                            VStack {
                                if viewModel.didBlockUser {
                                    Text("0")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Friends")
                                        .font(.system(size: 16))
                                }
                                else{
                                    Text("\(viewModel.friendsList.count)")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("\(viewModel.friendsList.count == 1 ? "Friend" : "Friends")")
                                        .font(.system(size: 16))
                                }
                            
                            }
                            .padding(.horizontal, 10)
                            .onTapGesture {
                                //show friends list if you're their friend, they're public, or its your own profile
                                if (viewModel.isFriends || viewModel.isPublic) || !viewModel.viewingOtherProfile
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
                        if viewModel.viewingOtherProfile {
                            if let profileUser = viewModel.profileUser {
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
                    if viewModel.viewingOtherProfile {
                        HStack{
                            Button(action: {
                                if (viewModel.didBlockUser) {
                                    userManager.unblockUser (userId: user_uid)
                                    viewModel.didBlockUser = false
                                    viewModel.friendshipLabelText = "Add Friend"
                                }
                                //if request tapped -> remove friend request
                                else if (viewModel.isRequestSentToOtherUser)
                                {
                                    userManager.deleteFriendRequest (user_uid: user_uid)
                                    viewModel.isRequestSentToOtherUser = false
                                    viewModel.friendshipLabelText = "Add Friend"
                                }

                                else if (viewModel.didUserSendMeRequest)
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
                                        viewModel.friendshipLabelText = "Friends"
                                        viewModel.isFriends = true
                                        //make friends count go up by 1
                                        viewModel.friendsList.append(userManager.currentUser?.uid ?? "Friend")
                                    }
                                }
                                else if !viewModel.isFriends
                                {
                                    // Call the function to send the friend request
                                    userManager.sendFriendRequest(to: user_uid) { success, error in
                                        if success {
                                            viewModel.isRequestSentToOtherUser = true
                                            viewModel.friendshipLabelText = "Requested"
                                            print("Friend request and notification sent successfully.")
                                        } else {
                                            print("Failed to send friend request: \(error?.localizedDescription ?? "Unknown error")")
                                        }
                                    }
                                }
                                else if viewModel.isFriends{
                                    showingAlert = true
                                }
                            }) {
                                Text(viewModel.friendshipLabelText)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white) // White text color
                                    .padding() // Add padding inside the button
                                    .frame(maxWidth: .infinity) // Make the button expand to full width
                                    .background(
                                        viewModel.didBlockUser
                                        ? Color.red // Red if the user is blocked
                                        : (viewModel.isRequestSentToOtherUser || viewModel.isFriends ? Color.gray : Color.customPurple) // Gray if requested or friends, else purple
                                    )
                                    .cornerRadius(25) // Rounded corners
                                    .shadow(radius: 5) // Optional shadow for depth
                            }
                            
                            if (viewModel.isFriends)
                                {
                                
                                    //Link to Messages page
                            NavigationLink(
                            destination: ChatLogView(
                                chatUser: ChatUser(
                                    data: [
                                        "uid": viewModel.profileUser?.uid ?? "",
                                        "email": viewModel.profileUser?.email ?? "",
                                        "username": viewModel.profileUser?.username ?? "",
                                        "profileImageUrl": viewModel.profileUser?.profileImageUrl ?? "",
                                        "name": viewModel.profileUser?.name ?? ""
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
                   
                    if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
    
                        // If viewing your own profile or a friend's profile with no posts
                    else if (!viewModel.viewingOtherProfile || viewModel.isFriends || viewModel.isPublic) && viewModel.userPosts.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.customPurple)
                                    .padding(.top, 40)
                                
                                if (!viewModel.viewingOtherProfile) {
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
                    else if (viewModel.isFriends || viewModel.isPublic) || !viewModel.viewingOtherProfile {
                            LazyVStack {
                                ForEach(viewModel.userPosts) { post in
                                    PostCard(post: post, onDelete: { selectedPost in
                                        viewModel.selectedPost = selectedPost
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
                        destination: FriendsView(user_uid: viewModel.profileUser?.uid ?? "", viewingOtherProfile: viewModel.viewingOtherProfile),
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
                    ProfileSettingsView(appState: appState, userManager: userManager)
                        .environmentObject(userManager)
                        .environmentObject(appState)
                }
                .fullScreenCover(isPresented: $showAddPost) {
                    AddPostView()
                }
                .onAppear {
                    // After the view appears, we can safely initialize the ViewModel
                    viewModel.appState = appState
                    viewModel.userManager = userManager
                    print ("Profile view appeared")
                    viewModel.checkBlockedStatus(user_uid: user_uid) // Check if either user is blocked
                    viewModel.fetchUserData(user_uid: user_uid)
                    viewModel.fetchUserPosts(uid: user_uid)
                    viewModel.fetchUserFriends(userId: user_uid) { friends, error in
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
                        viewModel.fetchUserData(user_uid: user_uid)
                        viewModel.fetchUserPosts(uid: user_uid)
                        viewModel.fetchUserFriends(userId: user_uid) { friends, error in
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
                                    viewModel.handleSignOut()
                                }),
                                .cancel()
                            ]
                        )
                        
                    case .moreOptions:
                        return ActionSheet(
                            title: Text("User Actions"),
                            buttons: [
                                .destructive(Text(viewModel.didBlockUser ? "Unblock" : "Block"), action: {
                                    if viewModel.didBlockUser {
                                        // Call function to unblock user here
                                        userManager.unblockUser(userId: user_uid)
                                        viewModel.didBlockUser = false
                                        viewModel.friendshipLabelText = "Add Friend"
                                    } else {
                                        // Call function to block user here
                                        userManager.blockUser(userId: user_uid)
                                        //clear all possible friendship statuses
                                        viewModel.isFriends = false
                                        viewModel.didUserSendMeRequest = false
                                        viewModel.isRequestSentToOtherUser = false
                                        viewModel.didBlockUser = true
                                        viewModel.friendshipLabelText = "Unblock"
                                        
                                        userManager.removeFriend (currentUserUID: userManager.currentUser?.uid ?? "", user_uid)
                                    }
                                }),
                                .cancel()
                            ]
                        )

                        
                    }
                }
                .alert(isPresented: $showingAlert) {
                     Alert(
                        title: Text("Unfriend \(viewModel.profileUser?.username ?? "")?"),
                         message: Text("Are you sure you want to unfriend this person?"),
                         primaryButton: .destructive(Text("Unfriend")) {
                             // Unfriend action: Add your unfriending logic here
                             userManager.removeFriend (currentUserUID: userManager.currentUser?.uid ?? "", viewModel.profileUser?.uid ?? "")
                             viewModel.friendshipLabelText = "Add Friend"
                             viewModel.isFriends = false
                             viewModel.friendsList.removeLast()
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
                            if let post = viewModel.selectedPost {
                                viewModel.deletePost_db { success in
                                    if success {
                                        viewModel.userPosts.removeAll { $0.id == post.id }
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }

            
        }
  
}
