import FirebaseFirestore
import Combine

// NotificationUser model to represent a user fetched from Firestore
struct NotificationUser {
    let uid: String
    let name: String
    let username: String
    let profileImageUrl: String
    var notification: Notification
    var full_message: String? // Optional property
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
        
        //reset notification users so its not appended to each time view is called
        notificationUsers = []
        
        // Loop over each senderId (UID) and fetch the user data
        for notification in notifications {
            
            group.enter() // Enter the group for each async operation

            // Fetch user details from Firestore
            fetchUserFromFirestore(uid: notification.senderId, notification: notification) { [weak self] result in
                guard let self = self else { return }  // Avoid using self if it's deallocated
                
                switch result {
                case .success(let user):
                    // Add the user to the notification users list
                    self.notificationUsers.append(user)
                    print("Fetched User: \(user.name), \(user.username), Full message: \(user.full_message ?? "No message")")
                case .failure(let error):
                    print("Error fetching user: \(error.localizedDescription)")
                }
                group.leave() // Leave the group after each fetch completes
            }
        }
        
        // Notify when all async fetches are done
        group.notify(queue: .main) {
            // Call the completion handler once all users have been fetched
            completion(.success(self.notificationUsers))
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
