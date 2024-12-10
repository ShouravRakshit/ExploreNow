//
//  FriendsView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore

struct FriendsView: View {
    //------------------------------------------------------------------------------------------------
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    
    @StateObject private var friendManager = FriendManager()
    
    @State private var showingAlert = false
    @State private var friendToUnfriend: User? = nil // Store the user being unfriended
    
    @State private var navigateToProfile = false // State to manage the full screen cover
    @State private var selectedUserUID: String? = nil
    
    @State private var searchQuery = ""
    
    
    var user_uid: String // The UID of the user whose friends list is being viewed
    var viewingOtherProfile: Bool
    //------------------------------------------------------------------------------------------------
    
    var body: some View {
        VStack {
            // Search Bar with purple border
            HStack {
                TextField("Search", text: $searchQuery)
                    .foregroundColor(.gray)
                    .padding(.leading, 12) // Ensure the placeholder stays left aligned
                    .padding(.vertical, 10)
                
                Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.trailing, 10) // Move the icon to the right
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.customPurple, lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, 5)
            .padding(.bottom, 5)
            
            if friendManager.isLoading {
                ProgressView()  // Show loading spinner while fetching friends
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if let error = friendManager.error {
                Text("Error: \(error.localizedDescription)")  // Display error if any
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(friendManager.filteredUsers) { friend in
                    ZStack {
                        NavigationLink(destination: ProfileView(user_uid: friend.uid)) {
                            EmptyView() // Makes the NavigationLink invisible
                        }
                        .opacity(0) // Hide the NavigationLink but maintain its tap functionality
                        
                        row(for: friend) // The content of the row
                            .contentShape(Rectangle()) // Makes the row tappable
                    }
                }
                .listStyle(PlainListStyle()) // Ensure list style is plain (no separators, no extra padding)
                .padding (.top, 10)
            }

        }
        .onAppear {
            friendManager.fetchFriends(forUserUID: user_uid)  // Fetch friends when the view appears
            
            print ("fetched friends length: \(friendManager.friends)")
            print ("Viewing other profile: \(viewingOtherProfile)")
        }
        .onChange(of: searchQuery) { newValue in
            filterUsers(query: newValue)
        }
        .navigationTitle("Friends")  // Title of the profile section
        .navigationBarTitleDisplayMode(.inline)  // Title display mode
        .alert(isPresented: $showingAlert) {
             Alert(
                 title: Text("Unfriend \(friendToUnfriend?.username ?? "")?"),
                 message: Text("Are you sure you want to unfriend this person?"),
                 primaryButton: .destructive(Text("Unfriend")) {
                     // Unfriend action: Add your unfriending logic here
                     if let friendToUnfriend = friendToUnfriend {
                         unfriendUser (friendToUnfriend)
                     }
                 },
                 secondaryButton: .cancel {
                     // Cancel action (dismiss the alert)
                     print("Unfriend canceled.")
                 }
             )
         }

    }
    
    // Define a variable for the row content, which will display each friend's information
    private func row(for friend: User) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Profile Image
            if let profileImageUrl = friend.profileImageUrl,
               let url = URL(string: profileImageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 50, height: 50)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            
            // Text content: Username and Name
            VStack(alignment: .leading) {
                Text("@\(friend.username)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(friend.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding (.leading, 15)
            
            Spacer()
            if !viewingOtherProfile {
                // Friends button
                Button(action: {
                    // Trigger the alert and set the user to unfriend
                    friendToUnfriend = friend
                    showingAlert = true
                }) {
                    Text("Friends")
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to ensure no default List row interactions
            }
            //Spacer() // This will push the content to the left if needed
        }
        //.padding(.vertical, 1)
    }
    //------------------------------------------------------------------------------------------------
    
    // Function to handle unfriending the user (this is where you add your unfriending logic)
    private func unfriendUser(_ user: User) {
        // Implement your unfriending logic here
        print("Unfriended \(user.username)!")
        
        // Example: Remove friend from current user's friend list in Firestore or other database
        friendManager.removeFriend(currentUserUID: user_uid, user)
    }
    //------------------------------------------------------------------------------------------------
    private func filterUsers(query: String) {
        if query.isEmpty {
            friendManager.filteredUsers = friendManager.friends
        } else {
            friendManager.filteredUsers = friendManager.friends.filter { user in
                user.email.lowercased().contains(query.lowercased()) ||
                user.name.lowercased().contains(query.lowercased())
            }
        }
    }
    //------------------------------------------------------------------------------------------------
}
