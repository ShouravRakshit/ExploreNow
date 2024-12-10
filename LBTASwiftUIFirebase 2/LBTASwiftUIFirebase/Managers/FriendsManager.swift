//
//  FriendsManager.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import FirebaseFirestore


//------------------------------------------------------------------------------------------------
class FriendManager: ObservableObject {
    //------------------------------------------------------------------------------------------------
    @Published var friends      : [User] = []  // The list of friends, wrapped in User objects
    @Published var filteredUsers: [User] = []
    //self.filteredUsers = self.users
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    
    private let db = Firestore.firestore()
    //------------------------------------------------------------------------------------------------
    // Fetch friends for a user UID
    func fetchFriends(forUserUID userUID: String) {
        isLoading = true  // Indicate loading state
        error = nil       // Reset any previous errors
        
        // Reference to the friend's document for the user
        let friendsRef = db.collection("friends").document(userUID)
        
        // Fetch the friend's list (a document in the "friends" collection)
        friendsRef.getDocument { document, error in
            self.isLoading = false
            
            if let error = error {
                self.error = error  // Handle error
                return
            }
            
            // Check if the document exists
            guard let document = document, document.exists else {
                self.error = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User's friend list not found"])
                return
            }
            
            // Get the friendUIDs from the document
            if let friendUIDs = document.get("friends") as? [String] {
                print("Fetched friendUIDs: \(friendUIDs.count)")
                self.loadFriendsDetails(from: friendUIDs)  // Load friend details using their UIDs
            } else {
                print("No friends list found for user")
                self.friends = []  // No friends found
            }
        }
    }
    //------------------------------------------------------------------------------------------------
    // Load friend details using their UIDs
    private func loadFriendsDetails(from friendUIDs: [String]) {
        let group = DispatchGroup()
        var fetchedFriends: [User] = []
        
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
                    fetchedFriends.append(friend)
                }
                group.leave()
            }
        }

        // Once all friends are fetched, update the state
        group.notify(queue: .main) {
            self.friends       = fetchedFriends
            self.filteredUsers = self.friends
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
            self.fetchFriends(forUserUID: currentUserUID)
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
