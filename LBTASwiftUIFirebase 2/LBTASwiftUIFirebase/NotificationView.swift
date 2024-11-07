//
//  NotificationView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-11-06.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import Firebase

struct NotificationView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: NotificationViewModel
    
    // Custom initializer to pass userManager to the view model
    init(userManager: UserManager) {
        _viewModel = StateObject(wrappedValue: NotificationViewModel(userManager: userManager))
    }
    
    //var notifications_all: [Notification] = []  // Array to hold notification objects
    var notificationUsers: [NotificationUser] = []
    @State private var isLoading = false
    
    let db = Firestore.firestore()
    
    var body: some View {
        VStack{
            //----- TOP ROW --------------------------------------
            HStack {
                Image(systemName: "chevron.left")
                    .resizable() // Make the image resizable
                    .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
                    .frame(width: 30, height: 30) // Set size
                    .padding()
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                    .onTapGesture {
                        // Go back to profile page
                        self.userManager.hasUnreadNotifications = false
                        userManager.fetchNotifications()
                        presentationMode.wrappedValue.dismiss()
                    }
                Spacer() // Pushes the text to the center
                Text("Notifications")
                    .font(.custom("Sansation-Regular", size: 30))
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                    .offset(x: -30)
                Spacer() // Pushes the text to the center
            }
            //------------------------------------------------
            Spacer()
            if isLoading {
                Text("Loading...")
                    .font(.system(size: 24, weight: .bold))
            }
            
            else{
                if viewModel.notificationUsers.isEmpty{
                    Text("No notifications available.")
                        .foregroundColor(.gray)
                        .padding()
                }
                else
                {
                    List(viewModel.notificationUsers, id: \.uid) { user in
                        VStack(alignment: .leading) {
                            HStack{
                                // User image
                                if !user.profileImageUrl.isEmpty
                                {
                                    WebImage(url: URL(string: user.profileImageUrl))
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(Circle()) // Clip to circle shape
                                        .frame(width: 50, height: 50) // Set size
                                }
                                else
                                {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                        .frame(width: 50, height: 50) // Set size for placeholder
                                        .background(Color.gray.opacity(0.2)) // Optional background
                                        .clipShape(Circle()) // Clip to circle shape
                                }
                                
                                Text(user.notification.message)  // Show notification message
                                    .font(.body)
                                    .padding(.bottom, 5)
                                    .lineLimit(nil)  // Allow unlimited lines
                                    .fixedSize(horizontal: false, vertical: true) // Allow vertical resizing (wrapping)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Confirm button
                                Button(action: {
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
                                        viewModel.notificationUsers[index].notification.message = "You and \(user.name) are now friends."
                                    }
                                    acceptFriendRequest (requestId: requestId, receiverId: receiverId, senderId: senderId)
                                    //__ accepted your friend request
                                    sendNotificationToAcceptedUser(receiverId: senderId, senderId: receiverId) { success, error in
                                        if success {
                                            print("Notification sent successfully")
                                        } else {
                                            print("Error sending notification: \(String(describing: error))")
                                        }
                                    }
                                    //can be combined with updateNotificationStatus for efficiency
                                    //You and __ are now friends
                                    updateNotificationAccepted (user)
                                }) {
                                    Text(user.notification.status == "pending" ? "Confirm" : "Friends")
                                        .font(.body)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(user.notification.status == "pending" ? Color(red: 140/255, green: 82/255, blue: 255/255) : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .contentShape(Rectangle())  // Ensure the button area is tappable
                                .buttonStyle(PlainButtonStyle())  // Avoid default button styles
                                
                            }
                            HStack {
                                /*
                                Text("From: \(user.notification.senderId)")  // Show sender's ID
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                 */
                                
                                Spacer()
                                
                                Text(user.notification.timestamp.dateValue(), style: .time)  // Show timestamp
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            
                            Divider() // Divider for each notification
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            
            Spacer() // Pushes content to the top
  
        }
        .onAppear{
            //viewModel.resetNotificationUsers()
            //populate notifications
            userManager.fetchNotifications()
            isLoading = true
            viewModel.populateNotificationUsers()  // Fetch users when view appears
            isLoading = false
            markNotificationsAsRead()
            userManager.fetchNotifications()// Re-fetch notifications to ensure the read status is reflected
        }
    }


    
    // Function to mark all notifications as read
    private func markNotificationsAsRead() {
        //print ("Marking notifications as read")
        // Check if the currentUser exists and if there are notifications
        guard let currentUser = userManager.currentUser else { return }
        
        // Get the notifications from currentUser
        var notifications = currentUser.notifications // Make sure you work with a mutable array

        // Loop through each notification and update its isRead property
        for i in 0..<notifications.count {
            var notification = notifications[i] // Create a mutable copy of the notification
            // Check if notification is unread
            if !notification.isRead {
                // Set isRead to true
                notification.isRead = true
                self.userManager.hasUnreadNotifications = false
                // Update Firestore
                updateNotificationStatus(notification)
                
                // Update the notification in the array
                notifications[i] = notification
            }
        }
    }
    
    // Helper function to update the notification as read in Firestore
    private func updateNotificationAccepted(_ notificationUser: NotificationUser) {
        guard let currentUser = userManager.currentUser else { return }
        
        let db = FirebaseManager.shared.firestore
        let notificationsRef = db.collection("notifications")
        
        // Find the notification by its timestamp and receiverId
        notificationsRef
            .whereField("timestamp", isEqualTo: notificationUser.notification.timestamp)
            .whereField("receiverId", isEqualTo: currentUser.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    return
                }
                
                // If the notification exists, update the isRead field
                if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "status": "accepted",
                        "message": "You and \(notificationUser.name) are now friends",
                        "timestamp": Timestamp()
                    ]) { error in
                        if let error = error {
                            print("Error updating notification: \(error.localizedDescription)")
                        } else {
                            print("Notification marked as read")
                        }
                    }
                }
            }
    }
    
    // Helper function to update the notification as read in Firestore
    private func updateNotificationStatus(_ notification: Notification) {
        guard let currentUser = userManager.currentUser else { return }
        
        let db = FirebaseManager.shared.firestore
        let notificationsRef = db.collection("notifications")
        
        // Find the notification by its timestamp and receiverId
        notificationsRef
            .whereField("timestamp", isEqualTo: notification.timestamp)
            .whereField("receiverId", isEqualTo: currentUser.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    return
                }
                
                // If the notification exists, update the isRead field
                if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "isRead": true
                    ]) { error in
                        if let error = error {
                            print("Error updating notification: \(error.localizedDescription)")
                        } else {
                            print("Notification marked as read")
                        }
                    }
                }
            }
    }
    
    private func acceptFriendRequest(requestId: String, receiverId: String, senderId: String) {
        // Step 1: Update the request status to "accepted"
        let requestRef = db.collection("friendRequests").document(requestId)
        requestRef.updateData([
            "status": "accepted"
        ]) { error in
            if let error = error {
                print("Error updating request status: \(error.localizedDescription)")
                return
            }
            print("Friend request accepted successfully!")

            // Step 2: Add sender and receiver to each other's friends list
            
            // Add senderId to receiver's friends list (if the document exists, update it; if not, create it)
            let receiverRef = db.collection("friends").document(receiverId)
            receiverRef.getDocument { document, error in
                if let error = error {
                    print("Error checking receiver's friends document: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    // Document exists, update the friends list
                    receiverRef.updateData([
                        "friends": FieldValue.arrayUnion([senderId])
                    ]) { error in
                        if let error = error {
                            print("Error adding sender to receiver's friends list: \(error.localizedDescription)")
                        } else {
                            print("Sender added to receiver's friends list.")
                        }
                    }
                } else {
                    // Document does not exist, create it with senderId as the first friend
                    receiverRef.setData([
                        "friends": [senderId]
                    ]) { error in
                        if let error = error {
                            print("Error creating receiver's friends list: \(error.localizedDescription)")
                        } else {
                            print("Receiver's friends list created with sender.")
                        }
                    }
                }
            }

            // Add receiverId to sender's friends list (same logic as above)
            let senderRef = db.collection("friends").document(senderId)
            senderRef.getDocument { document, error in
                if let error = error {
                    print("Error checking sender's friends document: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    // Document exists, update the friends list
                    senderRef.updateData([
                        "friends": FieldValue.arrayUnion([receiverId])
                    ]) { error in
                        if let error = error {
                            print("Error adding receiver to sender's friends list: \(error.localizedDescription)")
                        } else {
                            print("Receiver added to sender's friends list.")
                        }
                    }
                } else {
                    // Document does not exist, create it with receiverId as the first friend
                    senderRef.setData([
                        "friends": [receiverId]
                    ]) { error in
                        if let error = error {
                            print("Error creating sender's friends list: \(error.localizedDescription)")
                        } else {
                            print("Sender's friends list created with receiver.")
                        }
                    }
                }
            }
        }
    }

    
    
    //The user who sent the friend request should be notified it was accepted
    private func sendNotificationToAcceptedUser(receiverId: String, senderId: String, completion: @escaping (Bool, Error?) -> Void) {
        userManager.sendRequestAcceptedNotification(to: receiverId, senderId: senderId) { success, error in
            if success {
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
}


/*struct NotificationView_Preview: PreviewProvider
    {
    static var previews: some View
        {
        NotificationView()
        }
    }
*/

// ViewModel to manage notification users
class NotificationViewModel: ObservableObject {
    @Published var notificationUsers: [NotificationUser] = []
    private var userManager: UserManager  // Store userManager
    
    // Custom initializer to inject userManager
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func resetNotificationUsers() {
        self.notificationUsers = [] // Reset the list
    }
    
    func populateNotificationUsers() {
        resetNotificationUsers()
        //print("After resetting notification users count:  \(notificationUsers.count)")
        if let notifications = userManager.currentUser?.notifications {
            NotificationManager.shared.populateNotificationUsers(notifications: notifications) { result in
                switch result {
                case .success(let notificationUsers):
                    self.notificationUsers = notificationUsers
                    //print("Fetched \(notificationUsers.count) notification users")
                case .failure(let error):
                    print("Failed to fetch notification users: \(error.localizedDescription)")
                }
            }
        }
        
    }
}