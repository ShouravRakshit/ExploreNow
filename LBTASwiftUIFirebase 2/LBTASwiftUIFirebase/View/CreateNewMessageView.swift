//
//  CreateNewMessageView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct CreateNewMessageView: View {
    let didSelectNewUser: (ChatUser) -> () // A closure that is called when a new user is selected
    
    @Environment(\.presentationMode) var presentationMode // To control the navigation view presentation (e.g., dismiss the current view)
    @ObservedObject var vm = CreateNewMessageViewModel() // View model to handle data and logic for this view
    
    var body: some View {
        NavigationView { // Wrapping the entire view in a NavigationView to allow navigation features
            VStack {
                searchBar // A search bar for filtering users (defined elsewhere in the code)
                
                // Display message if no users match the search criteria
                if vm.filteredUsers.isEmpty {
                    Text("No friends found") // Display text indicating no results
                        .foregroundColor(.gray) // Text color is gray
                        .padding(.top, 20) // Padding to give some space from the top
                    Spacer() // Add space below the text to push it upwards
                } else {
                    // If there are users, display them in a scrollable list
                    ScrollView {
                        ForEach(vm.filteredUsers) { user in
                            Button { // Each user is a button that triggers an action when tapped
                                presentationMode.wrappedValue.dismiss() // Dismiss the current view when a user is selected
                                didSelectNewUser(user) // Call the closure passed to the view, passing the selected user
                            } label: {
                                HStack { // Horizontal stack for displaying user data
                                    WebImage(url: URL(string: user.profileImageUrl)) // Load the user's profile image from a URL
                                        .resizable() // Make the image resizable
                                        .frame(width: 50, height: 50) // Set the width and height of the image
                                        .clipped() // Ensure the image is clipped to the frame (no overflow)
                                        .cornerRadius(50) // Round the corners to make the image circular
                                        .overlay(RoundedRectangle(cornerRadius: 50)
                                            .stroke(Color(.label), lineWidth: 2) // Add a border around the image with a rounded rectangle
                                        )
                                    VStack(alignment: .leading) { // Vertical stack for the user's name and email
                                        Text(user.name) // Display the user's name
                                            .foregroundColor(Color(.label)) // Set the text color to the label color (automatic dark/light mode handling)
                                        Text(user.email) // Display the user's email
                                            .foregroundColor(.gray) // Set the text color to gray for the email
                                            .font(.system(size: 12)) // Set the font size of the email text
                                    }
                                    Spacer() // Push content to the left and allow alignment on the right
                                }
                                .padding(.horizontal) // Horizontal padding for spacing
                                .padding(.vertical, 8) // Vertical padding for spacing
                            }
                            Divider() // Add a divider after each user
                                .padding(.leading, 70) // Add left padding to make the divider align with the user content
                        }
                    }
                }
            }
            .toolbar { // Add a toolbar for the navigation bar
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { // Cancel button on the left side of the navigation bar
                        presentationMode.wrappedValue.dismiss() // Dismiss the view when tapped
                    } label: {
                        Text("Cancel") // Button label is "Cancel"
                    }
                }
            }
            .onChange(of: vm.searchQuery) { _ in // Trigger filtering when the search query changes
                vm.filterUsers() // Call the filterUsers method from the view model to update the filtered list
            }
        }
    }
    
    
    
    private var searchBar: some View {
        HStack {
            TextField("Search", text: $vm.searchQuery) // Create a TextField for search input
                .padding(8) // Add padding inside the TextField to give it some space from the edges
                .background(Color(.systemGray6)) // Set a light gray background color for the TextField
                .cornerRadius(8) // Apply rounded corners with a radius of 8 for a smoother look
                .padding(.horizontal) // Apply horizontal padding around the TextField to ensure it doesn't touch the screen edges
        }
        .padding(.top, 10) // Apply padding at the top of the HStack to add some spacing from the top of the parent view
    }
}
