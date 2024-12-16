//
//  MessageView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import Firebase

struct MessageView: View {
    let message: ChatMessage // The message to display, passed as a parameter
    let onDelete: (String) -> Void // Closure to handle message deletion, takes message ID as parameter

    var body: some View {
        HStack {  // Horizontally stack elements in this container (used for user and message alignment)
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid { // Check if the message is sent by the current user
                Spacer() // Push the message to the right by adding a flexible space on the left
                VStack(alignment: .trailing, spacing: 4) { // Stack elements vertically with trailing alignment (to position text to the right)
                    HStack { // Horizontal stack for message text and timestamp
                        VStack(alignment: .trailing, spacing: 4) { // Inner vertical stack for the message text and timestamp
                            Text(message.text)  // Display the text of the message
                                .foregroundColor(.white)  // Set the text color to white for better contrast
                                .font(.body) // Use body font for the message text

                            // Display the timestamp of the message, formatted using `formatTimestamp`
                            Text(formatTimestamp(message.timestamp.dateValue()))
                                .foregroundColor(.white.opacity(0.8))  // Slightly transparent white color for the timestamp
                                .font(.caption2) // Use a smaller font size for the timestamp
                        }

                        // Delete button for the message
                        Button(action: {
                            onDelete(message.id)  // Calls the onDelete closure, passing the message's unique ID to trigger deletion
                        }) {
                            Image(systemName: "trash") // Displays a trash icon to signify message deletion
                                .foregroundColor(.white) // Sets the color of the trash icon to white for better contrast on dark backgrounds
                        }
                    }
                    .padding() // Adds padding around the button to provide space between the icon and the edges of the button.
                    .background(Color.blue)  // Sets the background color of the button to blue, making it stand out as an action button.
                    .cornerRadius(12) // Applies a rounded corner with a radius of 12 points for a smooth, modern look.
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.text)  // Displays the chat message text
                            .foregroundColor(.black) // Sets the text color to black for readability
                            .font(.body) // Uses body font style, which is appropriate for general text content

                        // Timestamp inside the bubble
                        Text(formatTimestamp(message.timestamp.dateValue())) // Formats and displays the message timestamp
                            .foregroundColor(.gray) // Sets the timestamp text color to gray to differentiate it from the main message
                            .font(.caption2) // Uses a smaller font size for the timestamp to make it less prominent
                    }
                    .padding() // Adds padding inside the bubble for better spacing around the text
                    .background(Color.white)  // Sets the background color of the message bubble to white
                    .cornerRadius(12) // Applies rounded corners with a 12-point radius to create a soft, modern look
                }
                Spacer() // Adds space to push the message to the left of the screen
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter() // Create an instance of DateFormatter to format the date
        formatter.dateStyle = .none // Set the date style to none, meaning only the time will be displayed
        formatter.timeStyle = .short // Set the time style to short (e.g., 3:30 PM), which is a concise representation of time
        return formatter.string(from: date) // Return the formatted time as a string
    }
}

