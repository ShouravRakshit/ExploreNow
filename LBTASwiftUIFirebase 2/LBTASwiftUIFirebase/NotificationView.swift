import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import Firebase

struct NotificationView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: NotificationViewModel
    @State private var selectedUserUID: String? = nil  // UID of the selected user
    
    @State private var isLoading = true
    let db = Firestore.firestore()
    
    // Custom initializer to pass userManager to the view model
    init(userManager: UserManager) {
        _viewModel = StateObject(wrappedValue: NotificationViewModel(userManager: userManager))
    }

    var body: some View {
        VStack {
            Spacer()
            if isLoading {
                Text("Loading...")
                    .font(.system(size: 24, weight: .bold))
            } else {
                if viewModel.notificationUsers.isEmpty {
                    Text("No notifications available.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.notificationUsers, id: \.notification.timestamp) { user in
                        VStack(alignment: .leading) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 4)
                                        .frame(width: 41, height: 41)
                                    
                                    if !user.profileImageUrl.isEmpty {
                                        WebImage(url: URL(string: user.profileImageUrl))
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle())
                                            .frame(width: 40, height: 40)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .padding()
                                            .scaledToFill()
                                            .foregroundColor(Color(.label))
                                            .frame(width: 40, height: 40)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(Circle())
                                    }
                                }

                                Text(user.full_message ?? "")
                                    .font(.subheadline)
                                    .bold()
                                    .padding(.bottom, 5)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.customPurple)
                                    .onTapGesture {
                                        // Set the selected user UID to navigate to their profile
                                        selectedUserUID = user.uid
                                    }

                                if user.notification.type == "friendRequest" {
                                    Button(action: {
                                        if user.notification.status == "pending" {
                                            // Handle Accept Friend Request Logic
                                            acceptFriendRequest(user: user)
                                        }
                                    }) {
                                        Text(user.notification.status == "pending" ? "Confirm" : "Friends")
                                            .font(.subheadline)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(user.notification.status == "pending" ? Color.purple : Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .contentShape(Rectangle())
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if user.notification.status == "pending" {
                                        Button(action: {
                                            deleteFriendRequest(notificationUser: user)
                                        }) {
                                            Text("Delete")
                                                .font(.subheadline)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.gray)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .contentShape(Rectangle())
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }

                            HStack {
                                Spacer()
                                Text(user.notification.timeAgo)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            Spacer() // Pushes content to the top

            // Conditional NavigationLink to navigate to ProfileView when selectedUserUID is set
            if let selectedUserUID = selectedUserUID {
                NavigationLink(
                    destination: ProfileView(user_uid: selectedUserUID),
                    isActive: .constant(true),
                    label: { EmptyView() }
                )
                .hidden() // Hide the NavigationLink UI but it still triggers the navigation
            }
        }
        .onAppear {
                    print("notifications view appeared")
                    isLoading = true
                    userManager.fetchNotifications { result in
                        switch result {
                        case .success(let notifications):
                            print("Fetched \(notifications.count) notifications")
                            viewModel.populateNotificationUsers(notifications: notifications)
                            isLoading = false
                            markNotificationsAsRead()
                        case .failure(let error):
                            print("Error fetching notifications: \(error.localizedDescription)")
                        }
                    }
                }
                .navigationBarTitle("Notifications", displayMode: .inline)
            }

            private func acceptFriendRequest(user: NotificationUser) {
                let senderId = user.notification.senderId
                let receiverId = user.notification.receiverId
                let requestId = "\(senderId)_\(receiverId)"

                // Update status in the model first
                if let index = viewModel.notificationUsers.firstIndex(where: { $0.uid == user.uid }) {
                    viewModel.notificationUsers[index].notification.status = "accepted"
                    viewModel.notificationUsers[index].full_message = "You and \(user.name) are now friends."
                }
                
                userManager.acceptFriendRequest(requestId: requestId, receiverId: receiverId, senderId: senderId)
                userManager.sendNotificationToAcceptedUser(receiverId: senderId, senderId: receiverId) { success, error in
                    if success {
                        print("Notification sent successfully")
                        userManager.updateNotificationAccepted(user)
                    } else {
                        print("Error sending notification: \(String(describing: error))")
                    }
                }
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
    
    func populateNotificationUsers2() {
        resetNotificationUsers()
        //print("After resetting notification users count:  \(notificationUsers.count)")
        if let notifications = userManager.currentUser?.notifications {
            NotificationManager.shared.populateNotificationUsers(notifications: notifications) { result in
                switch result {
                case .success(let notificationUsers):
                    
                    for notificationUser in notificationUsers {
                        self.notificationUsers.append(notificationUser)
                        print("populateNotificationUsers: \(notificationUser.notification.message)")
                    }
                    
                    self.notificationUsers = notificationUsers
                    self.notificationUsers.sort { $0.notification.timestamp.dateValue() > $1.notification.timestamp.dateValue() }
                    // Split the notificationUsers array into unread and rest notifications
                    self.unreadNotificationUsers = notificationUsers.filter { !$0.notification.isRead }
                    self.restNotificationUsers = notificationUsers.filter { $0.notification.isRead }
                    
                    
                    print("Notification view After sorting final:")
                    
                    
                    // Loop through each notification user and print their full_message
                    for user in notificationUsers
                        {
                        print("User Full Message: \(user.full_message ?? "No message") timestamp: \(user.notification.timestamp.dateValue())")
                        }
                case .failure(let error):
                    print("Failed to fetch notification users: \(error.localizedDescription)")
                }
            }
        }
        
    }
    
    func populateNotificationUsers(notifications: [Notification]) {
        resetNotificationUsers()
        //print("After resetting notification users count:  \(notificationUsers.count)")
        NotificationManager.shared.populateNotificationUsers(notifications: notifications) { result in
            switch result {
            case .success(let notificationUsers):
                
                for notificationUser in notificationUsers {
                    self.notificationUsers.append(notificationUser)
                    print("populateNotificationUsers: \(notificationUser.notification.message)")
                }
                
                self.notificationUsers = notificationUsers
                self.notificationUsers.sort { $0.notification.timestamp.dateValue() > $1.notification.timestamp.dateValue() }
                // Split the notificationUsers array into unread and rest notifications
                self.unreadNotificationUsers = notificationUsers.filter { !$0.notification.isRead }
                self.restNotificationUsers = notificationUsers.filter { $0.notification.isRead }
                
                
                print("Notification view After sorting final:")
                
                
                // Loop through each notification user and print their full_message
                for user in notificationUsers
                    {
                    print("User Full Message: \(user.full_message ?? "No message") timestamp: \(user.notification.timestamp.dateValue())")
                    }
            case .failure(let error):
                print("Failed to fetch notification users: \(error.localizedDescription)")
            }
        }
        
    }
    

}
