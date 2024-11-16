//
//  UserManager.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-21.
//

import SwiftUI
import Combine
import Firebase

class UserManager: ObservableObject {
    @Published public var currentUser: User? {
        didSet {
            // Call fetchNotifications only if currentUser is not nil
            if let user = currentUser {
                // Fetch notifications for the current user
               // fetchNotifications()
            } else {
                // Handle case when user is nil (i.e., signed out)
                print("User is nil, skipping notifications fetch.")
            }
        }
    }
    @Published var hasUnreadNotifications: Bool = false // Flag for unread notifications
    private let db = Firestore.firestore()
    

    init() {
        fetchCurrentUser()
    }

    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Could not find Firebase UID")
            return
        }

        FirebaseManager.shared.firestore.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Failed to fetch current user: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data() else {
                    print("No data found")
                    return
                }

                DispatchQueue.main.async {
                    self?.currentUser = User(data: data, uid: uid)
                    if let currentUser = self?.currentUser {
                        print("User Manager - Fetched User: \(currentUser.name)")
                        //self?.fetchNotifications()
                        
                        self?.fetchNotifications {result in
                            switch result {
                            case .success(let notifications):
                                print("Fetched \(notifications.count) notifications successfully.")

                            case .failure(let error):
                                print("Error fetching notifications: \(error.localizedDescription)")
                                // Handle the error, e.g., show an alert or log the issue
                            }
                        }
                    } else {
                        print("User Manager - Failed to initialize current user.")
                    }
                }
            }
    }
    
    func checkFriendshipStatus() {
        // Implement logic to check friendship status
        print("checkFriendshipStatus called")
    }


    private func updateUserInFirestore(_ user: User) {
        print ("in updateUserInFirestore")
        let userData: [String: Any] = [
            "uid": user.uid,
            "name": user.name,
            "username": user.username,
            "email": user.email,
            "bio": user.bio,
            "profileImageUrl": user.profileImageUrl ?? ""
        ]
        print ("UID: \(user.uid)")
        FirebaseManager.shared.firestore.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("Failed to update user in Firestore: \(error.localizedDescription)")
            } else {
                print("User successfully updated in Firestore.")
            }
        }
    }
    
    func setCurrentUser_name(newName: String) {
        print ("in setCurrentUser_name")
        if let username = currentUser?.username
            {
            if let bio = currentUser?.bio {
                updateCurrentUserFields (newName: newName, newUsername: username, newBio: bio)
            }
            }
        
        else {}
    }
    
    func setCurrentUser_username(newUsername: String) {
        if let name = currentUser?.name
            {
            if let bio = currentUser?.bio {
                updateCurrentUserFields (newName: name, newUsername: newUsername, newBio: bio)
            }
            }
        
        else {}
    }
    
    func setCurrentUser_bio (newBio: String) {
        if let name = currentUser?.name
            {
            if let username = currentUser?.username{
                updateCurrentUserFields (newName: name, newUsername: username, newBio: newBio)
            }
            }
        
        else {}
    }
    
    func updateCurrentUserFields (newName: String, newUsername: String, newBio: String)
    {
        print ("in updateCurrentUserFields: newName: \(newName)")
        // Check if currentUser is not nil
        guard var user = currentUser else {
            print("Current user is not set.")
            return
        }
        
        if let uid = currentUser?.uid{
            // Update the user's name
            user = User(data: [
                "name": newName,
                "username": newUsername,
                "email": user.email,
                "bio": newBio,
                "profileImageUrl": user.profileImageUrl ?? ""
            ], uid: uid)
        }
        // Assign the updated user back to currentUser
        self.currentUser = user
        
        // Optionally, you might want to update the user in Firestore as well
        updateUserInFirestore(user)
    }
    //-----------------------------------------------------------------------------------------------------------
    // Function to send a friend request
    func sendFriendRequest(to receiverId: String, completion: @escaping (Bool, Error?) -> Void) {
        // Get the current user's ID (sender)
        guard let senderId = FirebaseManager.shared.auth.currentUser?.uid else {
            completion(false, NSError(domain: "User not logged in", code: 401, userInfo: nil))
            return
        }

        // Prepare the friend request data
        let friendRequestData: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId,
            "status": "pending",  // Initially set to "pending"
            "timestamp": Timestamp()  // Current timestamp
        ]
        
        // Use senderId_receiverId as the document ID to ensure unique identification of the request
        let friendRequestDocId = "\(senderId)_\(receiverId)"

        // Add the friend request to the friendRequests collection
        db.collection("friendRequests").document(friendRequestDocId).setData(friendRequestData){ error in
            if let error = error {
                completion(false, error)
            } else {
                // If friend request is successfully sent, send notification
                self.sendNotification(to: receiverId, senderId: senderId) { success, error in
                    if success {
                        completion(true, nil)
                    } else {
                        completion(false, error)
                    }
                }
            }
        }
    }
    
    //sends friend request to user
    func sendNotification(to receiverId: String, senderId: String, completion: @escaping (Bool, Error?) -> Void) {
        if let name = currentUser?.name, let username = currentUser?.username{
            let notificationData: [String: Any] = [
                "type": "friendRequest",
                "senderId": senderId,
                "receiverId": receiverId,
                "message": "sent you a friend request.",
                "timestamp": Timestamp(),
                "isRead": false, // Initially unread,
                "status": "pending",
                "post_id": ""
            ]
            
            // Add notification to the notifications collection
            db.collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    //sends notification to user that their request was accepted
    func sendRequestAcceptedNotification(to receiverId: String, senderId: String, completion: @escaping (Bool, Error?) -> Void) {
        if let name = currentUser?.name, let username = currentUser?.username{
            let notificationData: [String: Any] = [
                "type": "friendRequest",
                "senderId": senderId,
                "receiverId": receiverId,
                "message": "accepted your friend request.",
                "timestamp": Timestamp(),
                "isRead": false, // Initially unread
                "status": "accepted",
                "post_id": ""
            ]
            
            // Add notification to the notifications collection
            db.collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    /*
    func fetchNotifications() {
        print ("Calling fetchNotifications")
        if let receiver_uid = currentUser?.uid {
            print ("fetching notifications for receiver \(receiver_uid)")
            FirebaseManager.shared.firestore.collection("notifications")
                .whereField("receiverId", isEqualTo: receiver_uid)  // Get notifications for this user
                .order(by: "timestamp", descending: true)  // Order by timestamp, descending (most recent first)
                .getDocuments(completion: { snapshot, error in
                    if let error = error {
                        print("Failed to fetch notifications: \(error.localizedDescription)")
                        return
                    }
                    
                    // Check if the snapshot has documents
                    if let documents = snapshot?.documents, documents.isEmpty {
                        print("No notifications found.")
                        return  // Exit early if no notifications are found
                    }

                    // Parse the notifications into an array
                    var notifications: [Notification] = []
                    snapshot?.documents.forEach { document in
                        let data = document.data()

                        if let receiverId = data["receiverId"] as? String,
                           let senderId = data["senderId"] as? String,
                           let type = data["type"] as? String,
                           let post_id = data["post_id"] as? String,
                           let message = data["message"] as? String,
                           let timestamp = data["timestamp"] as? Timestamp,
                           let status = data["status"] as? String,
                           let isRead = data["isRead"] as? Bool {
                            
                           print("Notification message: \(message) with timestamp: \(timestamp.dateValue())") // Print the timestamp to confirm order
                            
                            var notification = Notification(receiverId: receiverId,
                                                            senderId: senderId,
                                                            message: message,
                                                            timestamp: timestamp,
                                                            isRead: isRead,
                                                            status: status,
                                                            type: type,
                                                            post_id: post_id)
                            notifications.append(notification)
                        }
                    }
                   
                    // Set the fetched notifications for the current user
                    self.setNotificationsForCurrentUser(newNotifications: notifications)
                    if let currentUser = self.currentUser{
                        self.hasUnreadNotifications = currentUser.notifications.contains { !$0.isRead }
                    }
                    
                })
        }
    }*/
    
    func fetchNotifications(completion: @escaping (Result<[Notification], Error>) -> Void) {
        print("Calling fetchNotifications")
        
        if let receiver_uid = currentUser?.uid {
            print("Fetching notifications for receiver \(receiver_uid)")
            
            FirebaseManager.shared.firestore.collection("notifications")
                .whereField("receiverId", isEqualTo: receiver_uid)  // Get notifications for this user
                .order(by: "timestamp", descending: true)  // Order by timestamp, descending (most recent first)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Failed to fetch notifications: \(error.localizedDescription)")
                        // Return the error via the completion handler
                        completion(.failure(error))
                        return
                    }
                    
                    // Check if the snapshot has documents
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("No notifications found.")
                        completion(.success([]))  // Return an empty array if no notifications are found
                        return
                    }
                    
                    // Parse the notifications into an array
                    var notifications: [Notification] = []
                    snapshot?.documents.forEach { document in
                        let data = document.data()
                        
                        if let receiverId = data["receiverId"] as? String,
                           let senderId = data["senderId"] as? String,
                           let type = data["type"] as? String,
                           let post_id = data["post_id"] as? String,
                           let message = data["message"] as? String,
                           let timestamp = data["timestamp"] as? Timestamp,
                           let status = data["status"] as? String,
                           let isRead = data["isRead"] as? Bool {
                            
                            print("Notification message: \(message) with timestamp: \(timestamp.dateValue())") // Print the timestamp to confirm order
                            
                            let notification = Notification(receiverId: receiverId,
                                                            senderId: senderId,
                                                            message: message,
                                                            timestamp: timestamp,
                                                            isRead: isRead,
                                                            status: status,
                                                            type: type,
                                                            post_id: post_id)
                            notifications.append(notification)
                        }
                    }
                    
                    // Set the fetched notifications for the current user
                    self.setNotificationsForCurrentUser(newNotifications: notifications)
                    
                    // Update unread notifications flag
                    if let currentUser = self.currentUser {
                        self.hasUnreadNotifications = currentUser.notifications.contains { !$0.isRead }
                    }
                    
                    // Return the notifications array via the completion handler
                    completion(.success(notifications))
                }
        }
    }

    
    // Manually update the notifications for the current user
    func setNotificationsForCurrentUser2(newNotifications: [Notification]) {
        currentUser?.notifications = newNotifications
        print ("Setting notifications size: \(currentUser?.notifications.count)")
    }
    
    // Function to update the notifications for the current user using timestamp as unique identifier
    func setNotificationsForCurrentUser(newNotifications: [Notification]) {
        print ("After fetchUserFromFireStore")
        currentUser?.notifications = []
        // Assuming each Notification has a unique timestamp
        for newNotification in newNotifications {
            currentUser?.notifications.append(newNotification)
        }
        
        for newNotification in newNotifications {
            // Print the updated size of the notifications array
            print("SettingNotificationsForCurrentUser: \(newNotification.message)")
        }
        
    }
    
    func sendLikeNotification(likerId: String, post: Post, completion: @escaping (Bool, Error?) -> Void) {
        // Check if the post belongs to the current user and if the liker is not the post's author
        if post.uid != likerId {
            // Create a message for the notification
            let message = "liked your post!"
            
            // Create a timestamp for the notification
            let timestamp = Timestamp(date: Date())
            
            // Create a Notification object
            let notification = Notification(
                receiverId: post.uid,
                senderId: likerId,
                message: message,
                timestamp: timestamp,
                isRead: false,
                status: "Like",
                type: "Like",
                post_id: post.id
            )
            
            
            saveNotificationToFirestore(notification) { success, error in
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    func sendCommentNotification(commenterId: String, post: Post, commentMessage: String, completion: @escaping (Bool, Error?) -> Void) {
        // Check if the post belongs to the current user and if the commenter is not the post's author
        if post.uid != commenterId {
            // Create a message for the notification
            let message = "commented on your post: \(commentMessage)"
            
            // Create a timestamp for the notification
            let timestamp = Timestamp(date: Date())
            
            // Create a Notification object for the comment
            let notification = Notification(
                receiverId: post.uid,
                senderId: commenterId,
                message: message,
                timestamp: timestamp,
                isRead: false,
                status: "Comment",
                type: "Comment",
                post_id: post.id
            )
            
            // Save the notification to Firestore
            saveNotificationToFirestore(notification) { success, error in
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
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
    
    
    func acceptFriendRequest(requestId: String, receiverId: String, senderId: String) {
        let db = Firestore.firestore()
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
    func sendNotificationToAcceptedUser(receiverId: String, senderId: String, completion: @escaping (Bool, Error?) -> Void) {
        sendRequestAcceptedNotification(to: receiverId, senderId: senderId) { success, error in
            if success {
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    // Helper function to update the notification as read in Firestore
    func updateNotificationAccepted(_ notificationUser: NotificationUser) {
        guard let currentUser = currentUser else { return }

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
    func updateNotificationAccepted(senderId: String) {
        //change "__ sent you a friend request" to "you and __ are now friends"
        guard let currentUser = currentUser else { return }

        let db = FirebaseManager.shared.firestore
        let notificationsRef = db.collection("notifications")
        
        // Find the notification by its receiverId and type (filter by "friendRequest" type)
        notificationsRef
            .whereField("senderId", isEqualTo: senderId)
            .whereField("receiverId", isEqualTo: currentUser.uid) // Filter by receiverId
            .whereField("type", isEqualTo: "friendRequest")  // Filter by type == "friendRequest"
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    return
                }
                
                // If the notification exists, update the isRead field
                if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "status": "accepted",
                        "message": "You and $NAME are now friends.", // Replace $NAME with userName or other field
                        "timestamp": Timestamp() // Optionally update timestamp
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
    
    
    /*
    func listenForNotifications() {
        guard let currentUser = currentUser else { return }
        
        // Firestore listener that listens to changes in the notifications collection
        notificationListener = FirebaseManager.shared.firestore
            .collection("notifications")
            .whereField("receiverId", isEqualTo: currentUser.uid) // Filter by receiverId (the current user's UID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening for notifications: \(error.localizedDescription)")
                    return
                }
                if let documents = snapshot?.documents {
                    // Map each document into a Notification object and update the currentUser.notifications
                    self.currentUser?.notifications = documents.map { doc in
                        Notification(from: doc) // Convert Firestore document to a Notification object
                    }
                }
            }
    }
    */

}

struct User
    {
    let uid: String
    let name: String
    let email: String
    let username: String
    let bio: String
    let profileImageUrl: String?
    
    var notifications: [Notification] = []

    // Conformance to Equatable
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.username == rhs.username &&
               lhs.bio == rhs.bio &&
               lhs.profileImageUrl == rhs.profileImageUrl
    }
    
    init(data: [String: Any], uid: String)
        {
        self.uid             = uid //change to data["uid"]
        self.name            = data["name"] as? String ?? "Unknown"
        self.username        = data["username"] as? String ?? "No Username"
        self.bio             = data ["bio"] as? String ?? ""
        self.email           = data["email"] as? String ?? "No Email"
        self.profileImageUrl = data["profileImageUrl"] as? String // Optional
        }
    }

struct Notification {
    let receiverId: String
    let senderId: String
    var message: String
    let timestamp: Timestamp
    var status: String
    var isRead: Bool
    let type: String
    let post_id: String? //Optional
    
    // Initializer that takes a Firestore document
    init(from document: QueryDocumentSnapshot) {
        let data = document.data()
        self.receiverId = data["receiverId"] as? String ?? ""
        self.senderId = data["senderId"] as? String ?? ""
        self.message = data["message"] as? String ?? "No message"
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date()) // Default to current time if not found
        self.isRead = data["isRead"] as? Bool ?? false // Default to unread
        self.status = data ["status"] as? String ?? ""
        self.type = data ["type"] as? String ?? ""
        self.post_id = data ["post_id"] as? String ?? ""
    }
    
    // Initializer to create a Notification from Firestore data
    init(receiverId: String, senderId: String, message: String, timestamp: Timestamp, isRead: Bool, status: String, type: String, post_id: String? = nil) {
        self.receiverId = receiverId
        self.senderId = senderId
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.status = status
        self.type   = type
        self.post_id = post_id // This can be nil if no post_id is passed
    }
    
    // You can add a computed property to display the time nicely
    var timeAgo: String {
        let date = timestamp.dateValue()
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date, to: now)

        // Handle years
        if let year = components.year, year > 0 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        }

        // Handle months
        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        }

        // Handle days
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        }

        // Handle hours
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }

        // Handle minutes
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }

        // Handle seconds
        if let second = components.second, second > 0 {
            return second == 1 ? "1 second ago" : "\(second) seconds ago"
        }

        // If no significant time difference
        return "Just now"
    }

}
