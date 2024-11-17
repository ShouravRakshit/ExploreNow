//
//  FriendsView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-11-16.
//

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
    
    var user_uid: String // The UID of the user whose friends list is being viewed
    //------------------------------------------------------------------------------------------------
    
    var body: some View {
        VStack {
            if friendManager.isLoading {
                ProgressView()  // Show loading spinner while fetching friends
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if let error = friendManager.error {
                Text("Error: \(error.localizedDescription)")  // Display error if any
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(friendManager.friends) { friend in
                    // Row content for each friend
                    row(for: friend)
                        .onTapGesture {
                            selectedUserUID = friend.uid
                            navigateToProfile = true
                        }
                }
                .listStyle(PlainListStyle()) // Ensure list style is plain (no separators, no extra padding)
                .padding (.top, 10)
            }
            
            // Conditional NavigationLink
            if navigateToProfile {
                NavigationLink(
                    destination: ProfileView(user_uid: selectedUserUID ?? ""),
                    isActive: $navigateToProfile,
                    label: { EmptyView() }
                )
                .hidden() // Hide the NavigationLink in the UI
            }
        }
        .onAppear {
            friendManager.fetchFriends(forUserUID: user_uid)  // Fetch friends when the view appears
            
            print ("fetched friends length: \(friendManager.friends)")
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
    
}
