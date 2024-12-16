//
//  ChatLogView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

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
        // Initialize the chatUser property with the passed argument
        self.chatUser = chatUser
        
        // Initialize the ViewModel using StateObject to ensure it persists during the lifecycle of the view
        _vm = StateObject(wrappedValue: ChatLogViewModel(chatUser: chatUser))
        
        // Customizing the appearance of the UINavigationBar
        let appearance = UINavigationBarAppearance()  // Create a new UINavigationBarAppearance instance
        
        // Configure the appearance with a default background style
        appearance.configureWithDefaultBackground()

        // Set the title text attributes for normal button state (e.g., for navigation bar buttons)
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        // Set the title text attributes for the back button (when navigating back)
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        // Set the back indicator image for the navigation bar (back button) and its transition mask
        appearance.setBackIndicatorImage(
            UIImage(systemName: "chevron.left")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal),
            transitionMaskImage: UIImage(systemName: "chevron.left")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        )
        
        // Set the tint color of the navigation bar's elements (including back button) to system blue
        UINavigationBar.appearance().tintColor = .systemBlue
        
        // Apply the customized appearance to different navigation bar states (standard, compact, scroll edge)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        VStack {
            // Displaying the main messages view
            messagesView
            
            // Conditionally showing the emoji picker based on the showEmojiPicker flag
            if showEmojiPicker {
                emojiPicker
                    .animation(.easeInOut) // Smooth transition for the emoji picker
            }
            
            // Displaying the chat bottom bar
            chatBottomBar
            
            // Button to toggle blocking or unblocking the user
            Button(action: {
                if let userId = chatUser?.uid {
                    // Check if the current user is blocked
                    if vm.blockedUsers.contains(userId) {
                        vm.unblockUser(userId: userId) // Unblock user if already blocked
                    } else {
                        vm.blockUser(userId: userId) // Block user if not already blocked
                    }
                }
            }) {
                // Button text is based on whether the user is blocked or not
                Text(vm.blockedUsers.contains(chatUser?.uid ?? "") ? "Unblock User" : "Block User")
                    .foregroundColor(.red) // Color is red to indicate block/unblock action
            }
            .padding()
        }
        
        // Customizing the navigation bar
        .navigationTitle("") // Empty title for the navigation bar (no title displayed)
        .navigationBarTitleDisplayMode(.inline) // Navigation title in inline mode (smaller)
        .navigationBarBackButtonHidden(false) // Ensure the back button is visible
        .toolbar {
            ToolbarItem(placement: .principal) {
                // Conditionally display a button with the user's name in the navigation bar
                if let name = chatUser?.name {
                    Button(action: {
                        // Trigger navigation when the user's name is tapped
                        self.isNavigating = true
                    }) {
                        // Display the name in the navigation bar, making it clickable
                        Text(name)
                            .font(.system(size: 20, weight: .bold)) // Styling the name text
                            .foregroundColor(.customPurple) // Custom purple color for the name
                            .frame(maxWidth: .infinity, alignment: .center) // Center the text horizontally
                    }
                }
            }
        }
        // Programmatically triggering navigation when isNavigating is true
        .background(
            NavigationLink(
                destination: ProfileView(user_uid: chatUser?.uid ?? ""), // Destination view when navigation occurs
                isActive: $isNavigating // Binding to isNavigating state to trigger navigation programmatically
            ) {
                EmptyView() // The content of the NavigationLink is invisible. It only triggers navigation when isNavigating is true
            }
        )
        // Monitoring changes to the chatUser and updating the view when it changes
        .onChange(of: chatUser) { newUser in
            if let user = newUser {
                print("User changed, reloading messages for \(user.name)") // Print log when a new user is selected
                vm.setChatUser(user)  // Update the ViewModel with the new user to reload messages or other user-related data
            } else {
                print("No user selected, cannot reload messages")  // If no user is selected, print a message indicating that messages cannot be reloaded
            }
        }
    }

    
    private var messagesView: some View {
        ScrollViewReader { scrollViewProxy in
            // Check if there are any chat messages
            if vm.chatMessages.isEmpty {
                // Empty state view if there are no messages
                VStack {
                    Spacer()
                    Text("No messages yet") // Display message when no messages are available
                        .foregroundColor(.gray) // Gray text color for the empty state
                        .font(.system(size: 16)) // Font size for the text
                    Spacer()
                }
            } else {
                // Show messages if available
                ScrollView {
                    // Group the messages by date using the ViewModel
                    let groupedMessages = vm.groupMessagesByDate()
                    // Loop through each date and its corresponding messages
                    ForEach(groupedMessages.keys.sorted(), id: \.self) { date in
                        VStack(alignment: .leading, spacing: 12) {
                            // Date Header
                            Text(date)
                                .font(.footnote) // Smaller font size for the date
                                .foregroundColor(.gray) // Gray text for the date
                                .padding(.leading) // Padding to the left
                                .frame(maxWidth: .infinity) // Ensure the frame takes up maximum width
                                .multilineTextAlignment(.center) // Center the text for the date
                                .padding(.top, 8) // Padding at the top of the date header
                            
                            // Messages for the specific date
                            ForEach(groupedMessages[date] ?? []) { message in
                                MessageView(message: message, onDelete: { messageId in
                                    vm.deleteMessage(messageId) // Provide delete functionality for each message
                                })
                            }
                        }
                    }
                    //T
                    .padding(.horizontal) // Horizontal padding for the messages view
                    .padding(.top, 8) // Padding at the top
                    .onChange(of: vm.chatMessages.count) { _ in
                        // Scroll to the bottom of the chat when messages count changes
                        scrollToBottom(scrollViewProxy: scrollViewProxy)
                    }
                }
                .background(Color(.init(white: 0.95, alpha: 1))) // Light gray background for the messages area
            }
        }
    }

    
    // Function to scroll to the bottom of the ScrollView programmatically
    private func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        // Ensures the scroll happens on the main thread to avoid UI-related issues
        DispatchQueue.main.async {
            // Check if there are any messages in the chat
            if let lastMessage = vm.chatMessages.last {
                // Scroll to the last message using its ID as the target for scrolling
                // The 'anchor' parameter is set to '.bottom' to align the last message at the bottom of the screen
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    
    private var chatBottomBar: some View {
        HStack {
            // Check if the current user has blocked the chatUser
            if vm.blockedUsers.contains(chatUser?.uid ?? "") {
                Spacer() // Add space before the text
                Text("You have blocked this person.")  // Display a message if the user has blocked this person
                    .foregroundColor(.red) // Red text to highlight the blocked status
                    .font(.system(size: 16, weight: .bold)) // Bold font with a reasonable size
                    .multilineTextAlignment(.center) // Center-align the text
                Spacer() // Add space after the text
            }
            // Check if the current user is blocked by the chatUser
            else if vm.blockedByUsers.contains(chatUser?.uid ?? "") {
                Spacer() // Add space before the text
                Text("You can't message this person.")  // Display a message if the user cannot message this person
                    .foregroundColor(.red) // Red text to show restriction
                    .font(.system(size: 16, weight: .bold)) // Bold font with reasonable size
                    .multilineTextAlignment(.center) // Center-align the text
                Spacer() // Add space after the text
            }
            else {
                // Emoji Picker Button - toggle the emoji picker visibility when tapped
                Button(action: {
                    withAnimation {  // Apply animation for toggling the emoji picker
                        showEmojiPicker.toggle()  // Toggle the emoji picker visibility
                    }
                }) {
                    Image(systemName: "face.smiling")  // System emoji icon for smiling face
                        .font(.system(size: 24)) // Icon size of 24 points
                        .foregroundColor(Color(.darkGray)) // Set color to dark gray
                }
                
                // Message input area - TextEditor for typing messages
                ZStack(alignment: .leading) {
                    // Placeholder text for the message input field when it's empty
                    if vm.chatText.isEmpty {
                        Text("Type your message...")  // Placeholder message
                            .foregroundColor(.gray)  // Light gray color for the placeholder
                            .padding(.leading, 5)  // Add padding on the left side to align the placeholder
                    }
                    // TextEditor for inputting the message
                    TextEditor(text: $vm.chatText)  // Bind the chat text to vm.chatText
                        .frame(height: 40)  // Set the height of the text field
                        .opacity(vm.chatText.isEmpty ? 0.5 : 1)  // Apply opacity to indicate when the text field is empty
                }
                
                // Send Button - Trigger the sending of the message
                Button {
                    vm.handleSend()  // Call the handleSend method to send the message
                } label: {
                    Text("Send")  // Button label text
                        .foregroundColor(.white)  // Set text color to white
                }
                .padding(.horizontal)  // Add horizontal padding for the button
                .padding(.vertical, 8)  // Add vertical padding for the button
                .background(Color.blue)  // Set background color to blue
                .cornerRadius(4)  // Round the corners of the button
            }
        }
        .padding(.horizontal)  // Add horizontal padding for the entire HStack
        .padding(.vertical, 8)  // Add vertical padding for the entire HStack
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
        
        // A VStack that contains the entire emoji picker UI
        return VStack {
            // ScrollView to allow scrolling if there are many emojis
            ScrollView {
                // LazyVGrid is used to display emojis in a flexible grid layout
                // It repeats the GridItem 4 times to create a 4-column grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    // Iterate through each emoji in the 'emojis' array
                    ForEach(emojis, id: \.self) { emoji in
                        // Button for each emoji that appends the selected emoji to chatText
                        Button(action: {
                            // Append selected emoji to the chat text
                            vm.chatText += emoji
                            // Close the emoji picker after selection
                            showEmojiPicker = false
                        }) {
                            // Display the emoji as text with a large font size
                            Text(emoji)
                                .font(.largeTitle) // Adjust the emoji size to make it large
                        }
                    }
                }
                .padding() // Add padding around the content of the ScrollView for better spacing between elements
            }
            .frame(maxHeight: 300) // Set a maximum height of 300 points for the emoji picker to prevent it from taking up too much space on the screen
            .background(Color.white) // Set a white background color for the emoji picker, making it visually distinct from the surrounding elements
            .cornerRadius(10) // Apply rounded corners with a radius of 10 points to create a softer, more modern look
            .shadow(radius: 5) // Add a subtle shadow effect with a radius of 5 to create a lifting effect, making the picker appear elevated
        }
    }
}
