
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 



import FirebaseFirestore
import Firebase
import FirebaseCore
import Combine

// NotificationUser model to represent a user fetched from Firestore
struct NotificationUser {
    let uid            : String  // Unique identifier for the user
    let name           : String  // The name of the user
    let username       : String  // The username of the user
    let profileImageUrl: String  // URL to the user's profile image
    var notification   : Notification  // The notification associated with this user
    var full_message   : String? // Optional property for the full message content
    var post_url       : String?  // Optional property for a URL to the post
    var post           : Post? // Optional property to hold the related post (if applicable)
}

// Singleton Manager to manage notification users
class NotificationManager {
    
    // Singleton instance to ensure only one instance of NotificationManager exists
    static let shared = NotificationManager() // Static constant that holds the single instance of NotificationManager.
    
    // Published variable to hold the list of notification users, observed by the UI
    @Published var notificationUsers: [NotificationUser] = [] // The array that stores NotificationUser objects. This property is marked with @Published so that any changes trigger updates in the UI.
    
    // Private init to enforce singleton usage, preventing instantiation from outside
    private init() {} // The private initializer ensures that the class cannot be instantiated outside of the class, enforcing the singleton pattern.
    
    // Fetch all notifications and populate the notification users
    func populateNotificationUsers(notifications: [Notification], completion: @escaping (Result<[NotificationUser], Error>) -> Void) {
        
        // Dispatch group to manage multiple async calls
        let group = DispatchGroup() // DispatchGroup is used to group multiple asynchronous tasks and wait for them to complete before proceeding with the next operation.
        
        // Clear the notificationUsers array to start fresh
        notificationUsers = [] // Reset the list of notification users before fetching new data.
        print ("notifications count before fetch user from firestore: \(notifications.count)") // Log the number of notifications to be processed.
        
        // Loop over each notification and fetch user data
        for notification in notifications {
            
            group.enter() // Enter the dispatch group for each async operation. This indicates that a new asynchronous task is starting.
            
            // Fetch user details from Firestore for the given UID and notification
            fetchUserFromFirestore(uid: notification.senderId, notification: notification) { [weak self] result in
                guard let self = self else { return }  // Avoid using self if it's deallocated (prevents memory leaks)
                
                var notificationUser: NotificationUser? // Declare a variable to hold the NotificationUser
                
                switch result {
                case .success(let user):
                    // If the user data is successfully fetched, create a NotificationUser object based on the fetched user data
                    notificationUser = user
                    
                    // Log the fetched user's username and message for debugging
                    print ("fetched user from firestore: \(notificationUser?.username) message: \(notificationUser?.full_message)")
                    
                    // Check if there is a post ID in the notification and if it is not empty
                    if let postId = notification.post_id, !postId.isEmpty {
                        // Fetch the post using the post ID
                        fetchPost(by: postId) { post in
                            // If the post is successfully fetched
                            if let fetchedPost = post {
                                // Handle the post here, e.g., update your UI or process the post object
                                print("Fetched Post: \(fetchedPost.description)") // Log the fetched post description
                                
                                // Assign the fetched post to the notification user
                                notificationUser?.post = fetchedPost
                                
                                // Set the post URL from the fetched post, using the first image URL if it exists
                                notificationUser?.post_url = fetchedPost.imageUrls.count > 0 ? fetchedPost.imageUrls [0] : ""
                                
                                // Append the NotificationUser with the fetched post URL to the notificationUsers array
                                if let notificationUser = notificationUser {
                                    self.notificationUsers.append(notificationUser) // Add the updated NotificationUser to the list
                                    print("Fetched User: \(user.name), Post URL: \(notificationUser.post_url)") // Log the user's name and post URL
                                }
                                
                                // Call group.leave() after both user and post fetches are done
                                group.leave() // This indicates that the asynchronous operation for fetching the user and post is complete. It's crucial for the DispatchGroup to track when the task is finished.
                                
                            } else {
                                // Handle the error (post not found or fetch failed)
                                print("Failed to fetch post.") // If the post could not be fetched (e.g., the post ID was invalid or the network request failed), log a message for debugging purposes to indicate the failure.
                                group.leave() // Even if fetching the post fails, we call group.leave() to ensure that the DispatchGroup is correctly notified. This helps prevent the DispatchGroup from getting stuck waiting for tasks that have failed or are incomplete.
                            }
                        }
                        // Fetch the post data asynchronously
                        /*self.fetchPostData(for: postId) { postUrl in
                            // Set the post_url for the NotificationUser if a URL is found
                            notificationUser?.post_url = postUrl
                            
                            // Append the NotificationUser with the fetched post URL to the list
                            if let notificationUser = notificationUser {
                                self.notificationUsers.append(notificationUser)
                                print("Fetched User: \(user.name), Post URL: \(postUrl ?? "No URL")")
                            }
                            
                            // Call group.leave() after both user and post fetches are done
                            group.leave()
                        }*/
                    } else {
                        // This message logs when a notification does not contain a post ID.
                        // It's an important debug message to confirm that the absence of a post ID is expected behavior for this notification.

                        // No postId, just append the user to the list
                        print ("no post id, appending user to list")
                        // No postId, just append the user to the list
                        if let notificationUser = notificationUser {
                            // If the notificationUser object exists, append it to the list of notificationUsers.
                            // This happens when there is no post associated with the notification, but the user data has still been fetched successfully.
                            self.notificationUsers.append(notificationUser)
                        }
                        // Leave the group even if there's no post URL to fetch
                        group.leave()
                        // This is important because even though there is no post to fetch, we must still signal that this particular task is finished.
                        // Without calling `group.leave()`, the DispatchGroup might wait forever, and `group.notify()` might never trigger.
                        
                    }
                    
                case .failure(let error):
                    // Handle the error case when fetching the user data fails.
                    print("Error fetching user: \(error.localizedDescription)")
                    // The error message provides debugging information about what went wrong during the fetching of the user.
                    // It could be related to network issues, incorrect user ID, or any other issues encountered during the async operation.
                    // Leave the group if there's an error in fetching the user
                    group.leave()
                    // Even though an error occurred, we still call `group.leave()` to ensure the DispatchGroup is notified that this task has finished (albeit unsuccessfully).
                    // Without this, the group might hang indefinitely, which could prevent other tasks from proceeding.
                }
            }
        }
        
        // Notify when all async fetches are done
        group.notify(queue: .main) {
            print ("notification user count after fetching: \(self.notificationUsers.count)")
            
            // This line logs the count of notification users after all async fetches are complete.
            // It's useful for confirming that the data has been fully fetched and processed before continuing.
                
            // Call the completion handler once all users have been fetched
            completion(.success(self.notificationUsers))
            // Once all tasks in the DispatchGroup have finished (including user and optional post fetches),
            // this callback is executed on the main queue. It provides the final list of notification users
            // to the caller, indicating the success of the operation.
            // `completion(.success(self.notificationUsers))` sends the list of successfully fetched notification users back to the caller.
        }
    }
    
    // Fetches the post URL for the current notification user
    private func fetchPostData(for postId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // Query the Firestore database for the post using the post_id
        db.collection("user_posts").document(postId).getDocument { document, error in
            if let document = document, document.exists {
                
                
                // If the document exists, proceed to fetch its data
                // Fetch the images field (assuming it's an array of strings)
                if let images = document.data()?["images"] as? [String], let firstImageUrl = images.first {
                    // If images exist in the post and the array is not empty, retrieve the first image URL
                    print ("first post in user post: \(firstImageUrl)")
                    // Return the first image URL via the completion handler
                    completion(firstImageUrl)
                } else {
                    // If there are no images in the post, return nil
                    completion(nil)
                }
            } else {
                // Handle the case where the post doesn't exist or there was an error
                print("Post with ID \(postId) does not exist or there was an error: \(error?.localizedDescription ?? "Unknown error")")
                // Return nil if the post doesn't exist or an error occurred
                completion(nil)
            }
        }
    }

    private func fetchPost(by postId: String, completion: @escaping (Post?) -> Void) {
        // The 'isLoading' flag can be uncommented to track the loading state of the post fetch operation
        // isLoading = true
        
        FirebaseManager.shared.firestore
            .collection("user_posts") // Accessing the 'user_posts' collection in Firestore
            .document(postId) // Fetch a specific post by its unique postId
            .getDocument { [weak self] documentSnapshot, error in
                guard let self = self else { return } // Ensure self is not deallocated before the completion block runs

                // Error handling: if the Firestore fetch operation fails
                if let error = error {
                    print("Error fetching post: \(error.localizedDescription)")  // Log the error message to debug or monitor issues
                    // self.isLoading = false
                    completion(nil) // Return nil to the completion handler to indicate failure in fetching the post
                    return // Exit the function as no further processing is needed due to the error
                }

                // Check if the document exists in Firestore
                guard let document = documentSnapshot, document.exists else {
                    print("Post with ID \(postId) does not exist.") // Log if the post document doesn't exist in Firestore
                    //self.isLoading = false
                    completion(nil) // Return nil since the post document was not found
                    return // Exit the function early because there is no post to process
                }

                // Fetch the data dictionary from the document
                let data = document.data() // Extract data from the Firestore document snapshot

                // Fetch the location reference from the post document
                guard let locationRef = data?["locationRef"] as? DocumentReference else {
                    print("Location reference is missing in the post data.")  // Log a message if the location reference field is missing in the document
                    //self.isLoading = false
                    completion(nil)  // Return nil because the location reference is essential but not found
                    return // Exit the function because the post data is incomplete
                }

                // Fetch location details using the location reference
                locationRef.getDocument { locationSnapshot, locationError in
                    // Check if the location data exists and if the "address" field is available
                    if let locationData = locationSnapshot?.data(),
                       let address = locationData["address"] as? String {

                        // Fetch user details from the "users" collection using the uid from the post
                        if let uid = data?["uid"] as? String {
                            // Query the "users" collection in Firestore to get user data by the uid
                            FirebaseManager.shared.firestore
                                .collection("users")
                                .document(uid)
                                .getDocument { userSnapshot, userError in
                                    // Check if the user document exists and if data is available
                                    if let userData = userSnapshot?.data() {
                                        // Create a Post object from the fetched data
                                        let post = Post(
                                            id: postId, // The post's unique identifier
                                            description: data?["description"] as? String ?? "", // Post description, default to empty if nil
                                            rating: data?["rating"] as? Int ?? 0, // Post rating, default to 0 if nil
                                            locationRef: locationRef, // Reference to the location document in Firestore
                                            locationAddress: address, // The address fetched from the location data
                                            imageUrls: data?["images"] as? [String] ?? [], // Array of image URLs associated with the post
                                            timestamp: (data?["timestamp"] as? Timestamp)?.dateValue() ?? Date(), // Post timestamp, default to the current date if nil
                                            uid: uid, // The user ID who created the post
                                            username: userData["username"] as? String ?? "User", // Username from the user data, default to "User" if not found
                                            userProfileImageUrl: userData["profileImageUrl"] as? String ?? "" // User profile image URL, default to an empty string if not found
                                        )

                                        // Return the post via the completion handler
                                        DispatchQueue.main.async {
                                            // Call the completion handler to return the fetched post
                                            //self.isLoading = false
                                            completion(post) // Return the created Post object to the caller
                                        }
                                    } else {
                                        // Handle the case where user data is not found or error occurs
                                        print("Error fetching user data for UID \(uid)")
                                        // Call the completion handler with nil to indicate failure
                                        //self.isLoading = false
                                        completion(nil)
                                    }
                                }
                        } else {
                            // Handle the case where the "uid" field is missing from the post data
                            print("UID is missing in the post data.") // Log an error message to indicate the missing field
                            //self.isLoading = false
                            completion(nil) // Return nil via the completion handler, as the UID is essential for fetching user data
                        }
                    } else {
                        print("Error fetching location data or address.") // Log an error message indicating failure to fetch location data
                        //self.isLoading = false
                        completion(nil) // Return nil via the completion handler as location data is required to create the post
                    }
                }
            }
    }


    
    // Helper function to fetch user details from Firestore
    private func fetchUserFromFirestore(uid: String, notification: Notification, completion: @escaping (Result<NotificationUser, Error>) -> Void) {
        let db = Firestore.firestore() // Initialize Firestore instance for database interaction
        
        // Reference to the user's document in Firestore
        let userRef = db.collection("users").document(uid) // Construct the reference to the specific user's document using the provided UID
        
        // Fetch the document from Firestore
        userRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                // Return error if something went wrong during the fetch operation
                completion(.failure(error))
            } else if let document = documentSnapshot, document.exists {
                // Proceed if the document exists in Firestore
                // Parse the document data
                if let data = document.data() {
                    // Guard statement to ensure that necessary fields are present in the document
                    guard let name = data["name"] as? String,
                          let username = data["username"] as? String,
                          let profileImageUrl = data["profileImageUrl"] as? String else {
                        // If any required fields are missing or of the wrong type, return a parsing error
                        completion(.failure(NSError(domain: "Data parsing error", code: 0, userInfo: nil)))
                        return
                    }
                    
                    // Debugging print statement to show the notification's message before making any changes
                    print ("before changing full message: \(notification.message)")
                    
                    // Create a NotificationUser object and initialize it with the user details and the notification object
                    var user = NotificationUser(uid: uid, name: name, username: username, profileImageUrl: profileImageUrl, notification: notification)
                    // Construct a string that combines the user's name and username in the format "Name (@username)"
                    let name_string = "\(name) (@\(username))"
                    // Check if the notification.message contains the placeholder "$NAME"
                    if notification.message.contains("$NAME") {
                        // If the message contains "$NAME", replace it with the user's name in the format "Name (@username)"
                        user.full_message = notification.message.replacingOccurrences(of: "$NAME", with: name_string)
                    } else {
                        // If the message does not contain "$NAME", prepend the user's name and username to the message
                        user.full_message = "\(name_string) \(notification.message)"
                    }

                    // Debugging print statement to inspect the full message after the replacement
                    print ("after changing full message: \(user.full_message)")
                    
                    // Return the NotificationUser object via the completion handler, signaling success
                    completion(.success(user))
                } else {
                    // If the document data cannot be parsed correctly (missing or invalid data), return a failure via the completion handler
                    // The NSError is created with a custom domain and code indicating a data error
                    completion(.failure(NSError(domain: "Document data error", code: 0, userInfo: nil)))
                }
            } else {
                // If the document does not exist in Firestore (the document snapshot is nil or the document doesn't exist),
                // return a failure via the completion handler.
                // The NSError is created with a custom domain and code indicating the document doesn't exist
                completion(.failure(NSError(domain: "Document does not exist", code: 0, userInfo: nil)))
            }
        }
    }
}
