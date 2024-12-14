//
//  IndividualPostView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import SDWebImageSwiftUI

// SwiftUI view representing the detailed view of an individual post
struct IndividualPostView: View {
    // State object to manage the view model's state
    @StateObject private var viewModel: IndividualPostViewModel

    // Initializer for setting up the view model
    init(post: Post, likesCount: Int, liked: Bool) {
        _viewModel = StateObject(wrappedValue: IndividualPostViewModel(post: post, likesCount: likesCount, liked: liked))
    }
    
    var body: some View {
        // Main scrollable container for the post view
        ScrollView {
            VStack(spacing: 0) {
                headerSection    // Displays user profile and post header
                imageSection    // Displays images associated with the post
                interactionBar    // Interaction buttons like Like and Location
                    .padding(.vertical, 12)
                if !viewModel.post.description.isEmpty {
                    descriptionSection    // Shows the post description if available
                }
                Divider()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                commentsSection    // Displays comments on the post
            }
        }
        .overlay(alignment: .bottom) {
            commentInputSection    // Input section for adding comments
                .background(AppTheme.background)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchInitialData()    // Fetches initial data when the view appears
        }
    }

    // Header section showing the profile image, username, and timestamp
    private var headerSection: some View {
        HStack(spacing: 12) {
            profileImage    // User profile image
            VStack(alignment: .leading, spacing: 2) {
                NavigationLink(destination: ProfileView(user_uid: viewModel.post.uid)) {
                    Text(viewModel.post.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryPurple)
                }
                Text(viewModel.timeAgo)    // Post timestamp
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.background)
    }

    // Profile image or placeholder if the URL is unavailable
    private var profileImage: some View {
        Group {
            // Use a conditional to check if the user profile image URL is valid
            if let imageUrl = URL(string: viewModel.post.userProfileImageUrl) {
                // Display the profile image if the URL is valid
                WebImage(url: imageUrl)
                    .resizable()             // Makes the image resizable
                    .scaledToFill()     // Scales the image to fill the frame without distortion
                    .frame(width: 40, height: 40)   // Sets the image dimensions to 40x40
                    .clipShape(Circle())        // Clips the image into a circular shape
                    .overlay(Circle().stroke(AppTheme.lightPurple, lineWidth: 2))
                // Adds a circular purple border with a 2-point line width around the image
            } else {
                // If the URL is invalid, display a placeholder image
                Image(systemName: "person.circle.fill")
                    .resizable()                 // Makes the placeholder image resizable
                    .frame(width: 40, height: 40)    // Sets the placeholder image dimensions to 40x40
                    .foregroundColor(AppTheme.secondaryText)    // Sets the color of the placeholder icon
                    .clipShape(Circle())        // Clips the placeholder image into a circular shape
                    .overlay(Circle().stroke(AppTheme.lightPurple, lineWidth: 2))
                // Adds a circular purple border with a 2-point line width around the placeholder
            }
        }
    }

    // Tabview of the images posted
    private var imageSection: some View {
        TabView {
            // Iterates through the indices of the image URLs in the post
            ForEach(viewModel.post.imageUrls.indices, id: \.self) { index in
                Group {
                    // Checks if the URL at the current index is valid
                    if let imageUrl = URL(string: viewModel.post.imageUrls[index]) {
                        // Displays the image from the valid URL
                        WebImage(url: imageUrl)
                            .resizable()            // Makes the image resizable
                            .scaledToFill()     // Ensures the image fills the frame proportionally
                            .frame(maxWidth: .infinity)      // Makes the image fill the available width
                            .frame(height: 400)     // Sets the image height to 400
                            .clipped()      // Crops any part of the image that overflows the frame
                    } else {
                        // Displays a placeholder icon if the URL is invalid
                        Image(systemName: "photo")
                            .resizable()             // Makes the placeholder icon resizable
                            .scaledToFit()          // Scales the icon to fit within the frame proportionally
                            .frame(maxWidth: .infinity)     // Makes the placeholder fill the available width
                            .frame(height: 400)     // Sets the placeholder height to 400
                            .foregroundColor(AppTheme.secondaryText)     // Sets the icon color
                    }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle())       // Applies a page-style tab view
        .frame(height: 400)     // Sets the height for the entire TabView
    }

    // Interaction bar for likes, location, and rating
    private var interactionBar: some View {
        HStack(spacing: 20) {        // Horizontal stack with spacing between items
            Button(action: { viewModel.toggleLike() }) {    // Calls the toggleLike() function when tapped
                HStack(spacing: 6) {    // Horizontal stack for like icon and count
                    Image(systemName: viewModel.liked ? "heart.fill" : "heart") // Displays filled heart if liked, otherwise an empty heart
                        .font(.system(size: 22))     // Sets the size of the heart icon
                        .foregroundColor(viewModel.liked ? .red : AppTheme.secondaryText)    // Red if liked, otherwise a secondary color
                    Text("\(viewModel.likesCount)") // Displays the number of likes

                        .font(.system(size: 14))    // Sets the font size of the likes count
                        .foregroundColor(AppTheme.secondaryText)    // Sets the text color to secondary
                }
            }
            // Location button with navigation link
            NavigationLink(destination: LocationPostsView(locationRef: viewModel.post.locationRef)) {
                HStack(spacing: 6) {    // Horizontal stack for location icon and address
                    Image(systemName: "mappin.circle.fill") // Map pin icon
                        .font(.system(size: 22))    // Sets the size of the map pin icon
                    Text(viewModel.post.locationAddress)    // Displays the location address
                        .font(.system(size: 14))     // Sets the font size of the address text
                        .lineLimit(1)       // Limits the address to one line
                }
                .foregroundColor(AppTheme.primaryPurple)    // Sets the text and icon color to primary purple
            }
            Spacer()    // Pushes the star rating to the right
            // Star rating display
            HStack(spacing: 4) {     // Horizontal stack for star icons
                // Star rating display
                ForEach(1...5, id: \.self) { index in   // Iterates from 1 to 5 for the stars
                    Image(systemName: index <= viewModel.post.rating ? "star.fill" : "star") // Displays filled star if index is less than or equal to rating, otherwise an empty star
                        .font(.system(size: 14))    // Sets the size of the star icon
                        .foregroundColor(index <= viewModel.post.rating ? .yellow : AppTheme.secondaryText) // Yellow for filled stars, secondary color for empty stars
                }
            }
        }
        .padding(.horizontal, 16)   // Adds horizontal padding to the entire interaction bar
    }

     // Description of the post
    private var descriptionSection: some View {
        Text(viewModel.post.description)    // Displays the post's description text
            .font(.system(size: 15))         // Sets the font size of the description text
            .foregroundColor(AppTheme.primaryText)   // Sets the text color to the primary theme color
            .frame(maxWidth: .infinity, alignment: .leading)    // Expands the width to fill the available space and aligns the text to the leading edge (left-aligned)
            .padding(16)     // Adds padding of 16 points around the text
            .background(AppTheme.background)     // Sets the background color of the section to match the theme
    }

    // Section displaying comments
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {  // Arranges the content vertically with left alignment and 16-point spacing between items
            HStack {    // Horizontal arrangement for the title and comment count
                Text("Comments")    // Displays the title for the comments section
                    .font(.system(size: 16, weight: .semibold)) // Sets the font size and weight for the title
                Spacer()    // Pushes the comment count to the far right
                Text("\(viewModel.comments.count)") // Displays the number of comments
                    .font(.system(size: 14))     // Sets the font size for the comment count
                    .foregroundColor(AppTheme.secondaryText)    // Sets the color to a secondary theme text color
            }
            .padding(.horizontal, 16)   // Adds horizontal padding to the title and count
            
            if viewModel.comments.isEmpty { // Checks if there are no comments
                // Placeholder for empty comments
                Text("No comments yet")      // Displays a placeholder text when there are no comments
                    .font(.system(size: 14))        // Sets the font size for the placeholder
                    .foregroundColor(AppTheme.secondaryText)    // Sets the color to a secondary theme text color
                    .padding(.horizontal, 16)   // Adds horizontal padding
                    .padding(.top, 8)   // Adds top padding for spacing
            } else {
                // List of comments
                ForEach(viewModel.comments) { comment in    // Loops through each comment in the `comments` array
                    CommentRow(// Displays a row for each comment
                                comment: comment, // Passes the current comment to the row
                               userData: viewModel.userData[comment.userID], // Passes user data associated with the comment
                               onDelete: { viewModel.deleteComment(comment) }, // Handles the deletion of the comment
                               onLike: { viewModel.toggleLikeForComment(comment) }) // Handles liking/unliking the comment
                }
            }
        }
        .padding(.bottom, 60)    // Adds bottom padding to create space between the comments section and other content
    }

    // Section for adding comments
    private var commentInputSection: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Group {
                    if let imageUrl = viewModel.currentUserProfileImageUrl,
                       let url = URL(string: imageUrl),
                       !imageUrl.isEmpty {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .foregroundColor(AppTheme.secondaryText)
                            .clipShape(Circle())
                    }
                }
                TextField("Add a comment...", text: $viewModel.commentText)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppTheme.secondaryBackground)
                    .cornerRadius(20)
                Button(action: { viewModel.showEmojiPicker.toggle() }) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Button(action: viewModel.addComment) {
                    Text("Post")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryPurple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if viewModel.showEmojiPicker {
                // Emoji picker view for comments
                EmojiPickerView(text: $viewModel.commentText, showPicker: $viewModel.showEmojiPicker)
                    .transition(.identity)
            }
        }
    }
    
    // MARK: - Supporting Views

    // View for each individual comment displayed
    private struct CommentRow: View {
        let comment: Comment
        let userData: (username: String, profileImageUrl: String?)?
        let onDelete: () -> Void
        let onLike: () -> Void
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                // User Image
                Group {
                    if let profileUrl = userData?.profileImageUrl,
                       let url = URL(string: profileUrl),
                       !profileUrl.isEmpty {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .foregroundColor(AppTheme.secondaryText)
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(userData?.username ?? "Unknown User")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(comment.text)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(comment.timestampString ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                // Like and Delete buttons
                HStack(spacing: 12) {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: comment.likedByCurrentUser ? "heart.fill" : "heart")
                                .foregroundColor(comment.likedByCurrentUser ? .red : AppTheme.secondaryText)
                            Text("\(comment.likeCount)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    if comment.userID == FirebaseManager.shared.auth.currentUser?.uid {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // View for adding emojis to the comment
    private struct EmojiPickerView: View {
        @Binding var text: String       // Binds to the text that the emoji will be appended to
        @Binding var showPicker: Bool    // Binds to the state that controls whether the emoji picker is visible


        let emojis = [
           
            "😀", "😂", "😍", "😎", "😢", "😡", "🥳", "🤔", "🤗", "🤩", "🙄", "😳",
            "👍", "👎", "💀", "🫣", "🤯", "😴", "😇", "🥰", "😱", "🤮", "😵", "😈",
            "👻", "😜", "😬", "🤠", "🤑", "🥴", "🫡", "🫠", "😌", "😋", "🫢", "🤡",
            "😭", "😅", "😤", "🤤", "😐", "😶", "🤥", "😶‍🌫️", "😲", "😷", "🤧", "🤒",

            
            "🐶", "🐱", "🐼", "🦄", "🦉", "🦋", "🐙", "🐢", "🦥", "🦈", "🦓", "🦀",
            "🦜", "🪲", "🪸", "🐳", "🐊", "🦩", "🐉", "🦧", "🦦", "🪿", "🐇", "🐓",
            "🦅", "🪱", "🪰", "🕊️", "🐝", "🐾", "🐔",

            
            "🌸", "🌍", "🌞", "🌊", "🌵", "🌋", "🌌", "🌈", "⛰️", "🏔️", "🪵", "🍂",
            "🌿", "🌲", "🌳", "☘️", "🌾", "🌬️", "🪹", "🪷", "💐", "🪻", "🦚",

            
            "🍕", "🍩", "🍔", "🍎", "🍷", "🧋", "🍿", "🥑", "🥗", "🍓", "🍇", "🍪",
            "🍫", "🍬", "🥨", "🍟", "🌭", "🍗", "🥓", "🍣", "🍤", "🧁", "🫛",
            "🍉", "🥥", "🫖", "🍸", "🥮",

           
            "🚗", "✈️", "🚀", "🛸", "🛤️", "🏝️", "🏰", "🎢", "🗽", "🗼", "🏜️", "🏕️",
            "🏟️", "🏖️", "🚂", "🛳️", "⛵️", "🚠", "🚞", "🗺️", "🌅", "🌠", "🎇",

           
            "🎵", "🎨", "📚", "🖥️", "📱", "💡", "💰", "📅", "📸", "🔑", "📖", "🧸",
            "💣", "🧪", "🪴", "🪔", "🛍️", "🛏️", "🪩", "🖊️", "📔", "🎙️", "🎤", "🎧",
            "🪞", "🪜", "🧳", "🔨", "🛠️", "⚙️", "🪚", "🔧", "🔗", "📦",

            
            "🎮", "🎭", "🏀", "⚽️", "🏈", "🏓", "🎯", "🪁", "🏋️‍♀️", "🏇", "🏂", "🛹",
            "🏄‍♂️", "🚴‍♀️", "🧘‍♂️", "🎣", "🤹‍♀️", "🧗‍♂️", "🤼‍♂️", "🎻", "🎷",
            "🥋", "🪂", "🎽", "🏌️‍♀️",

           
            "❤️", "✨", "🌟", "⚡️", "🔥", "💧", "🎉", "🎊", "🪄", "🔮", "🪦", "☠️",
            "🛡️", "🏆", "🎲", "🃏", "🪙",  "🕹️", "📡", "🧿", "🎶"
        ]

        var body: some View {
            ScrollView {    // Allows scrolling through the emoji grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), // Creates a grid with 6 columns and flexible spacing
                    spacing: 10 // Vertical spacing between rows
                ) {
                    
                    ForEach(emojis + Array(repeating: " ", count: (6 - emojis.count % 6) % 6),  // Adds padding spaces to fill out the last row
                        id: \.self  // Ensures unique IDs for each item
                    ) { emoji in
                        Button(action: {     // Button for selecting an emoji
                            if emoji != " " {       // Ensures padding spaces are not interactive
                                text += emoji       // Appends the selected emoji to the bound text
                                showPicker = false  // Hides the picker after an emoji is selected
                            }
                        }) {
                            Text(emoji)         // Displays the emoji
                                .font(.system(size: 30))        // Sets the font size for the emoji
                                .frame(width: 40, height: 40)   // Sets a fixed size for each emoji button
                                .background(emoji == " " ? Color.clear : Color.gray.opacity(0.1))    // Adds a light gray background for emojis, none for padding spaces
                                .cornerRadius(5)    // Rounds the corners of the button
                        }
                        .padding(5) // Adds padding around each button
                    }
                }
                .padding([.top, .horizontal])   // Adds padding around the grid
            }
            .background(AppTheme.background)    // Sets the background color of the emoji picker
        }
    }
}
