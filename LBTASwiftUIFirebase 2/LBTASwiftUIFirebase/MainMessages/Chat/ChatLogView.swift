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
    @EnvironmentObject var userManager: UserManager
    @Published var blockedByUsers: [String] = []

    let chatUser: ChatUser?
    
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
    
    
    private func fetchMessages() {
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

}

struct ChatLogView: View {
    let chatUser: ChatUser?
    
    @EnvironmentObject var userManager: UserManager
    @ObservedObject var vm: ChatLogViewModel
    @State private var showEmojiPicker = false
    @State private var selectedEmoji: String = ""
    @State private var isNavigating = false // Tracks the state of navigation
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = ChatLogViewModel(chatUser: chatUser)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]

        appearance.setBackIndicatorImage(UIImage(systemName: "chevron.left")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal),
                                       transitionMaskImage: UIImage(systemName: "chevron.left")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal))
        
        UINavigationBar.appearance().tintColor = .systemBlue // This sets the back button color
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
        
        
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
//        .navigationBarTitle("", displayMode: .inline) // Optional, customize
        .toolbar {
            ToolbarItem(placement: .principal) {
//                HStack {
                    //Spacer() // To center the content
                    if let name = chatUser?.name {
                        Button(action: {
//                            // Set the navigation state to true when the email is tapped
                            self.isNavigating = true
                        }) {
                            Text(name) // Make the email clickable
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.customPurple)
                                .frame(maxWidth: .infinity, alignment: .center) // Ensure the username takes all available width and is centered
                        }
                        

                    }
                    //Spacer() // To center the content
//                }
            }
        }
//         Use a NavigationLink triggered programmatically by `isNavigating`
        .background(
            NavigationLink(
                destination: ProfileView(user_uid: chatUser?.uid ?? ""),
                isActive: $isNavigating
            ) {
                EmptyView() // NavigationLink content is invisible; it only triggers navigation
            }

        )

    }
    
    private var messagesView: some View {
        ScrollViewReader { scrollViewProxy in
            if vm.chatMessages.isEmpty {
                // Empty state view
                VStack {
                    Spacer()
                    Text("No messages yet")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                    Spacer()
                }
            } else {
                // Show messages if available
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
    }

    
    private func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let lastMessage = vm.chatMessages.last {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    

    private var chatBottomBar: some View {
        HStack {
            if vm.blockedUsers.contains(chatUser?.uid ?? "") {
                Spacer()
                Text("You have blocked this person.")
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                Spacer()
            } else if vm.blockedByUsers.contains(chatUser?.uid ?? "") {
                Spacer()
                Text("You can't message this person.")
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
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
