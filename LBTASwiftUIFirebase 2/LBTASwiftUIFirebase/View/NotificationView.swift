//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 


import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import Firebase

struct NotificationView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: NotificationViewModel
    @State private var navigateToProfile = false // State to manage the full screen cover
    @State private var selectedUserUID: String? = nil
    @State private var selectedUser: NotificationUser? // Store selected user to pass to ProfileView
    @State private var isProfilePresented = false
    
    // Custom initializer to pass userManager to the view model
    init(userManager: UserManager) {
        _viewModel = StateObject(wrappedValue: NotificationViewModel(userManager: userManager))
    }
    
    var notificationUsers_all  : [NotificationUser] = []
    
    @State private var isLoading = true
    
    let db = Firestore.firestore()
    
    var body: some View {
        
        VStack{
            //------------------------------------------------
            Spacer()
            if isLoading
                {
                Text("Loading...")
                    .font(.system(size: 24, weight: .bold))
                }
            
            else
                {
                if viewModel.notificationUsers.isEmpty
                    {
                    Text("No notifications available.")
                        .foregroundColor(.gray)
                        .padding()
                    }
                else
                {
                    List(viewModel.notificationUsers, id: \.notification.timestamp) { user in
                        VStack(alignment: .leading) {
                            HStack{
                                // Red dot if notification is unread
                                if !user.notification.isRead {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10) // Size of the red dot
                                }
                                
                                ZStack
                                {
                                    if !user.profileImageUrl.isEmpty
                                        {
                                        WebImage(url: URL(string: user.profileImageUrl))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipped()
                                            .cornerRadius(20)
                                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.customPurple, lineWidth: 0.5))
                                            .padding(.horizontal, 1)
                                            .shadow(radius: 1)
                                        }
                                    else
                                        {

                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipped()
                                            .cornerRadius(20)
                                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.customPurple, lineWidth: 0.5))
                                            .padding(.horizontal, 1)
                                            .shadow(radius: 1)
                                        }
                                }

                                
                                NavigationLink(destination: ProfileView(user_uid: user.uid)) {
                                    Text(user.full_message ?? "")  // Show notification message
                                        .font(.subheadline)
                                        .padding(.bottom, 5)
                                        .lineLimit(nil)  // Allow unlimited lines
                                        .fixedSize(horizontal: false, vertical: true) // Allow vertical resizing (wrapping)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle()) // Prevent default button styling (optional)
                                .listRowBackground(Color.clear) // Ensures no arrow appears in List

                                if user.notification.type == "friendRequest"
                                {
                                    // Confirm button
                                    Button(action: {
                                        if (user.notification.status == "pending")
                                        {
                                            // Handle Confirm button action here
                                            print ("Accepting friend request")
                                            let senderId   = user.notification.senderId
                                            let receiverId = user.notification.receiverId
                                            let requestId = senderId + "_" + receiverId
                                            print ("requestID: \(requestId)")
                                            print ("senderID: \(senderId)")
                                            print ("receiverID: \(receiverId)")
                                            // Update status in the model first
                                            //needs to update notification And send notification to accepted user
                                            if let index = viewModel.notificationUsers.firstIndex(where: { $0.uid == user.uid }) {
                                                viewModel.notificationUsers[index].notification.status = "accepted"
                                                viewModel.notificationUsers[index].notification.message = "You and $NAME are now friends."
                                                viewModel.notificationUsers[index].full_message = "You and \(user.name) (@\(user.username) are now friends."
                                            }
                                            userManager.acceptFriendRequest (requestId: requestId, receiverId: receiverId, senderId: senderId)
                                            //__ accepted your friend request
                                            userManager.sendNotificationToAcceptedUser(receiverId: senderId, senderId: receiverId) { success, error in
                                                if success {
                                                    print("Notification sent successfully")
                                                    //can be combined with updateNotificationStatus for efficiency
                                                    //You and __ are now friends
                                                    userManager.updateNotificationAccepted (user)
                                                } else {
                                                    print("Error sending notification: \(String(describing: error))")
                                                }
                                            }

                                        }
                                    }) {
                                        Text(user.notification.status == "pending" ? "Confirm" : "Friends")
                                            .font(.subheadline)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(user.notification.status == "pending" ? Color(red: 140/255, green: 82/255, blue: 255/255) : Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .contentShape(Rectangle())  // Ensure the button area is tappable
                                    .buttonStyle(PlainButtonStyle())  // Avoid default button styles
                                    
                                    if user.notification.status == "pending"{
                                        // Confirm button
                                        Button(action: {
                                            deleteFriendRequest (notificationUser: user)
                                            
                                        }) {
                                            Text("Delete")
                                                .font(.subheadline)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.gray)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .contentShape(Rectangle())  // Ensure the button area is tappable
                                        .buttonStyle(PlainButtonStyle())  // Avoid default button styles
                                        
                                    }
                                    
                                }
                                //like, comment - show pic of post
                            else
                                {
                                if let post = user.post, user.post_url != nil {

                                WebImage(url: URL(string: user.post_url ?? ""))
                                    .resizable()
                                    .scaledToFit() // Ensures the image fits within the frame without distortion
                                    .frame(width: 40, height: 40) // Sets the frame size
                                    .clipped() // Crops anything outside the frame
                                }
                                }
                            }
                            HStack
                                {
                                
                                Spacer()
                                
                                Text(user.notification.timeAgo)  // Show timestamp
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                }

                        }
                        //.padding(.vertical, 5)
                    }
                }
            }
            
            Spacer() // Pushes content to the top
            
        }
        .onAppear
            {
            print ("notifications view appeared")
            //viewModel.resetNotificationUsers()
            //populate notifications
            isLoading = true
                
            userManager.fetchNotifications { result in
                switch result {
                case .success(let notifications):
                    // Now you have the notifications, you can populate the users
                    print("Fetched \(notifications.count) notifications")
                    viewModel.populateNotificationUsers(notifications: notifications)
                    isLoading = false
                    userManager.markNotificationsAsRead()
                    
                case .failure(let error):
                    print("Error fetching notifications: \(error.localizedDescription)")
                    // Handle the error appropriately (e.g., show an error message to the user)
                }
            }

            }

        .navigationBarTitle("Notifications", displayMode: .inline)
        .navigationBarBackButtonHidden(false) // Ensure back button is shown
        
    }
    
    private func deleteFriendRequest(notificationUser: NotificationUser) {
        let senderId = notificationUser.notification.senderId
        let receiverId = notificationUser.notification.receiverId
        let requestId = "\(senderId)_\(receiverId)" // Construct the request ID

        // Reference to the friend request document
        let requestRef = db.collection("friendRequests").document(requestId)

        // Delete the friend request
        requestRef.delete { error in
            if let error = error {
                print("Error deleting friend request: \(error.localizedDescription)")
            } else {
                print("Friend request deleted successfully!")
                
                deleteNotification (notificationUser: notificationUser)
            }
        }
    }
    
    private func deleteNotification(notificationUser: NotificationUser) {
        guard let currentUser = userManager.currentUser else { return }
        let db = FirebaseManager.shared.firestore
        let notificationsRef = db.collection("notifications")
        
        // Find the notification by its timestamp and receiverId
        notificationsRef
            .whereField("timestamp", isEqualTo: notificationUser.notification.timestamp)
            .whereField("receiverId", isEqualTo: currentUser.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to find notification: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No matching notification found.")
                    return
                }

                // Delete the notification
                for document in documents {
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting notification: \(error.localizedDescription)")
                            return
                        }
                        print("Notification deleted successfully.")
                    }
                }

                // Remove the notificationUser from viewModel.notificationUsers
                if let index = viewModel.notificationUsers.firstIndex(where: { $0.uid == notificationUser.uid }) {
                    viewModel.notificationUsers.remove(at: index)
                    print("Notification user removed from viewModel.notificationUsers.")
                }
            }
    }

 
}


