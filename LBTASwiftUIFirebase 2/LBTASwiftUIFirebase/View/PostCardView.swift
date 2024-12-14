//
//  PostCardView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct PostCardView: View {
    @StateObject private var viewModel: PostCardViewModel
    let post: Post
    var onDelete: ((Post) -> Void)?

    init(post: Post, onDelete: ((Post) -> Void)? = nil) {
        self.post = post
        self.onDelete = onDelete
        _viewModel = StateObject(wrappedValue: PostCardViewModel(post: post))
    }

    var body: some View {
        NavigationLink(destination: IndividualPostView(post: post, likesCount: viewModel.likesCount, liked: viewModel.liked)) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Section
                HStack(spacing: 12) {
                    // Profile Image
                    if let imageUrl = URL(string: post.userProfileImageUrl) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.lightPurple, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppTheme.secondaryText)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Username
                        NavigationLink(destination: ProfileView(user_uid: post.uid)) {
                            Text(post.username)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.primaryPurple)
                        }
                        
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(post.locationAddress)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Timestamp
                    Text(viewModel.formatDate(post.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                    
                    if viewModel.isCurrentUserPost {
                        Button(action: {
                            viewModel.showDeleteConfirmation = true
                            onDelete?(post)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                        .alert(isPresented: $viewModel.showDeleteConfirmation) {
                            Alert(
                                title: Text("Delete Post"),
                                message: Text("Are you sure you want to delete this post?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    viewModel.deletePost()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Images Section
                if !post.imageUrls.isEmpty {
                    TabView(selection: $viewModel.currentImageIndex) {
                        ForEach(post.imageUrls.indices, id: \.self) { index in
                            if let imageUrl = URL(string: post.imageUrls[index]) {
                                WebImage(url: imageUrl)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipped()
                                    .tag(index)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                }
                
                // Interaction Bar
                HStack(spacing: 20) {
                    // Like Button
                    Button(action: { viewModel.toggleLike() }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.liked ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.liked ? .red : AppTheme.secondaryText)
                            
                            Text("\(viewModel.likesCount)")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    // Comment Button
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryPurple)
                        Text("\(viewModel.comments.count)")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= post.rating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(index <= post.rating ? .yellow : AppTheme.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Description
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .lineLimit(3)
                }
            }
            .background(AppTheme.background)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray6), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            viewModel.setupListeners()
        }
    }
}
