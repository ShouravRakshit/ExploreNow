//
//  UserManager.swift
//  ExploreNow
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
        // Function to send a "like" notification.
        // Parameters:
        // - likerId: ID of the user who liked the post.
        // - post: The post object that was liked.
        // - completion: A closure that returns a success status (Bool) and an optional error (Error?).
            
        // Check if the post belongs to the current user and if the liker is not the post's author
        if post.uid != likerId {
            // Ensures that a user cannot like their own post, avoiding unnecessary notifications.

            // Create a message for the notification
            let message = "liked your post."
            
            // Sets the notification message to inform the receiver about the "like."
            // Consider localizing the string for internationalization.

            // Create a timestamp for the notification
            let timestamp = Timestamp(date: Date())
            
            // Captures the current date and time to track when the notification was sent.

            // Create a Notification object
            let notification = Notification(
                receiverId: post.uid,               // ID of the user who will receive the notification (post owner).
                senderId: likerId,                  // ID of the user who sent the "like" notification.
                message: message,                   // The content of the notification
                timestamp: timestamp,               // The time when the notification was created.
                isRead: false,                      // Indicates that the notification is unread when first created.
                status: "Like",                     // Specifies the type of action/status associated with the notification.
                type: "Like",                       // Defines the notification type (e.g., "Like" in this case).
                post_id: post.id                    // ID of the post that the notification refers to.
            )
            
            // Save the notification object to Firestore
            saveNotificationToFirestore(notification) { success, error in
                if success {
                    completion(true, nil)
                    // If saving is successful, invoke the completion handler with success = true and no error.
                } else {
                    completion(false, error)
                    // If saving fails, invoke the completion handler with success = false and provide the error.
                }
            }
        }
    }
    
    func sendCommentNotification(commenterId: String, post: Post, commentMessage: String, completion: @escaping (Bool, Error?) -> Void) {
        // Function to send a "comment" notification.
        // Parameters:
        // - commenterId: ID of the user who commented on the post.
        // - post: The post object that was commented on.
        // - commentMessage: The actual comment content.
        // - completion: A closure that returns a success status (Bool) and an optional error (Error?).

        // Check if the post belongs to the current user and if the commenter is not the post's author
        if post.uid != commenterId {
            // Ensures that a user cannot send a comment notification to themselves.
            // Avoids unnecessary or redundant notifications.

            // Create a message for the notification
            let message = "commented on your post: \"\(commentMessage)\"."
            
            // Formats the notification message to include the comment's content for more context.
            // Further Documentation: Consider truncating the commentMessage if it is too long to prevent overly verbose notifications.

            // Create a timestamp for the notification
            let timestamp = Timestamp(date: Date())
            
            // Captures the current date and time to timestamp the notification.
            // Useful for sorting or filtering notifications by time.

            // Create a Notification object for the comment
            let notification = Notification(
                receiverId: post.uid,                   // ID of the user who will receive the notification (post owner).
                senderId: commenterId,                  // ID of the user who sent the comment notification.
                message: message,                       // The content of the notification, including the comment message.
                timestamp: timestamp,                   // The time when the notification was created.
                isRead: false,                          // Indicates that the notification is unread when first created.
                status: "Comment",                      // Specifies the type of action/status associated with the notification (Comment).
                type: "Comment",                        // Defines the notification type (e.g., "Comment" in this case).
                post_id: post.id                        // ID of the post that the notification refers to.
            )
            
            // Save the notification to Firestore
            saveNotificationToFirestore(notification) { success, error in
                if success {
                    completion(true, nil)
                    // If saving is successful, invoke the completion handler with success = true and no error.
                } else {
                    completion(false, error)
                    // If saving fails, invoke the completion handler with success = false and provide the error.
                }
            }
        }
    }
    
    func sendCommentLikeNotification(commenterId: String, post: Post, commentMessage: String, completion: @escaping (Bool, Error?) -> Void) {
        // Function to send a "like on comment" notification.
        // Parameters:
        // - commenterId: ID of the user who wrote the comment.
        // - post: The post object to which the comment belongs.
        // - commentMessage: The content of the comment that was liked.
        // - completion: A closure that returns a success status (Bool) and an optional error (Error?).

        // Check if the post belongs to the current user and if the commenter is not the post's author
        if post.uid != commenterId {
            // Ensures that the notification is only sent if the commenter is not the post owner.
            // Prevents redundant notifications to the post's author if they liked their own comment.

            // Create a message for the notification
            let message = "liked your comment: \"\(commentMessage)\"."
            
            // Formats the notification message to include the comment content for clarity.
            // Further documentation: Consider truncating `commentMessage` if it exceeds a certain length for better display.

            // Create a timestamp for the notification
            let timestamp = Timestamp(date: Date())
            
            // Captures the current date and time when the notification is created.

            // Create a Notification object for the comment
            let notification = Notification(
                receiverId: commenterId,                    // ID of the user who will receive the notification (comment's author).
                senderId: currentUser?.uid ?? "",           // ID of the user who liked the comment. Defaults to an empty string if `currentUser` is nil.
                message: message,                           // The content of the notification.
                timestamp: timestamp,                       // The time when the notification was created.
                isRead: false,                              // Indicates that the notification is unread when first created.
                status: "Comment",                          // Specifies the type of action/status associated with the notification (Comment-related).
                type: "Comment",                            // Defines the notification type (e.g., "Comment" in this case).
                post_id: post.id                            // ID of the post to which the comment belongs.
            )
            
            // Save the notification to Firestore
            saveNotificationToFirestore(notification) { success, error in
                if success {
                    completion(true, nil)
                    // If saving is successful, invoke the completion handler with success = true and no error.
                } else {
                    completion(false, error)
                    // If saving fails, invoke the completion handler with success = false and provide the error
                }
            }
        }
    }
    
    private func saveNotificationToFirestore(_ notification: Notification, completion: @escaping (Bool, Error?) -> Void) {
        // Function to save a notification object to Firestore.
        // Parameters:
        // - notification: The Notification object to be saved.
        // - completion: A closure that returns a success status (Bool) and an optional error (Error?).

        let db = Firestore.firestore()
        // Initializes a Firestore database instance to interact with the Firestore database.
        let notificationRef = db.collection("notifications").document()
        // Creates a reference to a new document in the "notifications" collection.
        // A unique document ID is automatically generated for the notification.

        // Prepare the notification data in a dictionary format for Firestore
        
        let notificationData: [String: Any] = [
            "receiverId": notification.receiverId,               // ID of the user who will receive the notification.
            "senderId": notification.senderId,                   // ID of the user who triggered the notification.
            "message": notification.message,                     // The notification message content.
            "timestamp": notification.timestamp,                 // The timestamp when the notification was created.
            "status": notification.status,                       // The status/type of the notification (e.g., "Like", "Comment").
            "isRead": notification.isRead,                       // Indicates whether the notification has been read or not.
            "type"  : notification.type,                         // Specifies the type of notification (e.g., "Like", "Comment").
            "post_id": notification.post_id ?? ""                // The ID of the related post. Defaults to an empty string if nil.
        ]
        
        // Save the notification data to Firestore
        notificationRef.setData(notificationData) { error in
            // Attempts to write the data to the Firestore document.
            if let error = error {
                completion(false, error)
                // If an error occurs during the write operation, invoke the completion handler with `false` and the error.
            } else {
                completion(true, nil)
                // If the write operation succeeds, invoke the completion handler with `true` and no error.
            }
        }
    }
    
    
    func acceptFriendRequest(requestId: String, receiverId: String, senderId: String) {
        // Step 1: Get a reference to the Firestore database
        let db = Firestore.firestore()
        // Step 2: Define a reference to the friend request document using the provided requestId
        let requestRef = db.collection("friendRequests").document(requestId)
        // Step 3: Update the status of the friend request to "accepted"
        requestRef.updateData([
            "status": "accepted"
        ]) { error in
            // Step 4: Check if there was an error while updating the request status
            if let error = error {
                // Step 5: Print error message if update fails
                print("Error updating request status: \(error.localizedDescription)")
                return
            }
            // Step 6: Print success message if the update was successful
            print("Friend request accepted successfully!")

            // Step 7: Add sender and receiver to each other's friends list

            // Step 8: Define a reference to the receiver's friends list in Firestore
            let receiverRef = db.collection("friends").document(receiverId)
            // Step 9: Retrieve the document for the receiver's friends list to check if it exists
            receiverRef.getDocument { document, error in
                // Step 10: Check for errors in fetching the document
                if let error = error {
                    // Step 11: Print error message if fetching fails
                    print("Error checking receiver's friends document: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    // Step 1: Check if the document exists in Firestore
                    // 'document' is unwrapped, and if it exists, proceed with updating the friends list
                    // This ensures that you only modify the list if the document is already available

                    // Step 2: If document exists, update the friends list by adding the senderId
                    receiverRef.updateData([
                        "friends": FieldValue.arrayUnion([senderId])   // Adds the senderId to the "friends" array
                    ]) { error in
                        // Step 3: Handle the result of the update operation
                        if let error = error {
                            // Step 4: Print error message if the update fails
                            print("Error adding sender to receiver's friends list: \(error.localizedDescription)")
                        } else {
                            // Step 5: Print success message if the sender was successfully added to the friends list
                            print("Sender added to receiver's friends list.")
                        }
                    }
                } else {
                    // Step 6: If the document does not exist, create a new friends list document with senderId
                    // In this case, it's the first time the receiver is getting a friend, so we create their friends list with the senderId as the only entry
                    receiverRef.setData([
                        "friends": [senderId]   // Initializes the friends array with the senderId
                    ]) { error in
                        // Step 7: Handle the result of the create operation
                        if let error = error {
                            // Step 8: Print error message if the document creation fails
                            print("Error creating receiver's friends list: \(error.localizedDescription)")
                        } else {
                            // Step 9: Print success message if the receiver's friends list was created successfully
                            print("Receiver's friends list created with sender.")
                        }
                    }
                }
            }

            // Add receiverId to sender's friends list (same logic as above)
            let senderRef = db.collection("friends").document(senderId)
            // This line creates a reference to the sender's friends list document in the "friends" collection of Firestore using the senderId as the document identifier.
            senderRef.getDocument { document, error in
                // This begins an asynchronous call to retrieve the sender's friends list document from Firestore. It returns the document or an error.
                if let error = error {
                    print("Error checking sender's friends document: \(error.localizedDescription)")
                    return
                }
                // If there is an error fetching the document, it prints the error message and exits the function.

                
                if let document = document, document.exists {
                    // This block checks if the document exists. If it does, we proceed to update the friends list.

                    // Document exists, update the friends list
                    senderRef.updateData([
                        "friends": FieldValue.arrayUnion([receiverId])
                    ]) { error in
                        // This updates the "friends" field of the sender's document by adding the receiverId using arrayUnion, which ensures the receiverId is added only once.
                        if let error = error {
                            print("Error adding receiver to sender's friends list: \(error.localizedDescription)")
                            // If there is an error updating the document, an error message is printed.
                        } else {
                            print("Receiver added to sender's friends list.")
                            // If the update is successful, a success message is printed.
                        }
                    }
                } else {
                    // Document does not exist, create it with receiverId as the first friend
                    senderRef.setData([
                        "friends": [receiverId]
                    ]) { error in
                        // If the sender's friends list document does not exist, this creates a new document and initializes the "friends" array with the receiverId.
                        if let error = error {
                            print("Error creating sender's friends list: \(error.localizedDescription)")
                            // If there is an error creating the document, an error message is printed.
                        } else {
                            print("Sender's friends list created with receiver.")
                            // If the document is created successfully, a success message is printed.
                        }
                    }
                }
            }
        }
    }
    
    //The user who sent the friend request should be notified it was accepted
    func sendNotificationToAcceptedUser(receiverId: String, senderId: String, completion: @escaping (Bool, Error?) -> Void) {
        // This function is responsible for sending a notification to the user who sent the friend request.
        // It uses the receiverId and senderId to identify the users involved.
        sendRequestAcceptedNotification(to: receiverId, senderId: senderId) { success, error in
            // Calls the function `sendRequestAcceptedNotification` which will send the actual notification.
            // It passes the receiverId and senderId to that function, and once the notification is sent, it receives a
            // `success` flag and an optional `error` that indicates whether the operation was successful or failed.
            if success {
                // If the notification was successfully sent, it calls the completion handler with a success result (true) and no error.
                completion(true, nil)
            } else {
                // If there was an error sending the notification, it calls the completion handler with a failure result (false) and the error.
                completion(false, error)
            }
        }
    }
    
    // Helper function to update the notification as read in Firestore
    func updateNotificationAccepted(_ notificationUser: NotificationUser) {
        // This function updates the notification to mark it as read and updates its status in Firestore.
        guard let currentUser = currentUser else { return }
        // Checks if the currentUser is available. If not, it exits the function early to prevent errors.
        let db = FirebaseManager.shared.firestore
        // Creates a reference to the Firestore database from a shared FirebaseManager instance.

        let notificationsRef = db.collection("notifications")
        
        // Creates a reference to the "notifications" collection in Firestore where the notification data is stored.

        // Find the notification by its timestamp and receiverId, and order by timestamp descending
        notificationsRef
            .whereField("receiverId", isEqualTo: currentUser.uid)
        // Filters the notifications collection to find notifications where the receiverId matches the current user's UID.

            .order(by: "timestamp", descending: true)  // Order by timestamp in descending order
        // Orders the notifications by timestamp in descending order to get the latest notifications first.
            .whereField("timestamp", isEqualTo: notificationUser.notification.timestamp)
        // Filters the notifications collection to find the notification with the same timestamp as the one in the notificationUser parameter.
            .getDocuments { snapshot, error in
                // Retrieves the documents that match the query asynchronously.
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    // If there’s an error fetching the documents, print an error message and return to exit the function.
                    return
                }
                
                // If the notification exists, update the isRead field
                if let document = snapshot?.documents.first {
                    // Checks if any documents were found and takes the first document in the snapshot.
                    document.reference.updateData([
                        "status": "accepted",
                        // Updates the "status" field of the document to "accepted".
                        "message": "You and $NAME are now friends.",
                        // Updates the "message" field to indicate that the users are now friends. `$NAME` should be dynamically replaced with the friend’s name.
                        "timestamp": Timestamp()
                        // Updates the "timestamp" field to the current time (Firestore Timestamp) to reflect when the status was updated.
                    ]) { error in
                        if let error = error {
                            print("Error updating notification: \(error.localizedDescription)")
                            // If there’s an error updating the document, print the error message.
                        } else {
                            print("Notification marked as read")
                            // If the document update is successful, print a success message indicating the notification has been marked as read.
                        }
                    }
                }
            }
    }
    
    // Helper function to update the notification as read in Firestore
    func updateNotificationAccepted(senderId: String) {
        // This function updates the status of a notification when a friend request is accepted.
        // It changes the message to indicate that the two users are now friends and marks the notification as read.

        guard let currentUser = currentUser else { return }
        // Checks if the currentUser is available. If the currentUser is nil, the function exits early.
        let db = FirebaseManager.shared.firestore
        // Gets a reference to the Firestore instance from a singleton FirebaseManager class.
        let notificationsRef = db.collection("notifications")
        // Creates a reference to the "notifications" collection where the notifications are stored in Firestore.

        // Find the notification by its senderId, receiverId, and type (filter by "friendRequest" type)
        
        notificationsRef
            .whereField("senderId", isEqualTo: senderId)
        // Filters the notifications to find those sent by the specified senderId.

            .whereField("receiverId", isEqualTo: currentUser.uid)
        // Filters the notifications to find those received by the current user.

            .whereField("type", isEqualTo: "friendRequest")
        // Filters the notifications to only consider those with a type of "friendRequest".
            .getDocuments { snapshot, error in
                // Executes the query to get the matching notifications asynchronously.
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    // If there’s an error while fetching the documents, prints an error message and returns from the function
                    return
                }
                
                // If the notification exists, update the status and message
                if let document = snapshot?.documents.first {
                    // If a matching notification document is found, take the first document from the snapshot.
                    document.reference.updateData([
                        "status": "accepted",
                        // Updates the "status" field of the document to "accepted", indicating the friend request was accepted.
                        "message": "You and $NAME are now friends.", // Replace $NAME with userName or other field
                        // Updates the "message" field with a message indicating the users are now friends. $NAME is a placeholder
                        // that should be dynamically replaced with the name of the user.

                        "timestamp": Timestamp() // Optionally update timestamp
                        // Optionally updates the "timestamp" field to the current timestamp (indicating when the status was updated).
                    ]) { error in
                        if let error = error {
                            print("Error updating notification: \(error.localizedDescription)")
                            // If there’s an error while updating the document, print an error message.
                        } else {
                            print("Notification marked as read")
                            // If the document update is successful, print a success message.
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
        // This function updates a notification’s "isRead" status in Firestore when it's marked as read.
        // It searches for the notification based on its timestamp and receiverId, then updates its status.
        guard let currentUser = currentUser else { return }
        // Checks if the currentUser is available. If it's nil, the function returns early to prevent further execution.
        
        let db = FirebaseManager.shared.firestore
        // Accesses the Firestore instance via the shared FirebaseManager singleton.
        let notificationsRef = db.collection("notifications")
        
        // Creates a reference to the "notifications" collection where notification documents are stored in Firestore.

        // Find the notification by its timestamp and receiverId
        notificationsRef
            .whereField("timestamp", isEqualTo: notification.timestamp)
        // Filters the notifications to match the provided `timestamp` field of the notification.
            .whereField("receiverId", isEqualTo: currentUser.uid)
        // Filters the notifications to find those where the `receiverId` matches the current user's ID.
            .getDocuments { snapshot, error in
                // Executes the query to retrieve matching documents asynchronously.
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    // If there’s an error while fetching the documents, prints an error message and returns early.
                    return
                }
                
                // If the notification exists, update the isRead field
                if let document = snapshot?.documents.first {
                    // If a matching document is found in the snapshot, get the first document.
                    document.reference.updateData([
                        "isRead": true
                    ]) { error in
                        // Updates the "isRead" field to true, marking the notification as read.
                        if let error = error {
                            print("Error updating notification: \(error.localizedDescription)")
                            // If there’s an error while updating the document, prints an error message.
                        } else {
                            print("Notification marked as read")
                            // If the update is successful, prints a success message.
                        }
                    }
                }
            }
    }
    
    func unblockUser(userId: String) {
        // This function unblocks a user by removing them from the current user's block list and the blocked user's "blockedBy" list.
        guard let currentUser = currentUser else { return }
        // Checks if there is a valid `currentUser` (the user attempting to unblock). If there isn't, the function exits early.
        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUser.uid)
        // Creates a reference to the "blocks" collection in Firestore for the current user. This points to the user's block list by using their unique `uid`.
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)
        // Creates a reference to the "blocks" collection in Firestore for the blocked user, using their `userId`.

        // Remove the blocked user from the current user's blocks list
        
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayRemove([userId])], merge: true) { error in
            // Uses `setData` to modify the current user's block list by removing the `userId` from the "blockedUserIds" array.
            // `merge: true` ensures that other data in the document remains intact while updating the "blockedUserIds" field.
            if let error = error {
                // If an error occurs during the operation, this block of code handles it by printing the error message.
                print("Error unblocking user: \(error)")
            } else {
                // If no error occurs, this block executes, indicating the unblock was successful.
                print("User unblocked successfully.")
                // Optionally, the blocked user could be removed from an in-memory list (e.g., `blocked_users`) using:
                // self.blocked_users.removeAll { $0.uid == userId }

                
            }
        }

        // Remove the current user from the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayRemove([currentUser.uid])], merge: true) { error in
            // Similar to the previous operation, this removes the current user's `uid` from the "blockedByIds" array of the blocked user's document.
            // It ensures that the "blockedByIds" field of the blocked user is updated accordingly.

            if let error = error {
                // If an error occurs during this operation, the error is printed.
                print("Error removing blockedBy for user: \(error)")
            }
        }
    }
    
    func blockUser(userId: String) {
        // This function blocks a user by adding the user's ID to the current user's block list and adding the current user's ID to the blocked user's "blockedBy" list.
        guard let currentUser = currentUser else { return }
        // Checks if there is a valid `currentUser` (the user attempting to block). If not, the function exits early.

        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUser.uid)
        // Creates a reference to the current user's block list in Firestore by using their unique `uid`. The document corresponds to the current user.
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)
        // Creates a reference to the blocked user's block list in Firestore by using the provided `userId`. This points to the document for the blocked user.

        // Add the blocked user to the current user's blocks list

        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayUnion([userId])], merge: true) { error in
            // Uses `setData` to modify the current user's block list by adding the `userId` to the "blockedUserIds" array using `FieldValue.arrayUnion`,
            // which ensures that the `userId` is added only once, even if it appears multiple times.
            // `merge: true` ensures that other data in the document remains intact while updating the "blockedUserIds" field.
            if let error = error {
                // If an error occurs during this operation, this block of code handles it by printing the error message.
                print("Error blocking user: \(error)")
            } else {
                // If no error occurs, this block executes, indicating the block was successful.
                print("User blocked successfully.")
            }
        }

        // Add the current user to the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayUnion([currentUser.uid])], merge: true) { error in
            // Similar to the previous operation, this line adds the current user's `uid` to the "blockedByIds" array of the blocked user's document.
            // It uses `FieldValue.arrayUnion` to ensure that the current user is added only once.
            // `merge: true` ensures that only the "blockedByIds" field is modified without affecting other fields in the document.
            if let error = error {
                // If an error occurs during this operation, the error is printed.
                print("Error adding blockedBy for user: \(error)")
            }
        }
    }
    
    func deleteFriendRequest(user_uid: String) {
        // This function deletes a friend request between the current user and the user specified by `user_uid`.
        guard let currentUser = currentUser else { return }
        // Checks if there is a valid `currentUser` object (the user attempting to delete the friend request). If not, the function exits early.
        
        let db         = FirebaseManager.shared.firestore
        // Creates a reference to the Firestore instance, using a shared instance of the `FirebaseManager` class to access the Firestore database.
        let senderId   = currentUser.uid
        // The `senderId` is the UID of the current user, which will be used to identify who sent the friend request.
        let receiverId = user_uid
        // The `receiverId` is the `user_uid` passed to the function, representing the user who received the friend request.

        let requestId  = "\(senderId)_\(receiverId)" // Construct the request ID

        // Constructs a unique request ID by combining the sender's and receiver's UIDs into a single string, separated by an underscore. This ensures that the request ID is unique to the two users involved.

        // Reference to the friend request document
        let requestRef = db.collection("friendRequests").document(requestId)

        // Creates a reference to the specific friend request document in the Firestore "friendRequests" collection using the `requestId`.

        // Delete the friend request
        requestRef.delete { error in
            // Deletes the document at the `requestRef` reference, which corresponds to the specific friend request.
            if let error = error {
                // If an error occurs during the deletion, this block is executed.
                print("Error deleting friend request: \(error.localizedDescription)")
                // Prints the error message to the console for debugging purposes
            } else {
                // If the deletion is successful, this block is executed.
                print("Friend request deleted successfully!")
                // Prints a success message to the console.
                
            }
        }
    }
    
    // Remove a friend from both users' friend lists
    func removeFriend(currentUserUID: String, _ friend_uid: String) {
        // This function removes a friend from both the current user's and the friend's friend list in Firestore.
        let db = Firestore.firestore()
        // Creates a reference to the Firestore instance to interact with the database.
        let currentUserRef = db.collection("friends").document(currentUserUID)
        // Creates a reference to the current user's document in the "friends" collection using the current user's UID.
        let friendUserRef = db.collection("friends").document(friend_uid)
        // Creates a reference to the friend's document in the "friends" collection using the friend's UID.

        // Fetch the current user's friend list and the friend's list
        
        db.runTransaction { (transaction, errorPointer) -> Any? in
            // Runs a Firestore transaction to atomically fetch and modify both users' friend lists to ensure consistency.
            do {
                // Fetch current user's friend list
                let currentUserDoc = try transaction.getDocument(currentUserRef)
                // Retrieves the current user's document from Firestore within the transaction.
                
                guard let currentUserFriends = currentUserDoc.data()?["friends"] as? [String] else {
                              // Attempts to retrieve the current user's friend list, expected to be an array of strings (friend IDs).
                              return nil
                          }
                          
                
                // Fetch the friend's friend list
                let friendUserDoc = try transaction.getDocument(friendUserRef)
                // Retrieves the friend's document from Firestore within the transaction.
                guard let friendUserFriends = friendUserDoc.data()?["friends"] as? [String] else {
                    // Attempts to retrieve the friend's friend list, expected to be an array of strings (friend IDs).
                    return nil
                }
                
                // Remove friend from both lists
                var updatedCurrentUserFriends = currentUserFriends
                // Creates a mutable copy of the current user's friend list for modification.
                var updatedFriendUserFriends = friendUserFriends
                // Creates a mutable copy of the friend's friend list for modification.
                // Remove each other from the respective lists
                updatedCurrentUserFriends.removeAll { $0 == friend_uid }
                // Removes the friend's UID from the current user's friend list if it exists.
                updatedFriendUserFriends.removeAll { $0 == currentUserUID }
                // Removes the current user's UID from the friend's friend list if it exists.
                            
                // Commit the changes
                transaction.updateData(["friends": updatedCurrentUserFriends], forDocument: currentUserRef)
                // Updates the current user's friend list with the modified list that no longer includes the friend.
                transaction.updateData(["friends": updatedFriendUserFriends], forDocument: friendUserRef)
                // Updates the friend's friend list with the modified list that no longer includes the current user.
                
            } catch {
                // If any error occurs during the transaction (e.g., failure to retrieve or update the documents), handle it here.
                print("Error during transaction: \(error)")
                // Logs the error message to the console, providing information about the failure that occurred during the transaction.
                errorPointer?.pointee = error as NSError
                // Assigns the caught error (converted to NSError) to the error pointer, which is used for handling errors in the transaction block.
                // This makes the error available outside of the catch block, if needed.

                return nil
                // Exits the transaction early and returns nil if an error occurred, preventing further execution of the transaction block.
                // The return value of nil indicates that the transaction could not complete successfully.
            }
            return nil
            // The return statement is executed if the transaction completes successfully (i.e., there is no error), but the function still returns nil.
            // further documentation: It may be redundant as the earlier return statement in the catch block already handles early exits.

        } completion: { (result, error) in
            // Completion handler for the transaction, executed after the transaction is finished.
            // This block is called whether the transaction succeeds or fails, and it receives two parameters:
            // `result` (the result of the transaction) and `error` (any error that occurred during the transaction).
            if let error = error {
                // If an error occurs in the transaction, this block is executed.
                // Checks if an error is passed in the completion handler (indicating that the transaction failed).

                return
                // Exits the completion block early if an error occurred, effectively stopping further processing in case of failure.
                // The `return` here is used to skip over any success-related code.
            }
            
            print("Successfully removed friend!")
            // If no error occurs in the transaction, this line prints a success message to the console,
            // indicating that the operation (e.g., removing a friend) was successful.

        }
    }
    

}




