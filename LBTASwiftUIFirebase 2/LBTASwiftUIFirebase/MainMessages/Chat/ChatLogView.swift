//
//  ChatLogView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 07/10/2024.
//

import SwiftUI
import Firebase

struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let profileImageUrl = "profileImageUrl"
    static let email = "email"
}

struct ChatMessage: Identifiable {
    var id: String { documentId }
    
    let documentId: String
    let fromId, toId, text: String
    let timestamp: Timestamp
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
    }
}

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var blockedUsers: [String] = []
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchBlockedUsers()
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }

        if blockedUsers.contains(toId) {
            print("You cannot see messages from this user as you are blocked.")
            return
        }

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

                    if let messageSenderId = data[FirebaseConstants.fromId] as? String, !self.blockedUsers.contains(messageSenderId) {
                        self.chatMessages.append(.init(documentId: docId, data: data))
                    }
                }
            }
    }
    
    private func fetchBlockedUsers() {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("blocks").document(userId)
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

    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }

        if blockedUsers.contains(toId) {
            print("You are blocked by this user. You cannot send messages.")
            return
        }

        if let recipientBlockedUsers = chatUser?.blockedUsers, recipientBlockedUsers.contains(fromId) {
            print("You have blocked this user.")
            return
        }

        let messageData = [
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.timestamp: Timestamp()
        ] as [String: Any]
        
        let document = FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            print("Successfully saved current user sending message")
            self.persistRecentMessage()
            self.chatText = ""
        }
        
        let recipientMessagesDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessagesDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            print("Recipient saved message as well")
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
                }
            }
    }

    func blockUser(userId: String) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let blocksDocument = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        
        blocksDocument.setData(["blockedUserIds": FieldValue.arrayUnion([userId])], merge: true) { error in
            if let error = error {
                print("Error blocking user: \(error)")
            } else {
                print("User blocked successfully.")
                self.blockedUsers.append(userId)
            }
        }
    }
    
    func unblockUser(userId: String) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let blocksDocument = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        
        blocksDocument.setData(["blockedUserIds": FieldValue.arrayRemove([userId])], merge: true) { error in
            if let error = error {
                print("Error unblocking user: \(error)")
            } else {
                print("User unblocked successfully.")
                self.blockedUsers.removeAll { $0 == userId }
            }
        }
    }
}

struct ChatLogView: View {
    let chatUser: ChatUser?
    
    @ObservedObject var vm: ChatLogViewModel
    @State private var showEmojiPicker = false
    @State private var selectedEmoji: String = ""
    @State private var isNavigating = false // Tracks the state of navigation
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }

    var body: some View {
        VStack {
            messagesView
            
            if showEmojiPicker {
                emojiPicker
                    .animation(.easeInOut)
            }
            
            chatBottomBar
            
            Button(action: {
                if let userId = chatUser?.uid {
                    if vm.blockedUsers.contains(userId) {
                        vm.unblockUser(userId: userId)
                    } else {
                        vm.blockUser(userId: userId)
                    }
                }
            }) {
                Text(vm.blockedUsers.contains(chatUser?.uid ?? "") ? "Unblock User" : "Block User")
                    .foregroundColor(.red)
            }
            .padding()
        }
        //.navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        // Set the left bar button to make the email clickable
        // Use toolbar modifier to center the email
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Spacer() // To center the content
                    if let email = chatUser?.email {
                        Button(action: {
                            // Set the navigation state to true when the email is tapped
                            self.isNavigating = true
                        }) {
                            Text(email) // Make the email clickable
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.purple)
                        }
                    }
                    Spacer() // To center the content
                }
            }
        }
        // Use a NavigationLink triggered programmatically by `isNavigating`
        .background(
            NavigationLink(
                destination: ProfileView(uid: chatUser?.uid ?? ""),
                isActive: $isNavigating
            ) {
                EmptyView() // NavigationLink content is invisible; it only triggers navigation
            }
            .hidden() // Hide the NavigationLink content to avoid extra UI elements
        )

    }
    
    private var messagesView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                ForEach(vm.chatMessages) { message in
                    MessageView(message: message) { messageId in
                        vm.deleteMessage(messageId)
                    }
                    .id(message.id)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: vm.chatMessages.count) { _ in
                    scrollToBottom(scrollViewProxy: scrollViewProxy)
                }
            }
            .background(Color(.init(white: 0.95, alpha: 1)))
        }
    }
    
    private func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let lastMessage = vm.chatMessages.last {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation {
                    showEmojiPicker.toggle()
                }
            }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 24))
                    .foregroundColor(Color(.darkGray))
            }
            
            ZStack(alignment: .leading) {
                if vm.chatText.isEmpty {
                    Text("Type your message...")
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                TextEditor(text: $vm.chatText)
                    .frame(height: 40)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
                    .onChange(of: selectedEmoji) { newEmoji in
                        if !newEmoji.isEmpty {
                            vm.chatText += newEmoji
                            selectedEmoji = ""  // Clear the selected emoji after adding
                        }
                    }
            }
            
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var emojiPicker: some View {
        let emojis: [String] = ["😀", "😂", "😍", "😎", "😢", "😡", "🥳", "🤔", "🤗", "🤩", "🙄", "😳"]
        
        return VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                        showEmojiPicker = false
                    }) {
                        Text(emoji)
                            .font(.largeTitle)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
}

struct MessageView: View {
    let message: ChatMessage
    let onDelete: (String) -> Void // Closure to handle deletion
    
    var body: some View {
        Group {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                        Button(action: {
                            onDelete(message.id) // Call the delete function
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
    }
}
