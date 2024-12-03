//
//  ChatLogView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import SwiftUI
import Firebase


struct ChatLogView: View {
    var chatUser: ChatUser?
    
    @EnvironmentObject var userManager: UserManager
    @StateObject var vm: ChatLogViewModel
    @State private var showEmojiPicker = false
    @State private var selectedEmoji: String = ""
    @State private var isNavigating = false // Tracks the state of navigation
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        //self.vm = ChatLogViewModel(chatUser: chatUser)
        _vm = StateObject(wrappedValue: ChatLogViewModel(chatUser: chatUser)) // Use StateObject to persist the ViewModel
        
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
        .onChange(of: chatUser) { newUser in
            // Safely unwrap the chatUser before accessing its properties
            if let user = newUser {
                print("User changed, reloading messages for \(user.name)")
                vm.setChatUser (user)
            } else {
                print("No user selected, cannot reload messages")
            }
        }
        
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
                    let groupedMessages = vm.groupMessagesByDate()
                    ForEach(groupedMessages.keys.sorted(), id: \.self) { date in
                        VStack(alignment: .leading, spacing: 12) {
                            // Date Header
                            Text(date)
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.leading)
                                .frame(maxWidth: .infinity) // Expand the frame
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                            
                            // Messages for the specific date
                            ForEach(groupedMessages[date] ?? []) { message in
                                MessageView(message: message, onDelete: { messageId in
                                    vm.deleteMessage(messageId)
                                })
                            }
                        }
                    }
                    //T
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
        let emojis: [String] = [
            // Smileys & Emotions
            "😀", "😂", "😍", "😎", "😢", "😡", "🥳", "🤔", "🤗", "🤩", "🙄", "😳", "😇", "😉", "😋", "😜", "🤪",
            "🥰", "😱", "😴", "🤤", "😭", "😅", "🤓", "😞", "😩", "😤",
            
            // Animals & Nature
            "🐶", "🐱", "🐭", "🐰", "🦊", "🐻", "🐼", "🐸", "🐷", "🐵", "🐦", "🐧", "🦉", "🐳", "🦄", "🐝", "🐢", "🐬", "🐙",
            
            // Food & Drink
            "🍎", "🍌", "🍓", "🍉", "🍒", "🍔", "🍕", "🍩", "🍿", "🍪", "🌮", "🥗", "🍣", "🍱", "🥤", "☕", "🍇", "🥪", "🥞",
            
            // Activities & Objects
            "⚽", "🏀", "🏈", "🎾", "🏓", "🥋", "🎤", "🎮", "🎹", "🎨", "🧵", "🎬", "🎧", "🎯", "🎷", "🎻", "🏆", "🎟️", "🎲",
            
            // Travel & Places
            "🚗", "✈️", "🚀", "🚂", "🚤", "🛳️", "🏠", "🏔️", "🗽", "🏝️", "🏙️", "🏨", "⛺", "🗿",
            
            // Symbols
            "❤️", "💔", "🔥", "⭐", "🌈", "☀️", "⚡", "❄️", "💧", "🌍", "✨", "🎉", "🛑", "✔️", "➕", "➖", "♻️", "🔔", "🔒", "🔑",
            
            // Flags
            "🇺🇸", "🇬🇧", "🇨🇦", "🇮🇳", "🇦🇺", "🇫🇷", "🇩🇪", "🇯🇵", "🇧🇷", "🇰🇷", "🇨🇳", "🇮🇹"
        ]
        
        return VStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            vm.chatText += emoji
                            showEmojiPicker = false // Close picker after selection
                        }) {
                            Text(emoji)
                                .font(.largeTitle)
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300) // Limit the height of the picker for better UI
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
}
