//
//  ChatLogViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import SwiftUI
import Firebase



class ChatLogViewModel: ObservableObject {
    // Published properties allow the view to observe and react to changes.
    @Published var chatText = "" // A string to hold the text input by the user for sending a chat message
    @Published var errorMessage = "" // A string to hold any error messages that need to be displayed
    @Published var chatMessages = [ChatMessage]() // An array of ChatMessage objects to store messages in the chat log
    @Published var blockedUsers: [String] = [] // A list of blocked users (by the current user)
    @EnvironmentObject var userManager: UserManager // Injected user manager to manage user state and information
    @Published var blockedByUsers: [String] = [] // A list of users who have blocked the current user
    
    var chatUser: ChatUser? // The chat user being interacted with. Optional in case no user is specified
    
    // Initializer for the ChatLogViewModel
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        // Fetch information relevant to the user and the chat
        fetchBlockedUsers()
        fetchMessages()
        fetchBlockedByUsers()
    }


    private func fetchBlockedByUsers() {
        // Ensure the current user is authenticated and retrieve their user ID
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        // Access the Firestore database and listen for changes to the "blocks" collection, specifically the document for the current user
        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .addSnapshotListener { documentSnapshot, error in
                // Handle any errors that occur during the fetch operation
                if let error = error {
                    print("Error fetching blockedBy users: \(error)")
                    return
                }
                // If data is successfully retrieved, update the blockedByUsers property with the list of blocked user IDs
                if let data = documentSnapshot?.data() {
                    self.blockedByUsers = data["blockedByIds"] as? [String] ?? []
                }
            }
    }

    
    private func fetchBlockedUsers() {
        // Ensure the current user is authenticated and retrieve their user ID
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        // Access the Firestore database and listen for changes to the "blocks" collection, specifically the document for the current user
        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .addSnapshotListener { documentSnapshot, error in
                // Handle any errors that occur during the fetch operation
                if let error = error {
                    print("Error fetching blocked users: \(error)")
                    return
                }
                // If data is successfully retrieved, update the blockedUsers property with the list of blocked user IDs
                if let data = documentSnapshot?.data() {
                    self.blockedUsers = data["blockedUserIds"] as? [String] ?? []
                }
            }
    }

    
    // Method to set or update the chat user
    func setChatUser(_ newUser: ChatUser?) {
        self.chatUser = newUser // Set the new user
        fetchMessages() // Fetch messages for the new user
        fetchBlockedUsers() // Re-fetch blocked users for the new chatUser
        fetchBlockedByUsers() // Re-fetch blocked by users
    }
    
    func fetchMessages() {
        print ("fetching messages for: \(chatUser?.name)")
        
        // Step 1: Safeguard to ensure the current user ID (fromId) is available
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        // Step 2: Safeguard to ensure the target user ID (toId) is available
        guard let toId = chatUser?.uid else { return }

        // Step 3: Query Firestore for messages between the current user and the target user
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp, descending: false) // Order by timestamp in ascending order (oldest first)
            .addSnapshotListener { querySnapshot, error in
                
                // Step 4: Handle errors while fetching messages
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error)" // Update error message
                    print(error) // Log the error to the console for debugging
                    return // Stop further execution if there’s an error
                }

                // Step 5: Clear the current chat messages before fetching new ones
                self.chatMessages.removeAll()

                // Step 6: Process each document in the snapshot (representing a message)
                querySnapshot?.documents.forEach { queryDocumentSnapshot in
                    let data = queryDocumentSnapshot.data() // Extract data from the document snapshot
                    let docId = queryDocumentSnapshot.documentID // Get the document ID (unique identifier for the message)

                    // Step 7: Append the message to the chatMessages array
                    // Initialize a new ChatMessage object with the document data and add it to the list
                    self.chatMessages.append(.init(documentId: docId, data: data))
                }
            }
    }


    private func sendMessageBatch(fromId: String, toId: String, messageData: [String: Any]) {
        // Step 1: Retrieve Firestore instance from FirebaseManager
        let firestore = FirebaseManager.shared.firestore

        // Step 2: Generate a unique document ID for the message
        let messageId = firestore.collection("messages")
            .document(fromId) // The sender's document
            .collection(toId) // The recipient's collection
            .document() // Create a new document in the collection
            .documentID // Automatically generate the document ID for the new message

        // Step 3: Create reference to the sender's message document
        let senderMessageRef = firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document(messageId)

        // Step 4: Create reference to the recipient's message document
        let recipientMessageRef = firestore.collection("messages")
            .document(toId) // The recipient's document
            .collection(fromId) // The sender's collection
            .document(messageId) // Same message ID to mirror the message in both collections

        // Step 5: Create a batch to send the data in both places atomically
        let batch = firestore.batch()
        batch.setData(messageData, forDocument: senderMessageRef) // Add data to the sender's document
        batch.setData(messageData, forDocument: recipientMessageRef) // Add the same data to the recipient's document

        // Step 6: Commit the batch operation to Firestore
        batch.commit { error in
            // Step 7: Handle any errors that occur during commit
            if let error = error {
                self.errorMessage = "Failed to send message: \(error)" // Update error message property
                print("Error sending message: \(error)") // Log the error
                return // Exit the method if there was an error
            }

            // Step 8: Successfully sent the message, log and perform necessary actions
            print("Successfully sent message with ID: \(messageId)")
            self.persistRecentMessage() // Optionally, update any recent message persistence logic
            self.chatText = "" // Clear the input field after sending the message
        }
    }

    func handleSend() {
        // Step 1: Retrieve the current user's ID (sender) and the chat user's ID (recipient).
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }

        // Step 2: Check if the sender has blocked the recipient.
        if blockedUsers.contains(toId) {
            print("You have blocked this user. You cannot send messages.")
            return // Prevent sending the message if the sender has blocked the recipient
        }

        // Step 3: Fetch the recipient's block status to check if the sender is blocked by the recipient.
        let firestore = FirebaseManager.shared.firestore
        firestore.collection("blocks").document(toId).getDocument { document, error in
            // Handle any error while fetching the recipient's block status.
            if let error = error {
                print("Error fetching recipient block status: \(error)")
                return // Exit if there is an error fetching block status
            }

            // Step 4: Retrieve the list of users who have blocked the recipient (i.e., 'blockedByIds').
            let recipientBlockedUsers = document?.data()?["blockedByIds"] as? [String] ?? []
            
            // Step 5: Check if the sender is in the recipient's blocked list.
            if recipientBlockedUsers.contains(fromId) {
                print("This user has blocked you. You cannot send messages.")
                return // Prevent sending the message if the sender is blocked by the recipient
            }

            // Step 6: Proceed with sending the message if neither user has blocked the other.
            let messageData: [String: Any] = [
                FirebaseConstants.fromId: fromId, // Sender's ID
                FirebaseConstants.toId: toId, // Recipient's ID
                FirebaseConstants.text: self.chatText, // The content of the message
                FirebaseConstants.timestamp: Timestamp() // Timestamp of when the message was sent
            ]

            // Step 7: Call the sendMessageBatch function to actually send the message
            self.sendMessageBatch(fromId: fromId, toId: toId, messageData: messageData)
        }
    }

    private func persistRecentMessage() {
        // Step 1: Check if the `chatUser` is available. If not, return early.
        guard let chatUser = chatUser else { return }

        // Step 2: Get the current authenticated user's UID. If it's not available, return early.
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        // Step 3: Get the recipient's UID (chatUser). If not available, return early.
        guard let toId = self.chatUser?.uid else { return }

        // Step 4: Prepare the sender's data to be stored in the Firestore.
        let senderData = [
            FirebaseConstants.timestamp: Timestamp(), // The timestamp of the message
            FirebaseConstants.text: self.chatText, // The text of the message
            FirebaseConstants.fromId: uid, // The sender's UID
            FirebaseConstants.toId: toId, // The recipient's UID
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl, // The recipient's profile image URL
            FirebaseConstants.email: chatUser.email // The recipient's email
        ] as [String: Any]

        // Step 5: Create a reference to the sender's document in the Firestore `recent_messages` collection.
        let senderDocument = FirebaseManager.shared.firestore.collection("recent_messages")
            .document(uid) // Document for the sender (using sender's UID)
            .collection("messages") // The `messages` subcollection
            .document(toId) // Document for the recipient (using recipient's UID)

        // Step 6: Save the sender's data to Firestore.
        senderDocument.setData(senderData) { error in
            if let error = error {
                // If there is an error, set an error message and print the error.
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent message for sender: \(error)")
                return // Exit the function if there is an error
            }
        }

        // Step 7: Prepare the recipient's data to be stored in Firestore.
        let recipientData = [
            FirebaseConstants.timestamp: Timestamp(), // Timestamp of the message
            FirebaseConstants.text: self.chatText, // The text of the message
            FirebaseConstants.fromId: toId, // The recipient's UID
            FirebaseConstants.toId: uid, // The sender's UID
            FirebaseConstants.profileImageUrl: FirebaseManager.shared.auth.currentUser?.photoURL?.absoluteString ?? "", // The sender's profile image URL
            FirebaseConstants.email: FirebaseManager.shared.auth.currentUser?.email ?? "" // The sender's email
        ] as [String: Any]

        // Step 8: Create a reference to the recipient's document in the Firestore `recent_messages` collection.
        let recipientDocument = FirebaseManager.shared.firestore.collection("recent_messages")
            .document(toId) // Document for the recipient (using recipient's UID)
            .collection("messages") // The `messages` subcollection
            .document(uid) // Document for the sender (using sender's UID)

        // Step 9: Save the recipient's data to Firestore.
        recipientDocument.setData(recipientData) { error in
            if let error = error {
                // If there is an error, set an error message and print the error.
                self.errorMessage = "Failed to save recent message for recipient: \(error)"
                print("Failed to save recent message for recipient: \(error)")
                return // Exit the function if there is an error
            }
        }
    }


    func deleteMessage(_ messageId: String) {
        // Step 1: Get the current user's ID (fromId). If it fails, return early.
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        // Step 2: Get the recipient's ID (toId). If it fails, return early.
        guard let toId = chatUser?.uid else { return }
        
        // Step 3: Remove the message from the local chat messages array.
        // This removes the message from the `chatMessages` array based on its messageId.
        chatMessages.removeAll { $0.id == messageId }

        // Step 4: Delete the message from the sender's Firestore collection.
        // The message is deleted from the "messages" collection for the sender (fromId) and recipient (toId).
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId) // Sender's ID
            .collection(toId) // Recipient's ID
            .document(messageId) // Specific message document ID
            .delete { error in
                if let error = error {
                    // If there is an error during the deletion, log the error message.
                    print("Failed to delete message: \(error)")
                } else {
                    // If the deletion is successful, log success and update the recent messages.
                    print("Successfully deleted message")
                    self.updateRecentMessagesAfterDeletion(fromId: fromId, toId: toId)
                }
            }

        // Step 5: Delete the message from the recipient's Firestore collection.
        // The message is also deleted from the "messages" collection for the recipient (toId) and sender (fromId).
        FirebaseManager.shared.firestore.collection("messages")
            .document(toId) // Recipient's ID
            .collection(fromId) // Sender's ID
            .document(messageId) // Specific message document ID
            .delete { error in
                if let error = error {
                    // If there is an error during the deletion, log the error message.
                    print("Failed to delete message for recipient: \(error)")
                } else {
                    // If the deletion is successful, log success and update the recent messages.
                    print("Successfully deleted message for recipient")
                    self.updateRecentMessagesAfterDeletion(fromId: toId, toId: fromId)
                }
            }
    }

    private func updateRecentMessagesAfterDeletion(fromId: String, toId: String) {
        // Step 1: Fetch the most recent message in the "messages" collection for the sender (fromId) and recipient (toId).
        // This query retrieves the last message based on the timestamp, ordered in descending order, and limits the result to just one document.
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId) // Sender's ID
            .collection(toId) // Recipient's ID
            .order(by: FirebaseConstants.timestamp, descending: true) // Sort by timestamp, most recent first
            .limit(to: 1) // Limit to only the most recent message
            .getDocuments { snapshot, error in
                if let error = error {
                    // If there's an error fetching the documents, print the error and exit the function.
                    print("Failed to fetch last message: \(error)")
                    return
                }

                // Step 2: If a recent message is found, update the 'recent_messages' collection.
                if let lastMessage = snapshot?.documents.first?.data() {
                    // The last message data is successfully retrieved, so update the 'recent_messages' collection for the sender and recipient.
                    FirebaseManager.shared.firestore.collection("recent_messages")
                        .document(fromId) // Sender's ID
                        .collection("messages") // Sender's "messages" subcollection
                        .document(toId) // Recipient's ID (to store recent messages)
                        .setData(lastMessage) { error in
                            if let error = error {
                                // If there's an error updating the recent message, print it.
                                print("Failed to update recent_messages: \(error)")
                            }
                        }
                } else {
                    // Step 3: If there are no more messages (i.e., no recent message), delete the recent messages document.
                    // This happens when the last message has been deleted, and there are no remaining messages to display.
                    FirebaseManager.shared.firestore.collection("recent_messages")
                        .document(fromId) // Sender's ID
                        .collection("messages") // Sender's "messages" subcollection
                        .document(toId) // Recipient's ID
                        .delete { error in
                            if let error = error {
                                // If there's an error deleting the recent message document, print it.
                                print("Failed to delete recent_messages: \(error)")
                            }
                        }
                }
            }
    }

    func blockUser(userId: String) {
        // Retrieve the current authenticated user's ID. If not authenticated, exit the function.
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        // References to the Firestore documents for the current user's block list and the target user's block list
        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)

        // Add the target user to the current user's block list using Firestore's arrayUnion to ensure no duplicates
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayUnion([userId])], merge: true) { error in
            // Handle any error that occurs when attempting to update the current user's block list
            if let error = error {
                print("Error blocking user: \(error)") // Log the error if blocking fails
            } else {
                print("User blocked successfully.") // Log success when user is blocked successfully
                self.blockedUsers.append(userId)  // Update the local blocked users list
                self.removeFriend (currentUserUID: currentUserId, friend_uid: userId) // Remove the user from the friends list, if applicable
            }
        }

        // Add the current user to the blocked user's 'blockedBy' list, marking the current user as the one who blocked them
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayUnion([currentUserId])], merge: true) { error in
            // Handle any error that occurs when updating the blocked user's 'blockedBy' list
            if let error = error {
                print("Error adding blockedBy for user: \(error)") // Log the error if updating 'blockedBy' fails
            }
        }
    }

    func unblockUser(userId: String) {
        // Retrieve the current authenticated user's ID. If not authenticated, exit the function.
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        // References to the Firestore documents for the current user's block list and the target user's block list
        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)

        // Remove the blocked user from the current user's block list using Firestore's arrayRemove to ensure the user is removed
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayRemove([userId])], merge: true) { error in
            // Handle any error that occurs when attempting to update the current user's block list
            if let error = error {
                print("Error unblocking user: \(error)") // Log the error if unblocking fails
            } else {
                print("User unblocked successfully.") // Log success when user is unblocked successfully
                self.blockedUsers.removeAll { $0 == userId }  // Update the local blocked users list by removing the unblocked user
            }
        }

        // Remove the current user from the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayRemove([currentUserId])], merge: true) { error in
            // Check for any error that may occur while updating the blocked user's 'blockedByIds' list
            if let error = error {
                // Log the error if removing the current user from the 'blockedByIds' list fails
                print("Error removing blockedBy for user: \(error)")
            }
        }
    }
    
    // Remove a friend from both users' friend lists
    func removeFriend(currentUserUID: String, friend_uid: String) {
        // Reference to the Firestore database
        let db = Firestore.firestore()
        
        // References to the current user and friend's 'friends' documents in Firestore
        let currentUserRef = db.collection("friends").document(currentUserUID)
        let friendUserRef  = db.collection("friends").document(friend_uid)
        
        // Run a Firestore transaction to ensure atomic operations on both documents
        db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                // Fetch the current user's friend list document
                let currentUserDoc = try transaction.getDocument(currentUserRef)
                
                // Ensure that the friend's list exists and is of the correct type
                guard let currentUserFriends = currentUserDoc.data()?["friends"] as? [String] else {
                    return nil
                }
                
                // Fetch the friend's friend list document
                let friendUserDoc = try transaction.getDocument(friendUserRef)
                // Ensure that the friend's list exists and is of the correct type
                guard let friendUserFriends = friendUserDoc.data()?["friends"] as? [String] else {
                    return nil
                }
                
                // Remove the friend from both users' friend lists
                var updatedCurrentUserFriends = currentUserFriends
                var updatedFriendUserFriends = friendUserFriends
                
                // Remove the friend's UID from the current user's friend list
                updatedCurrentUserFriends.removeAll { $0 == friend_uid }
                
                // Remove the current user's UID from the friend's friend list
                updatedFriendUserFriends.removeAll { $0 == currentUserUID }
                
                // Update the Firestore database with the new friend lists
                transaction.updateData(["friends": updatedCurrentUserFriends], forDocument: currentUserRef)
                transaction.updateData(["friends": updatedFriendUserFriends], forDocument: friendUserRef)
                
            } catch {
                // If an error occurs during the transaction, print the error and return
                print("Error during transaction: \(error)")
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        } completion: { (result, error) in
            // If no error occurs in the transaction completion
            if let error = error {
                return
            }
            
            // If no error occurs in the transaction completion
            print("Successfully removed friend!")
            //delete all notifications associated with friend requests
            //self.deleteFriendRequestNotifications(user1UID: currentUserUID, user2UID: friend.uid)
        }
    }

}
extension ChatLogViewModel {
    // Function to group chat messages by date.
    func groupMessagesByDate() -> [String: [ChatMessage]] {
        var groupedMessages = [String: [ChatMessage]]()  // A dictionary to store messages grouped by their date (keyed by date as String)

        let dateFormatter = DateFormatter()  // DateFormatter to format timestamps into a string date
        dateFormatter.dateFormat = "MM/dd/yy" // Define the date format (e.g., "11/18/24")

        // Iterate through each chat message in the chatMessages array
        for message in chatMessages {
            // Convert the timestamp of the message to a string using the defined date format
            let dateKey = dateFormatter.string(from: message.timestamp.dateValue())
            
            // If no messages are already grouped under the specific date, initialize an empty array
            if groupedMessages[dateKey] == nil {
                groupedMessages[dateKey] = []
            }
            
            // Append the current message to the corresponding date's array in the dictionary
            groupedMessages[dateKey]?.append(message)
        }

        // Return the grouped messages dictionary
        return groupedMessages
    }
}
