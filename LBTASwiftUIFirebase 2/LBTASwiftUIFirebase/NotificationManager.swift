import FirebaseFirestore
import Combine

// NotificationUser model to represent a user fetched from Firestore
struct NotificationUser {
    let uid            : String
    let name           : String
    let username       : String
    let profileImageUrl: String
    var notification   : Notification
    var full_message   : String? // Optional property
    var post_url       : String? // Optional post URL
    var post           : Post?
}

// Singleton Manager to manage notification users
class NotificationManager {
    
    static let shared = NotificationManager() // Singleton instance
    
    // Store the notification users
    @Published var notificationUsers: [NotificationUser] = []
    
    // Private init to enforce singleton usage
    private init() {}
    
    // Fetch all notifications and populate the notification users
    func populateNotificationUsers(notifications: [Notification], completion: @escaping (Result<[NotificationUser], Error>) -> Void) {
        
        // Dispatch group to manage multiple async calls
        let group = DispatchGroup()
        
        // Reset notification users so it's not appended each time the view is called
        notificationUsers = []
        print ("notifications count before fetch user from firestore: \(notifications.count)")
        // Loop over each notification and fetch user data
        for notification in notifications {
            
            group.enter() // Enter the group for each async operation

            // Fetch user details from Firestore
            fetchUserFromFirestore(uid: notification.senderId, notification: notification) { [weak self] result in
                guard let self = self else { return }  // Avoid using self if it's deallocated
                
                var notificationUser: NotificationUser?
                
                switch result {
                case .success(let user):
                    // Create a notification user object based on the fetched user
                    notificationUser = user
                    
                    print ("fetched user from firestore: \(notificationUser?.username) message: \(notificationUser?.full_message)")
                    
                    // Check if there's a post_id, and fetch the post data if it exists
                    if let postId = notification.post_id, !postId.isEmpty {
                        
                        fetchPost(by: postId) { post in
                            if let fetchedPost = post {
                                // Handle the post here, e.g., update your UI or process the post object
                                print("Fetched Post: \(fetchedPost.description)")
                                notificationUser?.post = fetchedPost
                                
                                notificationUser?.post_url = fetchedPost.imageUrls.count > 0 ? fetchedPost.imageUrls [0] : ""
                                // Append the NotificationUser with the fetched post URL to the list
                                if let notificationUser = notificationUser {
                                    self.notificationUsers.append(notificationUser)
                                    print("Fetched User: \(user.name), Post URL: \(notificationUser.post_url)")
                                }
                                
                                // Call group.leave() after both user and post fetches are done
                                group.leave()
                                
                            } else {
                                // Handle the error (post not found or fetch failed)
                                print("Failed to fetch post.")
                                group.leave()
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
                        print ("no post id, appending user to list")
                        // No postId, just append the user to the list
                        if let notificationUser = notificationUser {
                            self.notificationUsers.append(notificationUser)
                        }
                        // Leave the group even if there's no post URL to fetch
                        group.leave()
                    }
                    
                case .failure(let error):
                    print("Error fetching user: \(error.localizedDescription)")
                    // Leave the group if there's an error in fetching the user
                    group.leave()
                }
            }
        }
        
        // Notify when all async fetches are done
        group.notify(queue: .main) {
            print ("notification user count after fetching: \(self.notificationUsers.count)")
            // Call the completion handler once all users have been fetched
            completion(.success(self.notificationUsers))
        }
    }
    
    //fetches post url for current notification user 
    private func fetchPostData(for postId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // Query the Firestore database for the post using the post_id
        db.collection("user_posts").document(postId).getDocument { document, error in
            if let document = document, document.exists {
                
                
                // Fetch the images field (assuming it's an array of strings)
                if let images = document.data()?["images"] as? [String], let firstImageUrl = images.first {
                    print ("first post in user post: \(firstImageUrl)")
                    // Return the first image URL
                    completion(firstImageUrl)
                } else {
                    // No images found
                    completion(nil)
                }
            } else {
                // Handle the case where the post doesn't exist or there's an error
                print("Post with ID \(postId) does not exist or there was an error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }

    private func fetchPost(by postId: String, completion: @escaping (Post?) -> Void) {
        //isLoading = true
        
        FirebaseManager.shared.firestore
            .collection("user_posts")
            .document(postId) // Fetch a specific post by its ID
            .getDocument { [weak self] documentSnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching post: \(error.localizedDescription)")
                    //self.isLoading = false
                    completion(nil)
                    return
                }

                // Check if document exists
                guard let document = documentSnapshot, document.exists else {
                    print("Post with ID \(postId) does not exist.")
                    //self.isLoading = false
                    completion(nil)
                    return
                }

                let data = document.data()

                // Fetch the location reference from the post document
                guard let locationRef = data?["locationRef"] as? DocumentReference else {
                    print("Location reference is missing in the post data.")
                    //self.isLoading = false
                    completion(nil)
                    return
                }

                // Fetch location details using the location reference
                locationRef.getDocument { locationSnapshot, locationError in
                    if let locationData = locationSnapshot?.data(),
                       let address = locationData["address"] as? String {

                        // Fetch user details from the "users" collection using the uid from the post
                        if let uid = data?["uid"] as? String {
                            FirebaseManager.shared.firestore
                                .collection("users")
                                .document(uid)
                                .getDocument { userSnapshot, userError in
                                    if let userData = userSnapshot?.data() {
                                        // Create a Post object from the fetched data
                                        let post = Post(
                                            id: postId,
                                            description: data?["description"] as? String ?? "",
                                            rating: data?["rating"] as? Int ?? 0,
                                            locationRef: locationRef,
                                            locationAddress: address,
                                            imageUrls: data?["images"] as? [String] ?? [],
                                            timestamp: (data?["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                            uid: uid,
                                            username: userData["username"] as? String ?? "User",
                                            userProfileImageUrl: userData["profileImageUrl"] as? String ?? ""
                                        )

                                        // Return the post via the completion handler
                                        DispatchQueue.main.async {
                                            //self.isLoading = false
                                            completion(post)
                                        }
                                    } else {
                                        print("Error fetching user data for UID \(uid)")
                                        //self.isLoading = false
                                        completion(nil)
                                    }
                                }
                        } else {
                            print("UID is missing in the post data.")
                            //self.isLoading = false
                            completion(nil)
                        }
                    } else {
                        print("Error fetching location data or address.")
                        //self.isLoading = false
                        completion(nil)
                    }
                }
            }
    }


    
    // Helper function to fetch user details from Firestore
    private func fetchUserFromFirestore(uid: String, notification: Notification, completion: @escaping (Result<NotificationUser, Error>) -> Void) {
        let db = Firestore.firestore()
        
        // Reference to the user's document in Firestore
        let userRef = db.collection("users").document(uid)
        
        // Fetch the document from Firestore
        userRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(.failure(error))  // Return error if something went wrong
            } else if let document = documentSnapshot, document.exists {
                // Parse the data
                if let data = document.data() {
                    guard let name = data["name"] as? String,
                          let username = data["username"] as? String,
                          let profileImageUrl = data["profileImageUrl"] as? String else {
                        completion(.failure(NSError(domain: "Data parsing error", code: 0, userInfo: nil)))
                        return
                    }
                    
                    print ("before changing full message: \(notification.message)")
                    
                    // Create a NotificationUser object and return it
                    var user = NotificationUser(uid: uid, name: name, username: username, profileImageUrl: profileImageUrl, notification: notification)
                    let name_string = "\(name) (@\(username))"
                    // Check if the notification.message contains "$NAME" and replace it with user.name
                    if notification.message.contains("$NAME") {
                        // Replace "$NAME" with the user's name
                        user.full_message = notification.message.replacingOccurrences(of: "$NAME", with: name_string)
                    } else {
                        // If no "$NAME" in the message, just use the message as is
                        user.full_message = "\(name_string) \(notification.message)"
                    }

                    print ("after changing full message: \(user.full_message)")
                    
                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "Document data error", code: 0, userInfo: nil)))
                }
            } else {
                completion(.failure(NSError(domain: "Document does not exist", code: 0, userInfo: nil)))
            }
        }
    }
}
