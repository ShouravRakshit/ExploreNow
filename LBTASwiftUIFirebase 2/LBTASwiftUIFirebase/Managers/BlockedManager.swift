//
//  BlockedManager.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import FirebaseFirestore


//------------------------------------------------------------------------------------------------
class BlockedManager: ObservableObject {
    //------------------------------------------------------------------------------------------------
    @Published var blocked_users: [User] = []  // The list of friends, wrapped in User objects
    @Published var filteredUsers: [User] = []
    //self.filteredUsers = self.users
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    
    private let db = Firestore.firestore()
    //------------------------------------------------------------------------------------------------
    // Fetch blocked users for a user UID
    func fetchBlockedUsers(forUserUID userUID: String, completion: @escaping (Bool) -> Void) {
        print("Fetching blocked users for current user uid: \(userUID)")
        
        isLoading = true  // Indicate loading state
        error = nil       // Reset any previous errors
        
        // Reference to the user's blocked users document
        let blocksRef = db.collection("blocks").document(userUID)
        
        // Fetch the document in the "blocks" collection
        blocksRef.getDocument { document, error in
            self.isLoading = false  // Stop loading indicator
            
            if let error = error {
                self.error = error  // Handle error
                print("Error fetching blocked users: \(error.localizedDescription)")
                completion(false)  // Indicate failure
                return
            }
            
            // Check if the document exists
            guard let document = document, document.exists else {
                self.error = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User's blocked list not found"])
                print("Blocked users document not found")
                completion(false)  // Indicate failure
                return
            }
            
            // Get the blocked user IDs from the document
            if let blockedUIDs = document.get("blockedUserIds") as? [String] {
                print("Fetched blockedUIDs: \(blockedUIDs.count)")
                self.loadFriendsDetails(from: blockedUIDs)  // Load user details using their UIDs
                completion(true)  // Indicate success
            } else {
                print("No blocked list found for user")
                self.blocked_users = []  // No users found
                completion(false)  // Indicate failure
            }
        }
    }

    //------------------------------------------------------------------------------------------------
    // Load friend details using their UIDs
    private func loadFriendsDetails(from friendUIDs: [String]) {
        let group = DispatchGroup()
        var fetchedBlockedUsers: [User] = []
        
        for uid in friendUIDs {
            group.enter()
            let friendRef = db.collection("users").document(uid)
            
            // Fetch each friend's details
            friendRef.getDocument { document, error in
                if let error = error {
                    print("Error fetching friend \(uid): \(error.localizedDescription)")
                } else if let document = document, document.exists {
                    let data = document.data() ?? [:]
                    let friend = User(data: data, uid: uid)  // Initialize User with the fetched data
                    fetchedBlockedUsers.append(friend)
                }
                group.leave()
            }
        }

        // Once all friends are fetched, update the state
        group.notify(queue: .main) {
            self.blocked_users = fetchedBlockedUsers
            self.filteredUsers = self.blocked_users
        }
    }
    //------------------------------------------------------------------------------------------------
    // Remove a friend from both users' friend lists
    func removeFriend(currentUserUID: String, _ friend: User) {
        let currentUserRef = db.collection("friends").document(currentUserUID)
        let friendUserRef = db.collection("friends").document(friend.uid)
        
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
                updatedCurrentUserFriends.removeAll { $0 == friend.uid }
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
                self.error = error
                return
            }
            
            print("Successfully removed friend!")
            //delete all notifications associated with friend requests
            //self.deleteFriendRequestNotifications(user1UID: currentUserUID, user2UID: friend.uid)
            // Optionally, reload friends after removal
            
            self.fetchBlockedUsers(forUserUID: currentUserUID) { success in
                if success {
                    self.isLoading = false
                    print("Blocked users fetched successfully!")
                } else {
                    print("Failed to fetch blocked users.")
                }
            }
            
        }
    }
    //------------------------------------------------------------------------------------------------
    func unblockUser(userId: String) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)

        // Remove the blocked user from the current user's blocks list
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayRemove([userId])], merge: true) { error in
            if let error = error {
                print("Error unblocking user: \(error)")
            } else {
                print("User unblocked successfully.")
                //self.blocked_users.removeAll { $0.uid == userId }
                
                self.isLoading = true
                self.fetchBlockedUsers(forUserUID: currentUserId) { success in
                if success {
                    self.isLoading = false
                    print("Blocked users fetched successfully!")
                } else {
                    print("Failed to fetch blocked users.")
                }
            }
            }
        }

        // Remove the current user from the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayRemove([currentUserId])], merge: true) { error in
            if let error = error {
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
        notificationsRef.whereField("type", isEqualTo: "friendRequest")
            .whereField("senderUID", isEqualTo: user1UID)
            .whereField("receiverUID", isEqualTo: user2UID)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }

                // Delete notifications for user1 -> user2
                snapshot?.documents.forEach { document in
                    document.reference.delete()
                    print("Deleted notification from \(user1UID) to \(user2UID)")
                }
            }

        // Query for the reverse case: user2 as sender and user1 as receiver
        notificationsRef.whereField("type", isEqualTo: "friendRequest")
            .whereField("senderUID", isEqualTo: user2UID)
            .whereField("receiverUID", isEqualTo: user1UID)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }

                // Delete notifications for user2 -> user1
                snapshot?.documents.forEach { document in
                    document.reference.delete()
                    print("Deleted notification from \(user2UID) to \(user1UID)")
                }
            }
    }
    //------------------------------------------------------------------------------------------------
}
