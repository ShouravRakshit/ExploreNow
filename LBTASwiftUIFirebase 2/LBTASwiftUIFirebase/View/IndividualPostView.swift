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
            if let imageUrl = URL(string: viewModel.post.userProfileImageUrl) {
                WebImage(url: imageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.lightPurple, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(AppTheme.secondaryText)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.lightPurple, lineWidth: 2))
            }
        }
    }

    // Tabview of the images posted 
    private var imageSection: some View {
        TabView {
            ForEach(viewModel.post.imageUrls.indices, id: \.self) { index in
                Group {
                    if let imageUrl = URL(string: viewModel.post.imageUrls[index]) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                            .clipped()
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 400)
    }

    // Interaction bar for likes, location, and rating
    private var interactionBar: some View {
        HStack(spacing: 20) {
            Button(action: { viewModel.toggleLike() }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.liked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(viewModel.liked ? .red : AppTheme.secondaryText)
                    Text("\(viewModel.likesCount)")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            NavigationLink(destination: LocationPostsView(locationRef: viewModel.post.locationRef)) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                    Text(viewModel.post.locationAddress)
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
                .foregroundColor(AppTheme.primaryPurple)
            }
            Spacer()
            HStack(spacing: 4) {
                // Star rating display
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= viewModel.post.rating ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(index <= viewModel.post.rating ? .yellow : AppTheme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
    }

     // Description of the post
    private var descriptionSection: some View {
        Text(viewModel.post.description)
            .font(.system(size: 15))
            .foregroundColor(AppTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.background)
    }

    // Section displaying comments
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(viewModel.comments.count)")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            
            if viewModel.comments.isEmpty {
                // Placeholder for empty comments
                Text("No comments yet")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            } else {
                // List of comments
                ForEach(viewModel.comments) { comment in
                    CommentRow(comment: comment,
                               userData: viewModel.userData[comment.userID],
                               onDelete: { viewModel.deleteComment(comment) },
                               onLike: { viewModel.toggleLikeForComment(comment) })
                }
            }
        }
        .padding(.bottom, 60)
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
        @Binding var text: String
        @Binding var showPicker: Bool

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
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                    spacing: 10
                ) {
                    
                    ForEach(emojis + Array(repeating: " ", count: (6 - emojis.count % 6) % 6), id: \.self) { emoji in
                        Button(action: {
                            if emoji != " " {
                                text += emoji
                                showPicker = false
                            }
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 40, height: 40)
                                .background(emoji == " " ? Color.clear : Color.gray.opacity(0.1))
                                .cornerRadius(5)
                        }
                        .padding(5)
                    }
                }
                .padding([.top, .horizontal])
            }
            .background(AppTheme.background)
        }
    }
}
