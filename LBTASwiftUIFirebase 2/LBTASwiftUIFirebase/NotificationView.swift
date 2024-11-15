import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import Firebase

struct NotificationView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: NotificationViewModel
    @State private var showingProfile = false // State to manage the full screen cover
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
                                ZStack
                                {
                                    // Circular border
                                    Circle()
                                        .stroke(Color.black, lineWidth: 4) // Black border
                                        .frame(width: 41, height: 41) // Slightly larger than the image
                                    
                                    if !user.profileImageUrl.isEmpty
                                        {
                                        WebImage(url: URL(string: user.profileImageUrl))
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle()) // Clip to circle shape
                                            .frame(width: 40, height: 40) // Set size
                                        }
                                    else
                                        {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .padding()
                                            .scaledToFill()
                                            .foregroundColor(Color(.label))
                                            .frame(width: 40, height: 40) // Set size for placeholder
                                            .background(Color.gray.opacity(0.2)) // Optional background
                                            .clipShape(Circle()) // Clip to circle shape
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
                                    /*
                                    NavigationLink(destination: PostView(post: post, likesCount: post.likesCount, liked: post.liked)) {
                                        WebImage(url: URL(string: user.post_url ?? ""))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40) // Set size
                                    }
                                    .buttonStyle(PlainButtonStyle()) */
                                    WebImage(url: URL(string: user.post_url ?? ""))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40) // Set size
                                }
                                }
                            }
                            HStack
                                {
                                /*
                                Text("From: \(user.notification.senderId)")  // Show sender's ID
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                 */
                                
                                Spacer()
                                
                                Text(user.notification.timeAgo)  // Show timestamp
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                }
                            
                            //Divider() // Divider for each notification
                        }
                        //.padding(.vertical, 5)
                    }
                }
            }
            
            Spacer() // Pushes content to the top
  
        }
        .onAppear
            {
            //viewModel.resetNotificationUsers()
            //populate notifications
            isLoading = true
            userManager.fetchNotifications()
            viewModel.populateNotificationUsers()  // Fetch users when view appears
            isLoading = false

            markNotificationsAsRead()
            userManager.fetchNotifications()
            }
        .onDisappear(){
            userManager.fetchNotifications() // Re-fetch notifications to ensure the read status is reflected
        }
        .navigationBarTitle("Notifications", displayMode: .inline)
        
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
        
        // Find the notification by its timestamp and receiverId and order by timestamp descending
        notificationsRef
            .whereField("receiverId", isEqualTo: currentUser.uid)
            .order(by: "timestamp", descending: true)  // Order by timestamp in descending order
            .whereField("timestamp", isEqualTo: notificationUser.notification.timestamp)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    return
                }
                
                // If the notification exists, update the isRead field
                if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "status": "accepted",
                        "message": "You and $NAME are now friends.",
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
    

    
    private func saveNotificationToFirestore(_ notification: Notification, completion: @escaping (Bool, Error?) -> Void) {
        let db = Firestore.firestore()
        let notificationRef = db.collection("notifications").document()
        
        let notificationData: [String: Any] = [
            "receiverId": notification.receiverId,
            "senderId": notification.senderId,
            "message": notification.message,
            "timestamp": notification.timestamp,
            "status": notification.status,
            "isRead": notification.isRead,
            "type"  : notification.type,
            "post_id": notification.post_id ?? ""
        ]
        
        notificationRef.setData(notificationData) { error in
            if let error = error {
                completion(false, error)
            } else {
                completion(true, nil)
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
    @Published var notificationUsers      : [NotificationUser] = []
    @Published var unreadNotificationUsers: [NotificationUser] = []
    @Published var restNotificationUsers  : [NotificationUser] = []
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
                    self.notificationUsers.sort { $0.notification.timestamp.dateValue() > $1.notification.timestamp.dateValue() }
                    // Split the notificationUsers array into unread and rest notifications
                    self.unreadNotificationUsers = notificationUsers.filter { !$0.notification.isRead }
                    self.restNotificationUsers = notificationUsers.filter { $0.notification.isRead }
                    
                    
                    print("After sorting:")
                    
                    // Loop through each notification user and print their full_message
                    for user in notificationUsers {
                        print("User Full Message: \(user.full_message ?? "No message") timestamp: \(user.notification.timestamp.dateValue())")
                    }
                case .failure(let error):
                    print("Failed to fetch notification users: \(error.localizedDescription)")
                }
            }
        }
        
    }
    

}
