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

    func fetchCurrentUser()
        {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Could not find Firebase UID")
            return
        }

        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("No data found")
                return
            }

            // Initialize the User object
            DispatchQueue.main.async
                {
                self.currentUser = User(data: data, uid: uid)
                if let currentUser = self.currentUser {
                       print("User Manager - Fetched User: \(currentUser.name)")
                        self.fetchNotifications()
                   } else {
                       print("User Manager - Failed to initialize current user.")
                   }
                }
            }
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
                "message": "\(name) (@\(username)) sent you a friend request.",
                "timestamp": Timestamp(),
                "isRead": false, // Initially unread,
                "status": "pending"
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
                "message": "\(name) (@\(username)) accepted your friend request.",
                "timestamp": Timestamp(),
                "isRead": false, // Initially unread
                "status": "accepted"
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
                           let message = data["message"] as? String,
                           let timestamp = data["timestamp"] as? Timestamp,
                           let status = data["status"] as? String,
                           let isRead = data["isRead"] as? Bool {
                            
                            print ("notification message: \(message)")
                            
                            let notification = Notification(receiverId: receiverId,
                                                            senderId: senderId,
                                                            message: message,
                                                            timestamp: timestamp,
                                                            isRead: isRead,
                                                            status: status)
                            notifications.append(notification)
                        }
                    }
                    
                   /* // Check if the notifications array is empty
                    if notifications.isEmpty {
                        print("No notifications found.")  // This message will be printed if there are no notifications
                    } else {
                        print("Found \(notifications.count) notifications.")  // This message will print how many notifications were found
                    }*/
                    
                    // Set the fetched notifications for the current user
                    self.setNotificationsForCurrentUser(newNotifications: notifications)
                    if let currentUser = self.currentUser{
                        self.hasUnreadNotifications = currentUser.notifications.contains { !$0.isRead }
                    }
                    
                })
        }
    }
    
    // Manually update the notifications for the current user
    func setNotificationsForCurrentUser(newNotifications: [Notification]) {
        print ("Setting notifications")
        currentUser?.notifications = newNotifications
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
    
    // Initializer that takes a Firestore document
    init(from document: QueryDocumentSnapshot) {
        let data = document.data()
        self.receiverId = data["receiverId"] as? String ?? ""
        self.senderId = data["senderId"] as? String ?? ""
        self.message = data["message"] as? String ?? "No message"
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date()) // Default to current time if not found
        self.isRead = data["isRead"] as? Bool ?? false // Default to unread
        self.status = data ["status"] as? String ?? ""
    }
    
    // Initializer to create a Notification from Firestore data
    init(receiverId: String, senderId: String, message: String, timestamp: Timestamp, isRead: Bool, status: String) {
        self.receiverId = receiverId
        self.senderId = senderId
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.status = status
    }
    
    // You can add a computed property to display the time nicely
    var timeAgo: String {
        let date = timestamp.dateValue()
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date, to: now)

        if let year = components.year, year > 0 {
            return "\(year) year(s) ago"
        }
        if let month = components.month, month > 0 {
            return "\(month) month(s) ago"
        }
        if let day = components.day, day > 0 {
            return "\(day) day(s) ago"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour) hour(s) ago"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute) minute(s) ago"
        }
        if let second = components.second, second > 0 {
            return "\(second) second(s) ago"
        }
        return "Just now"
    }

}
