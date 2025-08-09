//
//  IndividualPostView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, -----------, Manvi Juneja,
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
    private var commentInputSection: some View {     // Declares a computed property that returns a View, used for the comment input section.
        VStack(spacing: 0) {         // A vertical stack (VStack) to arrange the following views vertically, with no space between them.
            Divider()        // Adds a horizontal divider line to separate sections visually.
            HStack(spacing: 12) {       // A horizontal stack (HStack) to arrange the following views horizontally with 12 points of space between them.
                Group {         // Group is used to group multiple views together, allowing you to apply modifiers collectively.
                    if let imageUrl = viewModel.currentUserProfileImageUrl,     // If `currentUserProfileImageUrl` has a valid URL string...
                       let url = URL(string: imageUrl),     // Convert the string to a URL object.
                       !imageUrl.isEmpty {           // Ensure the image URL is not empty.
                        WebImage(url: url)           // Use a custom `WebImage` component to load and display the image from the URL.
                            .resizable()              // Makes the image resizable to fit within a defined frame.
                            .scaledToFill()          // Ensures the image fills the frame and may be cropped if needed.
                            .frame(width: 32, height: 32)        // Sets the image frame size to 32x32 points.
                            .clipShape(Circle())          // Clips the image into a circular shape.
                    } else {      // If no valid image URL exists...
                        Image(systemName: "person.circle.fill")      // Use a default system image, "person.circle.fill", to represent the user profile.
                            .resizable()             // Makes the default image resizable to fit within a defined frame.
                            .scaledToFill()     // Ensures the image fills the frame and may be cropped if needed
                            .frame(width: 32, height: 32)        // Sets the image frame size to 32x32 points.
                            .foregroundColor(AppTheme.secondaryText)    // Sets the image color using a custom theme color (`secondaryText`).
                            .clipShape(Circle())         // Clips the default image into a circular shape.
                    }
                }
                TextField("Add a comment...", text: $viewModel.commentText)   // Creates a text field with the placeholder "Add a comment..." and binds its text value to `viewModel.commentText`.
                    .textFieldStyle(.plain)     // Applies a plain text field style (no background or borders).
                    .padding(.vertical, 8)      // Adds vertical padding (8 points) inside the text field, creating space above and below the text.
                    .padding(.horizontal, 12)       // Adds horizontal padding (12 points) inside the text field, creating space on the left and right sides of the text.
                    .background(AppTheme.secondaryBackground)       // Sets the background color of the text field to a custom secondary background color defined in `AppTheme`.
                    .cornerRadius(20)       // Rounds the corners of the text field with a radius of 20 points, giving it a smooth, rounded appearance.
                Button(action: { viewModel.showEmojiPicker.toggle() }) {     // Creates a button that toggles the visibility of the emoji picker when pressed.
                    Image(systemName: "face.smiling")        // Displays a smiling face emoji as the button's icon, using a system image
                        .font(.system(size: 20))    // Sets the font size of the emoji to 20 points.
                        .foregroundColor(AppTheme.secondaryText)        // Sets the color of the emoji icon using the custom secondary text color from `AppTheme`.
                }
                Button(action: viewModel.addComment) {   // Creates a button that, when pressed, triggers the `addComment` method in the `viewModel`.
                    Text("Post")        // The button displays the text "Post".
                        .font(.system(size: 14, weight: .semibold)) // Sets the font size of the text to 14 points with a semibold weight.
                        .foregroundColor(AppTheme.primaryPurple)    // Sets the color of the text to a custom primary purple color from `AppTheme`.
                }
            }
            .padding(.horizontal, 16)   // Adds horizontal padding (16 points) around the entire HStack, providing space between the buttons/text field and the container's edges.
            .padding(.vertical, 12) // Adds vertical padding (12 points) around the entire HStack, providing space between the buttons/text field and the container's top and bottom edges
            
            if viewModel.showEmojiPicker {       // Conditional check: if `showEmojiPicker` is true in the `viewModel`, display the emoji picker.
                // Emoji picker view for comments
                EmojiPickerView(text: $viewModel.commentText, showPicker: $viewModel.showEmojiPicker)       // Displays the `EmojiPickerView`, passing in bindings to the comment text and picker visibility.
                    .transition(.identity)  // Defines a transition effect (no change in view appearance in this case) when the emoji picker is shown or hidden.
            }
        }
    }
    
    // MARK: - Supporting Views

    // View for each individual comment displayed
    private struct CommentRow: View {       // Declares a private struct `CommentRow` that conforms to the `View` protocol. This will be used to display individual comments.
        let comment: Comment        // A constant property representing the `Comment` object for this row.
        let userData: (username: String, profileImageUrl: String?)? // A constant property that contains the user's username and an optional URL for their profile image.
        let onDelete: () -> Void         // A closure property that is called when the delete action for the comment is triggered.
        let onLike: () -> Void      // A closure property that is called when the like action for the comment is triggered.
        
        var body: some View {       // The body property that defines the view to display for each individual comment.
            HStack(alignment: .top, spacing: 12) {        // A horizontal stack (HStack) to arrange the views for the comment. The alignment is at the top, and there is 12 points of spacing between the views.
                // User Image
                Group {     // A Group is used to group multiple views together for easier modifiers.
                    if let profileUrl = userData?.profileImageUrl,   // If the user has a valid profile image URL...
                       let url = URL(string: profileUrl),    // Convert the profile URL string into a valid URL object.
                       !profileUrl.isEmpty {         // Check that the URL string is not empty.
                        WebImage(url: url)       // Use the `WebImage` view to load the image from the URL asynchronously.
                            .resizable()         // Allows the image to be resized.
                            .scaledToFill()  // Ensures the image fills the designated space and may crop if necessary.
                            .frame(width: 32, height: 32)   // Sets the image's width and height to 32 points, making it a small circle.
                            .clipShape(Circle())    // Clips the image into a circular shape.
                    } else {            // If no valid profile image URL is found...
                        Image(systemName: "person.circle.fill")  // Use a system image of a filled person icon as a placeholder for the user's profile image.
                            .resizable()         // Makes the placeholder image resizable.
                            .scaledToFill()     // Ensures the placeholder fills the frame and may be cropped if necessary.
                            .frame(width: 32, height: 32)         // Sets the width and height of the placeholder image to 32 points.
                            .foregroundColor(AppTheme.secondaryText)    // Applies the custom secondary text color from `AppTheme` to the placeholder image.
                            .clipShape(Circle())     // Clips the placeholder image into a circular shape.
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {   // A vertical stack (VStack) that arranges its children views vertically, aligned to the leading edge, with 4 points of spacing between the views.
                    
                    Text(userData?.username ?? "Unknown User")  // Displays the username of the user from `userData`. If `userData` is nil or the `username` is missing, "Unknown User" is shown instead.
                        .font(.system(size: 14, weight: .semibold))  // Sets the font of the username text to a system font with a size of 14 points and a semibold weight.
                        .foregroundColor(AppTheme.primaryText)  // Applies the primary text color defined in `AppTheme` to the username text.
                    
                    Text(comment.text)       // Displays the comment text from the `comment` object.
                        .font(.system(size: 14))     // Sets the font size of the comment text to 14 points using the system font.
                        .foregroundColor(AppTheme.primaryText)  // Applies the primary text color defined in `AppTheme` to the comment text.
                    
                    Text(comment.timestampString ?? "")  // Displays the timestamp of the comment. If the timestamp is nil, it shows an empty string instead.
                        .font(.system(size: 12))    // Sets the font size of the timestamp to 12 points using the system font.
                        .foregroundColor(AppTheme.secondaryText)    // Applies the secondary text color defined in `AppTheme` to the timestamp text.
                }
                
                Spacer()     // Adds a spacer that pushes any content below it towards the top of the view, effectively filling any available vertical space. This is useful for creating space between the comment and any other content.
                
                // Like and Delete buttons
                HStack(spacing: 12) {    // A horizontal stack (HStack) that arranges its child views horizontally with 12 points of spacing between them.
                    Button(action: onLike) {    // A button that triggers the `onLike` action when pressed. It will handle the like functionality for the comment.
                        HStack(spacing: 4) {    // A nested horizontal stack for the contents inside the button. This aligns the heart icon and like count horizontally with 4 points of spacing.
                            Image(systemName: comment.likedByCurrentUser ? "heart.fill" : "heart")   // Displays a filled heart icon if the comment is liked by the current user, otherwise displays an empty heart icon.
                                .foregroundColor(comment.likedByCurrentUser ? .red : AppTheme.secondaryText)    // Changes the color of the heart icon to red if liked by the user, otherwise applies the secondary text color from `AppTheme`.
                            Text("\(comment.likeCount)")     // Displays the like count of the comment. The count is formatted as a string and passed to the `Text` view.
                                .font(.system(size: 12))        // Sets the font size of the like count to 12 points
                                .foregroundColor(AppTheme.secondaryText)    // Applies the secondary text color from `AppTheme` to the like count text.
                        }
                    }
                    
                    if comment.userID == FirebaseManager.shared.auth.currentUser?.uid { // Checks if the userID of the comment matches the current user's ID. This condition determines if the current user is the author of the comment.
                        Button(action: onDelete) {
                            // A button that triggers the `onDelete` action when pressed. This button will only be shown if the current user is the comment's author.
                            Image(systemName: "trash")  // Displays a trash can icon to represent the delete action.
                                .foregroundColor(.red)  // Sets the color of the trash can icon to red, indicating the delete action.
                        }
                    }
                }
            }
            .padding(.horizontal, 16)   // Adds 16 points of horizontal padding around the entire `HStack`, ensuring there is space between the content and the edges of the parent view.

            .padding(.vertical, 8)   // Adds 8 points of vertical padding around the `HStack`, ensuring there is space between the content and the top/bottom edges of the parent view.
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
