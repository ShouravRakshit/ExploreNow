//
//  MainMessagesView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, -------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct MainMessagesView: View {
    @State private var shouldShowLogOutOptions = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowChangePasswordConfirmation = false
    @State private var shouldShowNewMessageScreen = false
    
    @State private var searchQuery = "" // Search query for filtering messages
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @ObservedObject private var vm = MainMessagesViewModel()
    @State private var selectedChatUser: ChatUser? // Store the selected user for navigation
    
    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                
                searchBar
                
                messagesView
                
                Spacer()
                
                // Hidden navigation link for ChatLogView
                NavigationLink(
                    destination: ChatLogView(chatUser: selectedChatUser).environmentObject(userManager),
                    isActive: $shouldNavigateToChatLogView
                ) {
                    EmptyView()
                }
            }
            .background(Color(.systemGray6))
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
                CreateNewMessageView { user in
                    self.selectedChatUser = user
                    self.shouldNavigateToChatLogView = true
                }
            }
        }
    }
    
    // MARK: - Search Bar
    // This computed property returns the UI component for the search bar in the view.
    private var searchBar: some View {
        HStack {
            // TextField for user input to search for messages or users.
            TextField("Search users...", text: $searchQuery) // Placeholder text prompts the user to search for users
                .padding(10) // Adds padding inside the text field for better spacing
                .background(Color.white) // Sets the background color of the text field to white
                .cornerRadius(10) // Applies rounded corners to the text field for a smoother look
                .overlay(
                    // Adds a border around the text field with rounded corners
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1) // The border color is gray with a line width of 1
                )
                .padding(.horizontal) // Adds horizontal padding to ensure the text field is spaced from the edges of the parent view
                .onChange(of: searchQuery) { newValue in
                    // Calls the filterMessages method of the view model when the search query changes
                    vm.filterMessages(query: newValue)
                }
        }
        .padding(.top, 10) // Adds top padding to the entire HStack to give some space from the view above
    }
    
    // MARK: - Messages View
    // This computed property defines the UI for displaying a list of messages or guiding the user to start a new chat.
    private var messagesView: some View {
        VStack {
            ScrollView {
                // If the filtered messages list is empty, show a prompt to start a new chat or show no matches found
                if vm.filteredMessages.isEmpty {
                    VStack {
                        Spacer() // Adds space at the top of the VStack
                        
                        // If the search query is empty, show a button to start a new chat
                        if searchQuery.isEmpty {
                            Button(action: {
                                shouldShowNewMessageScreen = true // Show new message screen when button is tapped
                            }) {
                                Text("Click here to start a new chat")
                                    .foregroundColor(.blue) // Text color is blue for the button
                                    .font(.system(size: 16, weight: .semibold)) // Sets the font size and weight
                            }
                        } else {
                            // If the search query is not empty, show "No matches found."
                            Text("No matches found.")
                                .foregroundColor(.gray) // Sets text color to gray for no results
                                .font(.system(size: 16, weight: .semibold)) // Font styling for the message
                        }
                        
                        Spacer() // Adds space at the bottom of the VStack
                    }
                } else {
                    // If there are filtered messages, display them in a list using ForEach
                    ForEach(vm.filteredMessages) { recentMessage in
                        VStack {
                            // Button for selecting a message, navigating to the chat screen
                            Button {
                                handleChatSelection(recentMessage: recentMessage) // Handles chat selection
                            } label: {
                                HStack(spacing: 16) {
                                    // Profile image of the user in the message, using WebImage for remote images
                                    WebImage(url: URL(string: recentMessage.profileImageUrl))
                                        .resizable() // Makes the image resizable
                                        .scaledToFill() // Scales the image to fill the frame
                                        .frame(width: 50, height: 50) // Sets the width and height of the image
                                        .clipped() // Clips any overflowing parts of the image
                                        .cornerRadius(25) // Makes the image circular by applying corner radius
                                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color(.label), lineWidth: 1)) // Adds a border around the image
                                    
                                    // Message content, including the sender's name and message text
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(recentMessage.name ?? "") // Displays the sender's name
                                            .font(.system(size: 16, weight: .bold)) // Sets the font size and weight for the name
                                            .foregroundColor(Color(.label)) // Sets the text color
                                        Text(recentMessage.text) // Displays the message text
                                            .font(.system(size: 14)) // Sets the font size for the message
                                            .foregroundColor(Color(.darkGray)) // Sets the message text color
                                            .lineLimit(1) // Limits the text to one line
                                    }
                                    Spacer() // Adds space between message details and timestamp
                                    
                                    // Timestamp showing the time when the message was sent
                                    Text(vm.timeAgo(recentMessage.timestamp.dateValue()))
                                        .font(.system(size: 14, weight: .semibold)) // Font style for timestamp
                                        .foregroundColor(Color(.lightGray)) // Sets the timestamp color to light gray
                                }
                                .padding(.horizontal) // Adds horizontal padding inside the HStack
                            }
                            
                            // Divider between each message
                            Divider()
                        }
                        .padding(.vertical, 8) // Adds vertical padding around each message
                    }
                }
            }
        }
    }
    
    
    // MARK: - Custom Nav Bar
    // This computed property defines a custom navigation bar view that includes the current user's profile image, their name,
    // an online status indicator, and a button to start a new message.
    private var customNavBar: some View {
        HStack(spacing: 16) {
            // Display the user's profile image if the current user is available
            if let currentUser = userManager.currentUser {
                // Navigation link that redirects to the ProfileView when tapped
                NavigationLink(destination: ProfileView(user_uid: currentUser.uid)) {
                    WebImage(url: URL(string: currentUser.profileImageUrl ?? "")) // Loads the user's profile image from the URL
                        .resizable() // Makes the image resizable
                        .scaledToFill() // Ensures the image scales to fill the frame
                        .frame(width: 50, height: 50) // Sets the width and height of the profile image
                        .clipped() // Clips any excess portion of the image that overflows
                        .cornerRadius(44) // Rounds the corners of the image to make it circular
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1)) // Adds a border around the image with a custom purple color
                        .shadow(radius: 5) // Adds a shadow effect to the image for better visibility
                }
            } else {
                // Display a loading state if the current user is not available (e.g., waiting for data to load)
                Text("Loading...") // Placeholder text displayed while the user data is loading
                    .font(.system(size: 16, weight: .medium)) // Set the font size and weight for the loading text
            }
            
            // Display the user's name and online status below the profile image
            VStack(alignment: .leading, spacing: 4) {
                let name = userManager.currentUser?.name ?? "" // Fetches the user's name or an empty string if not available
                Text(name) // Displays the user's name
                    .font(.system(size: 24, weight: .bold)) // Sets the font size and weight for the name
                HStack {
                    // Green circle to indicate online status
                    Circle()
                        .foregroundColor(.green) // Sets the circle color to green
                        .frame(width: 14, height: 14) // Sets the size of the circle
                    Text("online") // Displays "online" text next to the circle
                        .font(.system(size: 12)) // Sets the font size for the online text
                        .foregroundColor(Color(.lightGray)) // Sets the color of the text to light gray
                }
            }
            
            Spacer() // Adds flexible space to push the content to the left
            
            // New Message Button
            Button(action: {
                shouldShowNewMessageScreen = true // Trigger the new message screen when the button is tapped
            }) {
                // Icon for the new message button, using the system "square.and.pencil" image
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24, weight: .bold)) // Sets the font size and weight for the icon
                    .foregroundColor(Color(.label)) // Sets the color of the icon to match the system text color
            }
        }
        .padding() // Adds padding around the entire navigation bar to space out the elements
    }
    
    
    // MARK: - Helper Functions
    
    // This function handles the selection of a recent message in the messages list. It determines the appropriate chat partner
    // (the user on the other end of the conversation), prepares the necessary data for that user, and triggers navigation
    // to the chat log view for the selected chat.
    private func handleChatSelection(recentMessage: RecentMessage) {
        // Determine the UID of the other user in the conversation.
        // If the current user is the sender of the message, we use the recipient's UID, and vice versa.
        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
        
        // Create a dictionary with the user data necessary for the chat, including UID, email, profile image URL, and name.
        let data = [
            "uid": uid,
            "email": recentMessage.email,
            "profileImageUrl": recentMessage.profileImageUrl,
            "name": recentMessage.name
        ]
        
        // Create a `ChatUser` object from the provided data to represent the user for the selected chat.
        self.selectedChatUser = ChatUser(data: data)
        
        // Set the flag to trigger navigation to the chat log view, where the user can see the conversation.
        self.shouldNavigateToChatLogView = true
    }
    
}
