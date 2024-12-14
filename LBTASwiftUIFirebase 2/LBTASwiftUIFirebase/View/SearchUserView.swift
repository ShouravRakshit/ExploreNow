//
//  SearchUserView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI

struct SearchUserView: View {
    @StateObject private var viewModel = SearchUserViewModel() // ViewModel used for managing search query and filtered users
    var didSelectUser: (ChatUser) -> Void // Closure to handle selection of a user, passed into the view

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar with purple border
            HStack {
                TextField("Search", text: $viewModel.searchQuery) // TextField to enter search query, bound to viewModel's searchQuery
                    .foregroundColor(.gray) // Gray text color for the input
                    .padding(.leading, 12) // Padding on the leading edge of the TextField
                    .padding(.vertical, 10) // Padding for top and bottom of TextField
                
                Image(systemName: "magnifyingglass") // Magnifying glass icon for search
                    .foregroundColor(.gray) // Gray color for the icon
                    .padding(.trailing, 10) // Padding on the trailing edge of the icon
            }
            .background(Color.white) // White background for the search bar
            .cornerRadius(10) // Rounded corners for the search bar
            .overlay(
                RoundedRectangle(cornerRadius: 20) // Custom border with purple color and rounded corners
                    .stroke(Color.customPurple, lineWidth: 1) // Purple border with 1px width
            )
            .padding(.horizontal) // Padding on the horizontal sides of the search bar
            .padding(.bottom, 20) // Bottom padding to separate search bar from user list
            
            // Users List
            ScrollView {
                LazyVStack(spacing: 8) { // LazyVStack to efficiently display a vertical list of users
                    ForEach(viewModel.filteredUsers) { user in // Iterate over the filtered users
                        Button(action: {
                            didSelectUser(user) // Call the didSelectUser closure when a user is selected
                        }) {
                            SearchUserRowView(user: user) // Custom view for displaying individual user row
                        }
                    }
                }
                .padding(.horizontal, 8) // Horizontal padding for the user list
            }
            .background(Color(.systemGray6)) // Light gray background for the user list
        }
        .onChange(of: viewModel.searchQuery) { newValue in // React to changes in the search query
            viewModel.filterUsers(query: newValue) // Filter users based on the new search query
        }
    }
}
