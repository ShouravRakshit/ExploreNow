//
//  FriendsManager.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import FirebaseFirestore


//------------------------------------------------------------------------------------------------
class FriendManager: ObservableObject {
    //------------------------------------------------------------------------------------------------
    @Published var friends      : [User] = []  // The list of friends, wrapped in User objects
    @Published var filteredUsers: [User] = [] // List of filtered users (not yet initialized)

    @Published var isLoading: Bool = false // Indicates whether the app is in a loading state
    @Published var error: Error? = nil // Holds an error, if any, related to the friend-fetching operation
    
    
    private let db = Firestore.firestore()  // Firestore instance to interact with Firestore database
    //------------------------------------------------------------------------------------------------
    // Function to fetch friends for a given user UID
    func fetchFriends(forUserUID userUID: String) {
        isLoading = true  // Set the loading state to true, indicating data is being fetched
        error = nil       // Reset any previous error
        
        // Reference to the friend's document for the user in the Firestore database
        let friendsRef = db.collection("friends").document(userUID)
        
        // Fetch the user's friend list (stored as a document in the "friends" collection)
        friendsRef.getDocument { document, error in
            self.isLoading = false // Set loading to false once the fetching process is complete
            
            // Handle any error that occurs during fetching
            if let error = error {
                self.error = error  // Store the error to be used later
                return
            }
            
            // Check if the document exists
            guard let document = document, document.exists else {
                // If the document doesn't exist (e.g., no friend list for the user), return an error
                self.error = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User's friend list not found"])
                return
            }
            
            // Get the friendUIDs from the document
            if let friendUIDs = document.get("friends") as? [String] {
                print("Fetched friendUIDs: \(friendUIDs.count)")  // Log the number of friend UIDs fetched
                self.loadFriendsDetails(from: friendUIDs)  // Load the details of each friend using their UIDs
            } else {
                print("No friends list found for user") // If no friends are found, log this message
                self.friends = []  // Set the friends list to an empty array
            }
        }
    }
    //------------------------------------------------------------------------------------------------
    // Load friend details using their UIDs
    private func loadFriendsDetails(from friendUIDs: [String]) {
        let group = DispatchGroup() // DispatchGroup to manage multiple asynchronous tasks
        var fetchedFriends: [User] = [] // Array to store the fetched friend details
        
        // Loop through each friend UID
        for uid in friendUIDs {
            group.enter() // Enter the dispatch group for each friend fetching operation
            let friendRef = db.collection("users").document(uid) // Reference to the friend's document in Firestore
            
            // Fetch each friend's details asynchronously
            friendRef.getDocument { document, error in
                if let error = error {
                    // If an error occurs while fetching the friend's details, print the error
                    print("Error fetching friend \(uid): \(error.localizedDescription)")
                } else if let document = document, document.exists {
                    // If the document exists, fetch the data and initialize a User object
                    let data = document.data() ?? [:] // Default to an empty dictionary if data is nil
                    let friend = User(data: data, uid: uid)   // Create a User object with the fetched data
                    fetchedFriends.append(friend) // Add the created User object to the array
                }
                group.leave() // Leave the dispatch group when the operation completes (either success or failure)
            }
        }

        // Once all friends are fetched, update the state
        group.notify(queue: .main) {
            // The notify method is called once all tasks in the DispatchGroup have completed.
            // It ensures that the following code runs on the main thread after all asynchronous operations are finished.
            self.friends       = fetchedFriends // Assign the fetched friends to the friends array.
            self.filteredUsers = self.friends  // Assign the same friends array to filteredUsers. This could be used for filtering or searching friends later.
        }
    }
    //------------------------------------------------------------------------------------------------
    // Remove a friend from both users' friend lists
    func removeFriend(currentUserUID: String, _ friend: User) {
        // Reference to the 'friends' collection for both current user and the friend
        let currentUserRef = db.collection("friends").document(currentUserUID)
        let friendUserRef = db.collection("friends").document(friend.uid)
        
        // Start a Firestore transaction to ensure atomicity when modifying both users' friend lists
        db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                // Fetch current user's friend list within the transaction
                let currentUserDoc = try transaction.getDocument(currentUserRef)
                // Safely extract the "friends" field from the current user's document
                guard let currentUserFriends = currentUserDoc.data()?["friends"] as? [String] else {
                    // If "friends" is not found or is not an array, return nil to indicate failure
                    return nil
                }
                
                // Fetch the friend's friend list within the same transaction
                let friendUserDoc = try transaction.getDocument(friendUserRef)
                // Safely extract the "friends" field from the friend's document
                guard let friendUserFriends = friendUserDoc.data()?["friends"] as? [String] else {
                    // Similarly, if "friends" is not found, return nil to indicate failure
                    return nil
                }
                
                // Remove friend from both lists
                var updatedCurrentUserFriends = currentUserFriends
                var updatedFriendUserFriends = friendUserFriends
                
                // Remove each other from the respective lists
                updatedCurrentUserFriends.removeAll { $0 == friend.uid }
                updatedFriendUserFriends.removeAll { $0 == currentUserUID }
                
                // Update the database with the new lists
                transaction.updateData(["friends": updatedCurrentUserFriends], forDocument: currentUserRef)
                transaction.updateData(["friends": updatedFriendUserFriends], forDocument: friendUserRef)
                
            } catch {
                print("Error during transaction: \(error)")
                errorPointer?.pointee = error as NSError // Set the error pointer to the encountered error
                return nil // Return nil to abort the transaction if an error occurs
            }
            return nil // Return nil to ensure that the transaction has no result in case of an error
        } completion: { (result, error) in
            if let error = error { // If an error occurs during the transaction completion, handle it
                self.error = error // Assign the error to the `error` property for later handling
                return // Exit the completion block early in case of an error
            }
            
            print("Successfully removed friend!") // Log a success message if the transaction completes without errors
            
            // Optionally, delete all notifications related to the friend request (commented out for now)
            //self.deleteFriendRequestNotifications(user1UID: currentUserUID, user2UID: friend.uid)

            // Optionally reload the user's friends list after the friend has been removed
            self.fetchFriends(forUserUID: currentUserUID)
        }
    }
    //------------------------------------------------------------------------------------------------
    // Function to delete a friend request notification between two users when one unfriends the other
    func deleteFriendRequestNotifications(user1UID: String, user2UID: String) {
        // Reference to the notifications collection in Firestore
        let notificationsRef = db.collection("notifications")

        // Query to find notifications where sender is user1 and receiver is user2
        notificationsRef.whereField("type", isEqualTo: "friendRequest") // Filter for "friendRequest" type notifications
            .whereField("senderUID", isEqualTo: user1UID) // Filter by sender being user1
            .whereField("receiverUID", isEqualTo: user2UID) // Filter by receiver being user2
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)") // Log an error if fetching fails
                    return
                }

                // Delete notifications for the case where user1 -> user2
                snapshot?.documents.forEach { document in
                    document.reference.delete()  // Delete each notification
                    print("Deleted notification from \(user1UID) to \(user2UID)")  // Log successful deletion
                }
            }

        // Query for the reverse case: user2 as sender and user1 as receiver
        notificationsRef.whereField("type", isEqualTo: "friendRequest") // Filter for "friendRequest" type notifications
            .whereField("senderUID", isEqualTo: user2UID) // Filter by sender being user2
            .whereField("receiverUID", isEqualTo: user1UID) // Filter by receiver being user1
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")  // Log an error if fetching fails
                    return
                }

                // Delete notifications for the case where user2 -> user1
                snapshot?.documents.forEach { document in
                    document.reference.delete()  // Delete each notification
                    print("Deleted notification from \(user2UID) to \(user1UID)")  // Log successful deletion
                }
            }
    }
    //------------------------------------------------------------------------------------------------
    
    
}
