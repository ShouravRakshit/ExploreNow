//
//  UserManager.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import Combine
import Firebase

// UserManager class handles user-related data and manages the state of the current user and their notifications.
class UserManager: ObservableObject {
    
    // The currentUser property is published, allowing the UI to react to changes.
    // When the user changes (e.g., sign-in or sign-out), the didSet is triggered.
    @Published public var currentUser: User? {
        didSet {
            // Fetch notifications only if the currentUser is non-nil (i.e., a user is logged in)
            if let user = currentUser {
                // Fetch notifications for the current user
               // fetchNotifications()
            } else {
                // Handle the case when currentUser is nil (i.e., the user signed out)
                print("User is nil, skipping notifications fetch.")
            }
        }
    }
    
    // @Published property that allows SwiftUI views to automatically update whenever the value changes.
    // Tracks whether the user has unread notifications or not.
    @Published var hasUnreadNotifications: Bool = false
    // Firestore instance to interact with the Firestore database (Firebase) for fetching and updating data.
    private let db = Firestore.firestore()
    
    // Initializer: Called when an instance of UserManager is created.
    // It attempts to fetch the current user when the object is initialized.
    init() {
        fetchCurrentUser() // Calls fetchCurrentUser method to check if there's a currently authenticated user.
    }

    // Method to fetch the current user details based on the user's Firebase UID.
    // If the UID is not available (user is not authenticated), it prints an error message.
    func fetchCurrentUser() {
        // Safely unwrap the current user's UID using guard statement.
        // If the user is not logged in or UID is nil, it prints an error message and exits the function early.
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            print("Could not find Firebase UID") // Provides feedback if the UID can't be found.
            return // Exits early if the UID is nil (user is not authenticated).
        }

        // Listen for real-time changes in the 'users' collection for the document with the given UID.
        // This ensures that if there are any updates to the user document, they are automatically reflected in the app.
        FirebaseManager.shared.firestore.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                // Handle any errors that occur while trying to fetch the user document.
                if let error = error {
                    print("Failed to fetch current user: \(error.localizedDescription)") // Print an error message to the console.
                    return // Exit early if there was an error fetching the document.
                }

                // Ensure that the snapshot contains data (i.e., the user document exists).
                guard let data = snapshot?.data() else {
                    print("No data found") // If no data is found in the snapshot, print an error.
                    return // Exit if no data is returned.
                }

                // Switch to the main thread to update the UI with the fetched user data.
                DispatchQueue.main.async {
                    // Initialize the 'currentUser' property using the fetched data and the user's UID.
                    self?.currentUser = User(data: data, uid: uid)
                    // Check if the currentUser was successfully initialized.
                    if let currentUser = self?.currentUser {
                        // Log the user's name to confirm successful retrieval.
                        print("User Manager - Fetched User: \(currentUser.name)")
                        //self?.fetchNotifications()
                        
                        // Fetch notifications for the current user. The method is called asynchronously.
                        self?.fetchNotifications {result in
                            // Handle the result of the notifications fetch operation.
                            switch result {
                            case .success(let notifications):
                                // If successful, print the number of notifications fetched.
                                print("Fetched \(notifications.count) notifications successfully.")

                            case .failure(let error):
                                // If there was an error fetching notifications, print the error.
                                print("Error fetching notifications: \(error.localizedDescription)")
                                // Handle the error, e.g., show an alert or log the issue
                            }
                        }
                    } else {
                        // If the currentUser was not initialized, print a failure message.
                        print("User Manager - Failed to initialize current user.")
                    }
                }
            }
    }
    
    func checkFriendshipStatus() {
        // print checkFriendshipStatus
        print("checkFriendshipStatus called")
    }


    private func updateUserInFirestore(_ user: User) {
        // Log message to indicate the function has been called.
        print ("in updateUserInFirestore")
        // Create a dictionary containing the user data to be updated in Firestore.
        let userData: [String: Any] = [
            "uid": user.uid, // User's unique ID.
            "name": user.name,  // User's full name.
            "username": user.username, // User's chosen username.
            "email": user.email,  // User's email address.
            "bio": user.bio,  // User's bio or description.
            "profileImageUrl": user.profileImageUrl ?? ""  // Profile image URL (default to empty string if nil).
        ]
        // Log the UID of the user to ensure the correct user is being updated.
        print ("UID: \(user.uid)")
        // Perform the Firestore update operation on the user's document.
        FirebaseManager.shared.firestore.collection("users").document(user.uid).setData(userData) { error in
            // If there is an error while updating, print the error message.
            if let error = error {
                print("Failed to update user in Firestore: \(error.localizedDescription)")
            } else {
                // If the update is successful, log a success message.
                print("User successfully updated in Firestore.")
            }
        }
    }
    
    func setCurrentUser_name(newName: String) {
       
        print ("in setCurrentUser_name") // Logs the entry to the function for debugging purposes.
        
        // Check if the current user's username is available.
        if let username = currentUser?.username
            {
            // Check if the current user's bio is available.
            if let bio = currentUser?.bio {
                // Calls another function to update the user's name, keeping the username and bio intact.
                updateCurrentUserFields (newName: newName, newUsername: username, newBio: bio)
            }
            }
        
        else {
                // No action is performed if the username is nil.
            }
    }
    
    func setCurrentUser_username(newUsername: String) {
        // Check if the current user's name is available.
        if let name = currentUser?.name
            {
            // Check if the current user's bio is available.
            if let bio = currentUser?.bio {
                // Calls another function to update the user's username, keeping the name and bio intact.
                updateCurrentUserFields (newName: name, newUsername: newUsername, newBio: bio)
            }
            }
        
        else {
                // No action is performed if the name is nil.
            }
    }
    
    func setCurrentUser_bio (newBio: String) {
        // Check if the current user's name is available.
        if let name = currentUser?.name
            {
            // Check if the current user's username is available.
            if let username = currentUser?.username{
                // Calls another function to update the user's bio, keeping the name and username intact
                updateCurrentUserFields (newName: name, newUsername: username, newBio: newBio)
            }
            }
        
        else {
                // No action is performed if the name is nil.
            }
    }
    
    // Function to update the current user's fields (name, username, and bio)
    func updateCurrentUserFields (newName: String, newUsername: String, newBio: String)
    {
        // Logging the new name for debugging purposes
        print ("in updateCurrentUserFields: newName: \(newName)")
        // Check if currentUser is not nil; if it is, exit the function
        guard var user = currentUser else {
            // If currentUser is nil, print an error message and return
            print("Current user is not set.")
            return // Exit the function early if there's no current user
        }
        
        // If currentUser exists, proceed to update the user's data
        if let uid = currentUser?.uid{
            // Create a new User object with updated fields (new name, username, and bio)
            user = User(data: [
                "name": newName, // Set the new name
                "username": newUsername, // Set the new username
                "email": user.email, // Retain the existing email
                "bio": newBio, // Set the new bio
                "profileImageUrl": user.profileImageUrl ?? ""  // Retain the existing profile image URL, or set an empty string if nil
            ], uid: uid) // Initialize a new User object with the updated data and the existing UID
        }
        // Assign the newly updated user object to the currentUser
        self.currentUser = user
        
        // Optionally, you might want to update the user in Firestore as well
        updateUserInFirestore(user)
    }
    //-----------------------------------------------------------------------------------------------------------
    // Function to send a friend request from the current user to another user
    func sendFriendRequest(to receiverId: String, completion: @escaping (Bool, Error?) -> Void) {
        // Get the current user's ID (sender)
        // The guard statement ensures the current user is logged in and their UID is available
        guard let senderId = FirebaseManager.shared.auth.currentUser?.uid else {
            // If the current user's UID is nil (i.e., they are not logged in), complete with an error
            completion(false, NSError(domain: "User not logged in", code: 401, userInfo: nil))
            return // Exit the function early if the user is not logged in
        }

        // Prepare the friend request data to be sent to Firestore
        let friendRequestData: [String: Any] = [
            "senderId": senderId, // Store the current user's UID as the sender
            "receiverId": receiverId, // Store the receiver's UID (passed into the function)
            "status": "pending",  // Initially set the status of the friend request to "pending"
            "timestamp": Timestamp()  // Store the current timestamp when the request is sent
        ]
        
        // Use senderId_receiverId as the document ID to ensure unique identification of the request
        // This creates a unique ID for each friend request by concatenating senderId and receiverId.
        // This ensures that each request is distinct, preventing duplicate requests between the same users.
        let friendRequestDocId = "\(senderId)_\(receiverId)"

        // Add the friend request to the friendRequests collection
        // This line saves the `friendRequestData` to the Firestore `friendRequests` collection.
        // The document ID is the unique `friendRequestDocId` created earlier.
        db.collection("friendRequests").document(friendRequestDocId).setData(friendRequestData){ error in
            // Check if there was an error while adding the data to Firestore
            if let error = error {
                // If there was an error, call the completion handler with `false` and pass the error.
                completion(false, error)
            } else {
                // If the data is saved successfully, send a notification to the receiver
                self.sendNotification(to: receiverId, senderId: senderId) { success, error in
                    // Check if the notification was sent successfully
                    if success {
                        // If notification is sent successfully, call the completion handler with success.
                        completion(true, nil)
                    } else {
                        // If there was an error sending the notification, call the completion handler with failure and the error.
                        completion(false, error)
                    }
                }
            }
        }
    }
    
    // Sends a notification to the user
    func sendNotification(to receiverId: String, senderId: String, completion: @escaping (Bool, Error?) -> Void) {
        // Check if the current user's name and username are available
        if let name = currentUser?.name, let username = currentUser?.username{
            // Prepare the notification data
            // This dictionary contains the notification information to be saved in Firestore.
            // It includes the type of notification, the sender and receiver IDs, a message,
            // the current timestamp, the "read" status, the request's status, and a placeholder for post ID.
            let notificationData: [String: Any] = [
                "type": "friendRequest",                     // Type of notification (friend request)
                "senderId": senderId,                       // ID of the sender (user sending the friend request)
                "receiverId": receiverId,                    // ID of the receiver (user receiving the friend request)
                "message": "sent you a friend request.",    // Notification message
                "timestamp": Timestamp(),                   // Timestamp of when the notification is sent
                "isRead": false,                            // Initially marked as unread
                "status": "pending",                        // Status of the friend request (pending)
                "post_id": ""                                // Placeholder for post_id, used in other types of notifications
            ]
            
            // Add the notification data to the Firestore "notifications" collection
            // The notification will be added as a new document in the notifications collection.
            db.collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    // If there is an error while saving the notification, call the completion handler with failure and the err
                    completion(false, error)
                } else {
                    // If the notification is successfully added, call the completion handler with success.
                    completion(true, nil)
                }
            }
        }
    }
    
    // Sends a notification to the user that their friend request was accepted
    func sendRequestAcceptedNotification(to receiverId: String, senderId: String, completion: @escaping (Bool, Error?) -> Void) {
        // Check if current user's name and username are available
        if let name = currentUser?.name, let username = currentUser?.username{
            // Prepare the notification data to be sent to Firestore
            let notificationData: [String: Any] = [
                "type": "friendRequest",                        // Type of notification (friend request)
                "senderId": senderId,                           // ID of the sender (user who accepted the request)
                "receiverId": receiverId,                       // ID of the receiver (user who made the request)
                "message": "accepted your friend request.",     // Message content for the notification
                "timestamp": Timestamp(),                        // Current timestamp for when the notification is sent
                "isRead": false, // Initially unread            // Initially mark the notification as unread
                "status": "accepted",                           // Status of the request (accepted)
                "post_id": ""                                   // Placeholder for post_id (can be used for other notification types)
            ]
            
            // Add the notification data to the Firestore "notifications" collection
            db.collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    // If there's an error in saving the notification, call the completion handler with failure and the error
                    completion(false, error)
                } else {
                    // If the notification is successfully added, call the completion handler with success
                    completion(true, nil)
                }
            }
        }
    }
    
    // Fetches notifications for the current user
    func fetchNotifications(completion: @escaping (Result<[Notification], Error>) -> Void) {
        print("Calling fetchNotifications") // Logs that the function was called to fetch notifications
        
        // Check if the current user has a valid UID (user ID)
        if let receiver_uid = currentUser?.uid {
            print("Fetching notifications for receiver \(receiver_uid)") // Logs the receiver's UID for debugging

        // Query the Firestore "notifications" collection to fetch notifications for the current user (receiver)
            FirebaseManager.shared.firestore.collection("notifications")
                .whereField("receiverId", isEqualTo: receiver_uid)  // Filters the notifications where receiverId matches the current user's UID
                .order(by: "timestamp", descending: true)           // Orders the notifications by the "timestamp" field in descending order (newest first)
                .getDocuments { snapshot, error in                  // Fetches the documents from the "notifications" collection
                    if let error = error {                          // If an error occurred during the fetch operation
                        print("Failed to fetch notifications: \(error.localizedDescription)")         // Logs the error message
                        // Returns the error via the completion handler to notify the caller of the failure
                        completion(.failure(error))
                        return                                      // Exit the function early in case of failure
                    }
                    
                    // Check if the snapshot has documents
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("No notifications found.")            // Logs a message indicating that no notifications were found
                        completion(.success([]))                     // Returns an empty array to the caller, indicating no notifications are available
                        return                                      // Exits the function early if no documents are found
                    }
                    
                    // Parse the notifications into an array
                    var notifications: [Notification] = []         // Initialize an empty array to hold the parsed notifications
                    
                    // Iterate over each document in the snapshot's documents
                    snapshot?.documents.forEach { document in
                        let data = document.data()               // Retrieve the actual data stored in the document as a dictionary
                        
                        // Safely unwrap the necessary fields from the document's data
                        if let receiverId = data["receiverId"] as? String,   // Check if receiverId is of type String
                           let senderId = data["senderId"] as? String,      // Check if senderId is of type String
                           let type = data["type"] as? String,              // Check if type is of type String
                           let post_id = data["post_id"] as? String,        // Check if post_id is of type String
                           let message = data["message"] as? String,        // Check if message is of type String
                           let timestamp = data["timestamp"] as? Timestamp, // Check if timestamp is of type Timestamp
                           let status = data["status"] as? String,          // Check if status is of type String
                           let isRead = data["isRead"] as? Bool {           // Check if isRead is of type Bool
                            
                            // Debugging output: Print the notification message and timestamp for confirmation
                            print("Notification message: \(message) with timestamp: \(timestamp.dateValue())")                  // Print the timestamp to confirm order
                            
                            // Create a new Notification object using the parsed data
                            let notification = Notification(receiverId: receiverId,      // Initialize the Notification with receiverId
                                                            senderId: senderId,         // Initialize with senderId
                                                            message: message,           // Initialize with message
                                                            timestamp: timestamp,       // Initialize with timestamp
                                                            isRead: isRead,             // Initialize with isRead status
                                                            status: status,              // Initialize with status
                                                            type: type,                 // Initialize with type
                                                            post_id: post_id)           // Initialize with post_id
                            
                            // Add the newly created notification to the notifications array
                            notifications.append(notification)                          // Append the notification to the array
                        }
                    }
                    
                    // Set the fetched notifications for the current user
                    self.setNotificationsForCurrentUser(newNotifications: notifications)
                    
                    // This calls a method `setNotificationsForCurrentUser` to update the notifications for the current user.
                    // It passes the `notifications` array (containing parsed notifications) as the parameter.

                    // Update unread notifications flag
                    if let currentUser = self.currentUser {
                        // Check if `currentUser` is available (not nil).
                        self.hasUnreadNotifications = currentUser.notifications.contains { !$0.isRead }
                           // The `contains` method is used to check if the `notifications` array of the `currentUser` contains any notifications that are not read (i.e., `isRead == false`).
                           // If such notifications exist, `hasUnreadNotifications` will be set to `true`; otherwise, it will be `false`.
                       }

                    
                    // Return the notifications array via the completion handler
                    completion(.success(notifications))
                    // Calls the completion handler with a `.success` result, passing the `notifications` array.
                    // This signals that the notification fetching operation was successful and provides the fetched notifications as the result.
                }
        }
    }

    
    // Manually update the notifications for the current user
    func setNotificationsForCurrentUser2(newNotifications: [Notification]) {
        // This function sets the notifications for the current user manually.
        // It takes an array of `Notification` objects as the parameter `newNotifications`.
        currentUser?.notifications = newNotifications
        // The `notifications` property of `currentUser` is set to the `newNotifications` array.
        // This will replace any existing notifications with the new ones.
            
        print ("Setting notifications size: \(currentUser?.notifications.count)")
        // Prints the size of the notifications array after the update.
        // The `?.` safely unwraps the `currentUser` to avoid crashes if it's nil.
    }
    
    // Function to update the notifications for the current user using timestamp as unique identifier
    func setNotificationsForCurrentUser(newNotifications: [Notification]) {
        // This function updates the notifications for the current user by iterating over the new notifications array.
        // It uses the `timestamp` as a unique identifier for the notifications.
        print ("After fetchUserFromFireStore")
        // Logs that the user has been fetched from Firestore, or the function has been called after fetching the user.
        currentUser?.notifications = []
        // Clears the existing notifications array for the current user.
        // This is important to make sure the user gets the updated list of notifications.
        // where each Notification has a unique timestamp
        for newNotification in newNotifications {
            // Iterates through each notification in the `newNotifications` array.
            // where each `Notification` has a unique timestamp.
            currentUser?.notifications.append(newNotification)
            // Appends each `newNotification` to the `notifications` array of the `currentUser`.
        }
        
        for newNotification in newNotifications {
            // Iterates through `newNotifications` again for logging purposes.
            print("SettingNotificationsForCurrentUser: \(newNotification.message)")
            // Prints the message of each notification to log the notifications being added to the current user's list.
            // This helps track what notifications are being set.
        }
        
    }
    
    func sendLikeNotification(likerId: String, post: Post, completion: @escaping (Bool, Error?) -> Void) {
        // Check if the post belongs to the current user and if the liker is not the post's author
        if post.uid != likerId {
            // Create a message for the notification
            let message = "liked your post."
            
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
            let message = "commented on your post: \"\(commentMessage)\"."
            
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
    
    func sendCommentLikeNotification(commenterId: String, post: Post, commentMessage: String, completion: @escaping (Bool, Error?) -> Void) {
        // Check if the post belongs to the current user and if the commenter is not the post's author
        if post.uid != commenterId {
            // Create a message for the notification
            let message = "liked your comment: \"\(commentMessage)\"."
            
            // Create a timestamp for the notification
            let timestamp = Timestamp(date: Date())
            
            // Create a Notification object for the comment
            let notification = Notification(
                receiverId: commenterId,
                senderId: currentUser?.uid ?? "",
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
    
    
    // Function to mark all notifications as read
    func markNotificationsAsRead() {
        //print ("Marking notifications as read")
        // Check if the currentUser exists and if there are notifications
        guard let currentUser = currentUser else { return }
        
        // Get the notifications from currentUser
        var notifications = currentUser.notifications // Make sure you work with a mutable array

        // Loop through each notification and update its isRead property
        for i in 0..<notifications.count {
            var notification = notifications[i] // Create a mutable copy of the notification
            // Check if notification is unread
            if !notification.isRead {
                // Set isRead to true
                notification.isRead = true
                self.hasUnreadNotifications = false
                // Update Firestore
                updateNotificationStatus(notification)
                
                // Update the notification in the array
                notifications[i] = notification
            }
        }
    }
    

    
    // Helper function to update the notification as read in Firestore
    private func updateNotificationStatus(_ notification: Notification) {
        guard let currentUser = currentUser else { return }
        
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
    
    func unblockUser(userId: String) {
        guard let currentUser = currentUser else { return }

        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUser.uid)
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)

        // Remove the blocked user from the current user's blocks list
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayRemove([userId])], merge: true) { error in
            if let error = error {
                print("Error unblocking user: \(error)")
            } else {
                print("User unblocked successfully.")
                //self.blocked_users.removeAll { $0.uid == userId }
                
            }
        }

        // Remove the current user from the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayRemove([currentUser.uid])], merge: true) { error in
            if let error = error {
                print("Error removing blockedBy for user: \(error)")
            }
        }
    }
    
    func blockUser(userId: String) {
        guard let currentUser = currentUser else { return }

        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUser.uid)
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)

        // Add the blocked user to the current user's blocks list
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayUnion([userId])], merge: true) { error in
            if let error = error {
                print("Error blocking user: \(error)")
            } else {
                print("User blocked successfully.")
            }
        }

        // Add the current user to the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayUnion([currentUser.uid])], merge: true) { error in
            if let error = error {
                print("Error adding blockedBy for user: \(error)")
            }
        }
    }
    
    func deleteFriendRequest(user_uid: String) {
        guard let currentUser = currentUser else { return }
        
        let db         = FirebaseManager.shared.firestore
        let senderId   = currentUser.uid
        let receiverId = user_uid
        let requestId  = "\(senderId)_\(receiverId)" // Construct the request ID

        // Reference to the friend request document
        let requestRef = db.collection("friendRequests").document(requestId)

        // Delete the friend request
        requestRef.delete { error in
            if let error = error {
                print("Error deleting friend request: \(error.localizedDescription)")
            } else {
                print("Friend request deleted successfully!")
                
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
    

}




