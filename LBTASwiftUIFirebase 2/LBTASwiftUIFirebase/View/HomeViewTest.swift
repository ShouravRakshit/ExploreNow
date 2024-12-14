//
//  HomeViewTest.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import Firebase
import SDWebImageSwiftUI

// The main view for the Home screen of the app
struct HomeViewTest: View {
    // Access shared user data using the environment object
    @EnvironmentObject var userManager: UserManager
    // View model to manage the state and data for the Home view
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack(spacing: 16) {
                    // App title
                    Text("ExploreNow")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Spacer()
                    
                    // Search Button
                    NavigationLink(destination: AllUsersSearchView()) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryPurple)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.lightPurple)
                            .clipShape(Circle())
                    }
                    
                    // Notifications Button
                    NavigationLink(destination: NotificationView(userManager: userManager)) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primaryPurple)
                                .frame(width: 40, height: 40)
                                .background(AppTheme.lightPurple)
                                .clipShape(Circle())

                            // Red dot indicator if there are unread notifications
                            if userManager.hasUnreadNotifications {
                                Circle()
                                    .fill(AppTheme.error)
                                    .frame(width: 12, height: 12)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(AppTheme.background)
                
                // Main Content
                if viewModel.isLoading {
                    // Loading State
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppTheme.primaryPurple)
                        
                        Text("Loading your feed...")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.secondaryText)
                        
                        // Loading Animation Dots
                        HStack(spacing: 6) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(AppTheme.primaryPurple)
                                    .frame(width: 8, height: 8)
                                    .opacity(0.3)
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(0.2 * Double(index)),
                                        value: viewModel.isLoading
                                    )
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background)
                    
                } else if viewModel.friendIds.isEmpty {
                    // Display an empty state if the user has no friends
                    EmptyStateView(
                        icon: "person.2",
                        message: "Add friends to see their posts",
                        backgroundColor: AppTheme.background
                    )
                    
                } else if viewModel.posts.isEmpty {
                    // Display an empty state if there are no posts
                    EmptyStateView(
                        icon: "photo.stack",
                        message: "No posts from friends yet",
                        backgroundColor: AppTheme.background
                    )
                    
                } else {
                    // Display the posts feed if posts are available
                    PostsFeedView(posts: viewModel.posts)
                }
            }
            .onAppear {
                if userManager.currentUser != nil {
                    viewModel.posts = []    // Clear existing posts.
                    viewModel.isLoading = true    // Show the loading state

                    // Fetch posts, notifications, and block list updates
                    viewModel.checkIfNotifications()
                    viewModel.setupBlockedUsersListener()
                    viewModel.fetchAllPosts()

                    // Simulate a delay to finish fetching
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        viewModel.isFetching = false
                    }

                }
            }
        }
    
    
    // MARK: - UI Components
    // A subview to display the feed of posts
    struct PostsFeedView: View {
        let posts: [Post]    // The list of posts to display
        @EnvironmentObject var userManager: UserManager

        var body: some View {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Iterate through and display each post
                    ForEach(posts) { post in
                        PostCardView(post: post)    // Custom view for a single post
                            .environmentObject(userManager)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .background(AppTheme.background)
        }
    }
    
        // Helper View for Empty States
        private struct EmptyStateView: View {
            let icon: String    // Icon to display
            let message: String    // Message to show
            let backgroundColor: Color    // Background color for the view
            
            var body: some View {
                ScrollView { // Wrap in ScrollView to maintain consistent layout
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 100) // Add some top spacing

                        // Display an icon for the empty state
                        Image(systemName: icon)
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.secondaryText)

                        // Display the message
                        Text(message)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: UIScreen.main.bounds.height - 200) // Adjust height to account for nav bar and tab bar
                }
                .background(backgroundColor)
            }
        }

}
