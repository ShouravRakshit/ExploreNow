//
//  ChatLogViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import Foundation
import SwiftUI
import Firebase



class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var blockedUsers: [String] = []
    @EnvironmentObject var userManager: UserManager
    @Published var blockedByUsers: [String] = []

    var chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchBlockedUsers()
        fetchMessages()
        fetchBlockedByUsers()
    }
    
    private func fetchBlockedByUsers() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("Error fetching blockedBy users: \(error)")
                    return
                }
                if let data = documentSnapshot?.data() {
                    self.blockedByUsers = data["blockedByIds"] as? [String] ?? []
                }
            }
    }
    
    private func fetchBlockedUsers() {
            guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

            FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        print("Error fetching blocked users: \(error)")
                        return
                    }
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
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }

        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp, descending: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error)"
                    print(error)
                    return
                }

                self.chatMessages.removeAll()

                querySnapshot?.documents.forEach { queryDocumentSnapshot in
                    let data = queryDocumentSnapshot.data()
                    let docId = queryDocumentSnapshot.documentID

                    // Allow fetching all messages, even if the user is blocked
                    self.chatMessages.append(.init(documentId: docId, data: data))
                    
                }
            }
    }


    private func sendMessageBatch(fromId: String, toId: String, messageData: [String: Any]) {
        let firestore = FirebaseManager.shared.firestore

        let messageId = firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document().documentID

        let senderMessageRef = firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document(messageId)

        let recipientMessageRef = firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document(messageId)

        let batch = firestore.batch()
        batch.setData(messageData, forDocument: senderMessageRef)
        batch.setData(messageData, forDocument: recipientMessageRef)

        batch.commit { error in
            if let error = error {
                self.errorMessage = "Failed to send message: \(error)"
                print("Error sending message: \(error)")
                return
            }
            print("Successfully sent message with ID: \(messageId)")
            self.persistRecentMessage()
            self.chatText = ""
        }
    }

    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }

        // Check if the sender has blocked the recipient
        if blockedUsers.contains(toId) {
            print("You have blocked this user. You cannot send messages.")
            return
        }

        // Fetch the recipient's blocked status
        let firestore = FirebaseManager.shared.firestore
        firestore.collection("blocks").document(toId).getDocument { document, error in
            if let error = error {
                print("Error fetching recipient block status: \(error)")
                return
            }

            let recipientBlockedUsers = document?.data()?["blockedByIds"] as? [String] ?? []
            if recipientBlockedUsers.contains(fromId) {
                print("This user has blocked you. You cannot send messages.")
                return
            }

            // Proceed with sending the message
            let messageData: [String: Any] = [
                FirebaseConstants.fromId: fromId,
                FirebaseConstants.toId: toId,
                FirebaseConstants.text: self.chatText,
                FirebaseConstants.timestamp: Timestamp()
            ]

            self.sendMessageBatch(fromId: fromId, toId: toId, messageData: messageData)
        }
    }

    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let senderData = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ] as [String: Any]
        
        let senderDocument = FirebaseManager.shared.firestore.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)

        senderDocument.setData(senderData) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent message for sender: \(error)")
                return
            }
        }

        let recipientData = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: toId,
            FirebaseConstants.toId: uid,
            FirebaseConstants.profileImageUrl: FirebaseManager.shared.auth.currentUser?.photoURL?.absoluteString ?? "",
            FirebaseConstants.email: FirebaseManager.shared.auth.currentUser?.email ?? ""
        ] as [String: Any]
        
        let recipientDocument = FirebaseManager.shared.firestore.collection("recent_messages")
            .document(toId)
            .collection("messages")
            .document(uid)

        recipientDocument.setData(recipientData) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message for recipient: \(error)"
                print("Failed to save recent message for recipient: \(error)")
                return
            }
        }
    }

    func deleteMessage(_ messageId: String) {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        chatMessages.removeAll { $0.id == messageId }

        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document(messageId)
            .delete { error in
                if let error = error {
                    print("Failed to delete message: \(error)")
                } else {
                    print("Successfully deleted message")
                    self.updateRecentMessagesAfterDeletion(fromId: fromId, toId: toId)

                }
            }

        FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document(messageId)
            .delete { error in
                if let error = error {
                    print("Failed to delete message for recipient: \(error)")
                } else {
                    print("Successfully deleted message for recipient")
                    self.updateRecentMessagesAfterDeletion(fromId: toId, toId: fromId)

                }
            }
    }
    
    private func updateRecentMessagesAfterDeletion(fromId: String, toId: String) {
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp, descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch last message: \(error)")
                    return
                }

                if let lastMessage = snapshot?.documents.first?.data() {
                    // Update recent_messages with the last message
                    FirebaseManager.shared.firestore.collection("recent_messages")
                        .document(fromId)
                        .collection("messages")
                        .document(toId)
                        .setData(lastMessage) { error in
                            if let error = error {
                                print("Failed to update recent_messages: \(error)")
                            }
                        }
                } else {
                    // No more messages, delete the recent_messages document
                    FirebaseManager.shared.firestore.collection("recent_messages")
                        .document(fromId)
                        .collection("messages")
                        .document(toId)
                        .delete { error in
                            if let error = error {
                                print("Failed to delete recent_messages: \(error)")
                            }
                        }
                }
            }
    }

    func blockUser(userId: String) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        let blockedUserRef = FirebaseManager.shared.firestore.collection("blocks").document(userId)

        // Add the blocked user to the current user's blocks list
        currentUserBlocksRef.setData(["blockedUserIds": FieldValue.arrayUnion([userId])], merge: true) { error in
            if let error = error {
                print("Error blocking user: \(error)")
            } else {
                print("User blocked successfully.")
                self.blockedUsers.append(userId)
                self.removeFriend (currentUserUID: currentUserId, friend_uid: userId)
            }
        }

        // Add the current user to the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayUnion([currentUserId])], merge: true) { error in
            if let error = error {
                print("Error adding blockedBy for user: \(error)")
            }
        }
    }

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
                self.blockedUsers.removeAll { $0 == userId }
            }
        }

        // Remove the current user from the blocked user's 'blockedBy' list
        blockedUserRef.setData(["blockedByIds": FieldValue.arrayRemove([currentUserId])], merge: true) { error in
            if let error = error {
                print("Error removing blockedBy for user: \(error)")
            }
        }
    }
    
    // Remove a friend from both users' friend lists
    func removeFriend(currentUserUID: String, friend_uid: String) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("friends").document(currentUserUID)
        let friendUserRef  = db.collection("friends").document(friend_uid)
        
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
                return
            }
            
            print("Successfully removed friend!")
            //delete all notifications associated with friend requests
            //self.deleteFriendRequestNotifications(user1UID: currentUserUID, user2UID: friend.uid)
        }
    }

}
extension ChatLogViewModel {
    func groupMessagesByDate() -> [String: [ChatMessage]] {
        var groupedMessages = [String: [ChatMessage]]()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy" // Example: 11/18/24

        for message in chatMessages {
            let dateKey = dateFormatter.string(from: message.timestamp.dateValue())
            if groupedMessages[dateKey] == nil {
                groupedMessages[dateKey] = []
            }
            groupedMessages[dateKey]?.append(message)
        }

        return groupedMessages
    }
}
