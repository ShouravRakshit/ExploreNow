//
//  BlockedManager.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import FirebaseFirestore


//------------------------------------------------------------------------------------------------
// BlockedManager is a class responsible for managing the blocked users list.
// It conforms to ObservableObject to allow SwiftUI views to bind and react to state changes.
class BlockedManager: ObservableObject {
    //------------------------------------------------------------------------------------------------
    // The 'blocked_users' array stores the list of users that the current user has blocked.
    // It is marked with @Published to allow automatic updates in the UI when the list changes.
    @Published var blocked_users: [User] = []  // The list of friends, wrapped in User objects
    
    // The 'filteredUsers' array is intended to store a filtered subset of blocked users.
    // It could be used for searching or categorizing users in some way.
    @Published var filteredUsers: [User] = []
    //self.filteredUsers = self.users
    // The 'isLoading' boolean indicates whether data is being loaded from the database.
    @Published var isLoading: Bool = false
    // The 'error' variable holds any error encountered during the data fetch process.
    // It is set to 'nil' when there are no errors.
    @Published var error: Error? = nil
    
    // The Firestore database instance is used to interact with the Firestore backend.
    private let db = Firestore.firestore()
    //------------------------------------------------------------------------------------------------
 
    // Fetch blocked users for a specific user identified by their UID.
    // The completion closure provides a success status (true or false).
    func fetchBlockedUsers(forUserUID userUID: String, completion: @escaping (Bool) -> Void) {
        print("Fetching blocked users for current user uid: \(userUID)")
        // Indicate the start of a loading state by setting 'isLoading' to true.
        isLoading = true
        // Reset any previously encountered errors.
        error = nil
        
        // Reference to the Firestore document for the current user's blocked users.
        let blocksRef = db.collection("blocks").document(userUID)
        
        // Fetch the document from the "blocks" collection in Firestore.
        blocksRef.getDocument { document, error in
            // Stop the loading indicator once the document fetch is completed.
            self.isLoading = false
            // Handle any errors encountered during the fetch operation.
            if let error = error {
                // Set the error state and print the error message
                self.error = error
                print("Error fetching blocked users: \(error.localizedDescription)")
                // Call the completion handler with 'false' to indicate failure.
                completion(false)
                return
            }
            
            // Check if the document exists in the Firestore database.
            // 'document' is an optional that might be nil if the document is not found.
            guard let document = document, document.exists else {
                // If the document doesn't exist, set an error message in the 'error' property.
                self.error = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User's blocked list not found"])
                // Print a message to the console indicating the document could not be found.
                print("Blocked users document not found")
                // Call the completion handler with 'false' to indicate failure
                completion(false)  // Indicate failure
                return  // Exit the function as the document wasn't found.
            }
            
            // If the document exists, try to get the list of blocked user IDs from the document.
            // The "blockedUserIds" field is expected to contain an array of user IDs (Strings).
            if let blockedUIDs = document.get("blockedUserIds") as? [String] {
                // Print the number of blocked users fetched for debugging purposes.
                print("Fetched blockedUIDs: \(blockedUIDs.count)")
                // Call the 'loadFriendsDetails' function to fetch detailed information about the blocked users.
                // The function will be responsible for looking up the users using their UIDs.
                self.loadFriendsDetails(from: blockedUIDs)  // Load user details using their UIDs
                // Indicate the success of the operation by calling the completion handler with 'true'.
                completion(true)
            } else {
                // If the "blockedUserIds" field is not found or doesn't contain an array of strings, handle the case.
                print("No blocked list found for user")
                // Reset the 'blocked_users' array as no users are blocked
                self.blocked_users = []
                // Indicate failure because no blocked users were found
                completion(false)
            }
        }
    }

    //------------------------------------------------------------------------------------------------
    // Load friend details using their UIDs
    private func loadFriendsDetails(from friendUIDs: [String]) {
        // DispatchGroup is used to wait for multiple asynchronous tasks to finish before proceeding.
        let group = DispatchGroup()
        // An array to store the fetched User objects (blocked users).
        var fetchedBlockedUsers: [User] = []
        
        // Iterate over each UID in the provided friendUIDs array.
        for uid in friendUIDs {
            // Enter the DispatchGroup for each async operation (fetching a friend's details).
            group.enter()
            // Reference to the "users" collection in Firestore using the UID.
            let friendRef = db.collection("users").document(uid)
            
            // Fetch the friend's document from Firestore.
            friendRef.getDocument { document, error in
                // Handle any errors that occur during the fetch.
                if let error = error {
                    print("Error fetching friend \(uid): \(error.localizedDescription)")
                } else if let document = document, document.exists {
                    // If the document exists, extract the data.
                    let data = document.data() ?? [:]
                    // Create a User object using the fetched data.
                    let friend = User(data: data, uid: uid)
                    // Append the friend (User object) to the fetchedBlockedUsers array.
                    fetchedBlockedUsers.append(friend)
                }
                // Leave the DispatchGroup after each asynchronous operation is complete.
                group.leave()
            }
        }

        // Once all the asynchronous fetch operations are complete, update the state.
        // The group.notify is called when all enter/leave operations are balanced.
        group.notify(queue: .main) {
            // Update the blocked_users property with the list of fetched User objects.
            self.blocked_users = fetchedBlockedUsers
            // Optionally, update the filteredUsers property, possibly for additional filtering or UI purposes.
            self.filteredUsers = self.blocked_users
        }
    }
    //------------------------------------------------------------------------------------------------
    // Remove a friend from both users' friend lists
    func removeFriend(currentUserUID: String, _ friend: User) {
        // Create references to the current user's and the friend's documents in the "friends" collection
        let currentUserRef = db.collection("friends").document(currentUserUID)
        let friendUserRef = db.collection("friends").document(friend.uid)
        
        // Run a Firestore transaction to ensure atomic updates
        db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                // Fetch the current user's friend list from Firestore
                let currentUserDoc = try transaction.getDocument(currentUserRef)
                guard let currentUserFriends = currentUserDoc.data()?["friends"] as? [String] else {
                    return nil // If the data is missing or malformed, return nil
                }
                
                // Fetch the friend's friend list from Firestore
                let friendUserDoc = try transaction.getDocument(friendUserRef)
                guard let friendUserFriends = friendUserDoc.data()?["friends"] as? [String] else {
                    return nil // If the data is missing or malformed, return nil
                }
                
                // Remove friend from both lists
                // Create copies of the friend lists to modify
                var updatedCurrentUserFriends = currentUserFriends
                var updatedFriendUserFriends = friendUserFriends
                
                // Remove the friend from both the current user's and the friend's lists
                updatedCurrentUserFriends.removeAll { $0 == friend.uid }
                updatedFriendUserFriends.removeAll { $0 == currentUserUID }
                
                // Update the databases with the new friend lists
                transaction.updateData(["friends": updatedCurrentUserFriends], forDocument: currentUserRef)
                transaction.updateData(["friends": updatedFriendUserFriends], forDocument: friendUserRef)
                
            } catch {
                // Catch and log any errors that occur during the transaction
                print("Error during transaction: \(error)")
                errorPointer?.pointee = error as NSError
                return nil // Return nil to signal failure
            }
            return nil
        } completion: { (result, error) in
            if let error = error {
                // Handle any errors that occur after the transaction completion
                self.error = error
                return
            }
            
            // Log success message when the friend is successfully removed
            print("Successfully removed friend!")
            //delete all notifications associated with friend requests
            //self.deleteFriendRequestNotifications(user1UID: currentUserUID, user2UID: friend.uid)
            // Optionally, reload friends after removal
            
            self.fetchBlockedUsers(forUserUID: currentUserUID) { success in
                if success {
                    self.isLoading = false // Stop the loading indicator if the fetch was successful
                    print("Blocked users fetched successfully!") // Log a success message
                } else {
                    print("Failed to fetch blocked users.")  // Log a failure message
                }
            }
            
        }
    }
    //------------------------------------------------------------------------------------------------
    func unblockUser(userId: String) {
        // Check if there is a current authenticated user. If not, exit the function.
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        // Reference to the current user's "blocks" document in Firestore
        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        // Reference to the blocked user's "blocks" document in Firestore
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)

        // Remove the blocked user from the current user's "blockedUserIds" array
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayRemove([userId])], merge: true) { error in
            if let error = error {
                // Log any errors that occur while updating the current user's block list
                print("Error unblocking user: \(error)")
            } else {
                // Log success message for unblocking the user
                print("User unblocked successfully.")
                //self.blocked_users.removeAll { $0.uid == userId }
                // Set the loading state to true, indicating that blocked users data will be fetched
                self.isLoading = true
                // Fetch the updated list of blocked users for the current user
                self.fetchBlockedUsers(forUserUID: currentUserId) { success in
                if success {
                    // If fetching blocked users is successful, stop the loading state
                    self.isLoading = false
                    print("Blocked users fetched successfully!")
                } else {
                    // Handle the failure in fetching blocked users
                    print("Failed to fetch blocked users.")
                }
            }
            }
        }

        // Remove the current user from the blocked user's "blockedByIds" array
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayRemove([currentUserId])], merge: true) { error in
            if let error = error {
                // Log any errors that occur while removing the current user from the blocked user's list
                print("Error removing blockedBy for user: \(error)")
            }
        }
    }
    
    //------------------------------------------------------------------------------------------------
    // Function to delete a friend request notification between two users when one unfriends the other
    func deleteFriendRequestNotifications(user1UID: String, user2UID: String) {
        // Reference to the notifications collection
        let notificationsRef = db.collection("notifications")

        // Query to find notifications where sender is user1 and receiver is user2, or vice versa
        notificationsRef.whereField("type", isEqualTo: "friendRequest") // Filters notifications of type "friendRequest"
            .whereField("senderUID", isEqualTo: user1UID) // Filters by sender's UID (user1)
            .whereField("receiverUID", isEqualTo: user2UID) // Filters by receiver's UID (user2)
            .getDocuments { (snapshot, error) in // Executes the query to fetch the documents
                if let error = error {  // If an error occurs during the fetch
                    print("Error fetching notifications: \(error.localizedDescription)") // Prints the error message
                    return // Exits the function early
                }

                // Delete notifications for user1 -> user2
                snapshot?.documents.forEach { document in // Loops through each document in the snapshot
                    document.reference.delete() // Deletes the notification document from Firestore
                    print("Deleted notification from \(user1UID) to \(user2UID)") // Logs the deletion
                }
            }

        // Query for the reverse case: user2 as sender and user1 as receiver
        notificationsRef.whereField("type", isEqualTo: "friendRequest") // Filters notifications of type "friendRequest"
            .whereField("senderUID", isEqualTo: user2UID) // Filters by sender's UID (user2)
            .whereField("receiverUID", isEqualTo: user1UID) // Filters by receiver's UID (user1)
            .getDocuments { (snapshot, error) in // Executes the query to fetch the documents
                if let error = error { // If an error occurs during the fetch
                    print("Error fetching notifications: \(error.localizedDescription)") // Prints the error message // Exits the function early
                    return
                }

                // Delete notifications for user2 -> user1
                snapshot?.documents.forEach { document in // Loops through each document in the snapshot
                    document.reference.delete() // Deletes the notification document from Firestore
                    print("Deleted notification from \(user2UID) to \(user1UID)")  // Logs the deletion
                }
            }
    }
    //------------------------------------------------------------------------------------------------
}
