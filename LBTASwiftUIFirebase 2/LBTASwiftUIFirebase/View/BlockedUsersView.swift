//
//  BlockedUsersView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-11-20.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct BlockedUsersView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var blockedManager = BlockedManager()
    
    @State private var friendToUnblock: User? = nil // Store the user being unblocked
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            //----- TOP ROW --------------------------------------
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
                    .offset(x: -30)
                Spacer()
            }
            //------------------------------------------------
            
            if blockedManager.isLoading {
                ProgressView()  // Show loading spinner while fetching friends
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
            else if let error = blockedManager.error {
                Text("Error: \(error.localizedDescription)")  // Display error if any
                    .foregroundColor(.red)
                    .padding()
            }
            else if blockedManager.filteredUsers.count == 0{
                Spacer ()
                Text ("No Blocked Users.")
                    .bold()
                    .padding(.top, 10)
                    .font(.custom("Sansation-Regular", size: 25))
                    .foregroundColor(.black)
            }
            else {
                List(blockedManager.filteredUsers) { friend in
                    // Row content for each friend
                    row(for: friend)
                }
                .listStyle(PlainListStyle()) // Ensure list style is plain (no separators, no extra padding)
                .padding (.top, 10)
            }
            
            Spacer ()
   
        }
        .alert(isPresented: $showingAlert) {
             Alert(
                 title: Text("Unblock \(friendToUnblock?.username ?? "")?"),
                 message: Text("Are you sure you want to unfriend this person?"),
                 primaryButton: .destructive(Text("Unblock")) {
                     if let friendToUnblock = friendToUnblock {
                         blockedManager.unblockUser (userId: friendToUnblock.uid)
                     }
                 },
                 secondaryButton: .cancel {
                     print("Unfriend canceled.")
                 }
             )
         }
        .onAppear(){
            blockedManager.isLoading = true
            blockedManager.fetchBlockedUsers(forUserUID: userManager.currentUser?.uid ?? "") { success in
                if success {
                    blockedManager.isLoading = false
                    print("Blocked users fetched successfully!")
                } else {
                    print("Failed to fetch blocked users.")
                }
            }
            print ("fetched blocked users length: \(blockedManager.blocked_users)")
        }
    }
    
    // Defining a variable for the row content, which will display each friend's information
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
                    .foregroundColor(.secondary)
            }
            .padding (.leading, 15)
            
            Spacer()

            // Friends button
            Button(action: {
                // Trigger the alert and set the user to unfriend
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
            .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to ensure no default List row interactions

        }
    }
    
}
