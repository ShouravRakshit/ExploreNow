//
//  SearchUserRowView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import SDWebImageSwiftUI // Used for loading images asynchronously from URLs

// SearchUserRowView is a custom view that displays information about a single user
struct SearchUserRowView: View {
    let user: ChatUser // The user object that contains the user data (e.g., profile image, name, email)
    
    var body: some View {
        HStack(spacing: 12) { // Horizontal stack for laying out the user information with 12 points of space between elements
            // Profile image loaded asynchronously from a URL
            WebImage(url: URL(string: user.profileImageUrl)) // WebImage component loads the profile image from the URL
                .resizable() // Allow the image to be resized
                .scaledToFill() // The image is scaled to fill the space, potentially cropping to maintain aspect ratio
                .frame(width: 40, height: 40) // Set the fixed width and height for the profile image
                .clipShape(Circle()) // Clip the image to a circular shape
            
            // Vertical stack for the user's name and email
            VStack(alignment: .leading, spacing: 4) { // Stack the name and email vertically, with 4 points of spacing
                Text(user.name) // Display the user's name
                    .font(.system(size: 16, weight: .semibold)) // Use system font with semi-bold weight and size 16
                    .foregroundColor(.primary) // Set the text color to the primary color, which adjusts based on the system theme (light/dark mode)
                
                Text(user.email) // Display the user's email
                    .font(.system(size: 14)) // Use system font with size 14
                    .foregroundColor(.gray) // Set the text color to gray for less emphasis
            }
            
            Spacer() // Spacer to push the content to the left and allow other components to align properly
        }
        .padding(.vertical, 12) // Vertical padding to space the content from the top and bottom
        .padding(.horizontal) // Horizontal padding to space the content from the left and right
        .background(Color.white) // White background for the row
        .cornerRadius(10) // Round the corners of the row for a smoother appearance
        .overlay(
            RoundedRectangle(cornerRadius: 10) // Add a border around the row with rounded corners
                .stroke(Color.black, lineWidth: 1) // Black border with 1 point width
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1) // Add a subtle shadow to the row for a 3D effect
    }
}
