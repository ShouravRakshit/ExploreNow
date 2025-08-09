//
//  UserRow.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, -----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import SDWebImageSwiftUI

// This struct defines a UserRow view which displays a user's profile with options to navigate to their profile page.
struct UserRow: View {
    let user: User        // The user whose data will be displayed in this row
    let isBlocked: Bool   // A flag indicating whether the user is blocked

    var body: some View {
        // NavigationLink is used to navigate to the ProfileView of the user when tapped
        NavigationLink(destination: ProfileView(user_uid: user.uid)) {
            HStack {
                // Check if the user has a profile image URL
                if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                    // If the URL exists and is not empty, load and display the user's profile image
                    WebImage(url: URL(string: profileImageUrl)) // SDWebImageSwiftUI component for loading images asynchronously
                        .resizable()                            // Makes the image resizable
                        .scaledToFill()                         // Scales the image to fill the frame
                        .frame(width: 50, height: 50)           // Sets the frame size for the image
                        .clipped()                              // Ensures the image is clipped to its frame
                        .cornerRadius(25)                       // Makes the image circular
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color(.label), lineWidth: 2)) // Adds a border around the image
                } else {
                    // If the profile image URL is absent, show a default placeholder image
                    Image(systemName: "person.fill")       // A system icon to represent a generic user
                        .resizable()                        // Makes the icon resizable
                        .scaledToFill()                     // Scales the icon to fill the frame
                        .frame(width: 50, height: 50)       // Sets the frame size for the icon
                        .clipped()                          // Ensures the icon is clipped to its frame
                        .cornerRadius(25)                   // Makes the icon circular
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color(.label), lineWidth: 2)) // Adds a border around the icon
                }

                // VStack to display the user's name and username
                VStack(alignment: .leading) {
                    Text(user.name)                               // Displays the user's full name
                        .foregroundColor(Color(.label))           // Uses system label color for text (adapts to light/dark mode)
                        .font(.system(size: 16, weight: .bold))    // Sets the font size and weight for the name
                    Text("@\(user.username)")                     // Displays the user's username prefixed with "@"
                        .foregroundColor(.gray)                   // Gray color for the username
                        .font(.system(size: 12))                  // Smaller font for the username
                }

                // Spacer to push the "Blocked" text to the right side of the row
                Spacer()

                // If the user is blocked, display a "Blocked" label in red
                if isBlocked {
                    Text("Blocked")                            // Displays the "Blocked" text
                        .foregroundColor(.red)                  // Red text color to indicate a blocked user
                        .padding(.trailing)                      // Adds trailing padding to the "Blocked" label
                }
            }
            .padding(.horizontal)  // Horizontal padding around the entire row
            .padding(.vertical, 8) // Vertical padding to give space around the row content
            .contentShape(Rectangle()) // Ensures that the entire area of the row is tappable
        }
        .buttonStyle(PlainButtonStyle()) // Disables default button styling to make the row look like a standard list item
    }
}
