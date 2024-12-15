//
//  BlockedUsersView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct BlockedUsersView: View {
    // EnvironmentObject to access the global user manager
    @EnvironmentObject var userManager: UserManager
    
    // Environment variable for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    // StateObject to manage the blocked users data
    @StateObject private var blockedManager = BlockedManager()
    
    // State variables for unblocking functionality
    @State private var friendToUnblock: User? = nil // Store the user being unblocked
    @State private var showingAlert = false // Show/hide the unblock confirmation alert
    
    var body: some View {
        VStack {
            //----- TOP ROW --------------------------------------
            // Navigation bar-like top row with a back button and title
            HStack {
                Image(systemName: "chevron.left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding()
                    .foregroundColor(Color.customPurple)
                    .onTapGesture {
                        // Go back to profile page
                        presentationMode.wrappedValue.dismiss()
                    }
                Spacer()
                Text("Blocked Users")
                    .font(.custom("Sansation-Regular", size: 20))
                    .foregroundColor(Color.customPurple)
                    .offset(x: -30) // Center the title
                Spacer()
            }
            //------------------------------------------------
            
            // Show loading indicator, error message, or blocked users list
            if blockedManager.isLoading {
                // Display a loading spinner while fetching data
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
            else if let error = blockedManager.error {
                // Display an error message if fetching data failed
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
            else if blockedManager.filteredUsers.isEmpty {
                // Show a message if there are no blocked users
                Spacer()
                Text("No Blocked Users.")
                    .bold()
                    .padding(.top, 10)
                    .font(.custom("Sansation-Regular", size: 25))
                    .foregroundColor(.black)
            }
            else {
                // Display the list of blocked users
                List(blockedManager.filteredUsers) { friend in
                    row(for: friend) // Custom row for each user
                }
                .listStyle(PlainListStyle()) // Plain style for the list
                .padding(.top, 10)
            }
            
            Spacer()
        }
        // Alert for confirming the unblock action
        .alert(isPresented: $showingAlert) {
             Alert(
                 title: Text("Unblock \(friendToUnblock?.username ?? "")?"),
                 message: Text("Are you sure you want to unfriend this person?"),
                 primaryButton: .destructive(Text("Unblock")) {
                     // Unblock the user if confirmed
                     if let friendToUnblock = friendToUnblock {
                         blockedManager.unblockUser(userId: friendToUnblock.uid)
                     }
                 },
                 secondaryButton: .cancel {
                     print("Unfriend canceled.") // Log when unblock is canceled
                 }
             )
         }
        // Fetch blocked users when the view appears
        .onAppear {
            blockedManager.isLoading = true
            blockedManager.fetchBlockedUsers(forUserUID: userManager.currentUser?.uid ?? "") { success in
                blockedManager.isLoading = false
                if success {
                    print("Blocked users fetched successfully!")
                } else {
                    print("Failed to fetch blocked users.")
                }
            }
            print("Fetched blocked users count: \(blockedManager.blocked_users)")
        }
    }
    
    // Define the row view for each blocked user
    private func row(for friend: User) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Display the user's profile image
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
                // Default profile image if none exists
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            
            // Display the username and full name
            VStack(alignment: .leading) {
                Text("@\(friend.username)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(friend.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 15)
            
            Spacer()

            // Button for unblocking the user
            Button(action: {
                // Trigger the alert and set the user to unblock
                friendToUnblock = friend
                showingAlert = true
            }) {
                Text("Blocked")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .foregroundColor(.red)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle()) // Ensure no default List row interactions
        }
    }
}
