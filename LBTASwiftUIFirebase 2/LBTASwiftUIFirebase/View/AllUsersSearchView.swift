//
//  AllUsersSearchView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-19.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct AllUsersSearchView: View {
    // ViewModel that manages the logic for filtering users in the search view
    @ObservedObject var vm = AllUsersSearchViewModel()
    
    // Used to manage the presentation mode (dismiss view)
    @Environment(\.presentationMode) var presentationMode
    
    // Injected UserManager object to manage the current user's information
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack {
            searchBar  // The search bar UI component for filtering users
            
            // Show a message when no users match the search filter
            if vm.filteredUsers.isEmpty {
                Text("No users found")  // Inform the user when no users match the search
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                Spacer()  // Add space below the message
            } else {
                // Show the filtered list of users in a ScrollView
                ScrollView {
                    // Iterate over the filtered users and display each one
                    ForEach(vm.filteredUsers) { user in
                        // Wrap each user in a NavigationLink to navigate to the user's profile
                        NavigationLink(destination: ProfileView(user_uid: user.uid)) {
                            // Display user row with a potential indication if the user is blocked
                            UserRow(user: user, isBlocked: vm.blockedUsers.contains(user.uid))
                        }
                        .buttonStyle(PlainButtonStyle())  // Use PlainButtonStyle to prevent default button style
                        .onTapGesture {
                            print("NavigationLink tapped for user: \(user.uid)")  // Log when a user row is tapped
                        }
                    }
                }
            }
        }
        // Set navigation bar title and display mode for the current view
        .navigationBarTitle("Search Users", displayMode: .inline)
        
        .onAppear {
            print("AllUsersSearchView appeared")  // Log when the view appears
            vm.fetchAllUsers()  // Fetch the list of users from the ViewModel
        }
    }
    
    
    private var searchBar: some View {
        // HStack to horizontally arrange the TextField inside a container view
        HStack {
            // TextField for searching, binding to the ViewModel's searchQuery property
            TextField("Search", text: $vm.searchQuery)
                .padding(8)  // Adds padding inside the TextField to make it more spacious
                .background(Color(.systemGray6))  // Sets the background color to a light gray (system default gray color)
                .cornerRadius(8)  // Rounds the corners of the TextField for a smoother look
                .padding(.horizontal)  // Adds horizontal padding around the TextField for spacing between it and other elements
        }
        .padding(.top, 10)  // Adds padding at the top of the HStack to give space from the elements above it
    }
}
