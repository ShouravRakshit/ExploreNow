//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import Firebase

struct NotificationView: View {
    // MARK: - Environment Objects and State Management

    // EnvironmentObject to access the user manager (provides user-related data across views)
    @EnvironmentObject var userManager: UserManager
    // Environment variable to manage view presentation state (used for dismissing the view)
    @Environment(\.presentationMode) var presentationMode
    // StateObject to hold the view model for this view, responsible for managing notification data
    @StateObject private var viewModel: NotificationViewModel
    // State variable to manage navigation to the ProfileView (full-screen cover)
    
    @State private var navigateToProfile = false
    // State variable to store the UID of the selected user for profile navigation
    @State private var selectedUserUID: String? = nil
    // State variable to store the selected user object for passing data to the ProfileView
    @State private var selectedUser: NotificationUser? // Store selected user to pass to ProfileView
    
    @State private var isProfilePresented = false // State variable to determine whether the profile is presented (using full-screen cover)
    
    // Custom initializer to pass userManager to the view model
    init(userManager: UserManager) {
        // Initializing viewModel with userManager (passed as dependency to the NotificationViewModel)
        _viewModel = StateObject(wrappedValue: NotificationViewModel(userManager: userManager))
    }
    
    // Placeholder array for notification users (currently not initialized or populated)
    var notificationUsers_all  : [NotificationUser] = []
    // State variable for tracking the loading state of the view
    @State private var isLoading = true
    // Firestore database instance for accessing cloud data
    let db = Firestore.firestore()
    
    var body: some View {
        
        VStack{
            //------------------------------------------------
            // Add spacing between elements in the vertical stack
            Spacer()
            // Conditional check for the loading state
            if isLoading
                {
                // Display a "Loading..." message with bold text when loading is true
                Text("Loading...")
                    .font(.system(size: 24, weight: .bold))
                }
            
            else
                {
                // If not loading, check if there are any notification users
                if viewModel.notificationUsers.isEmpty
                    {
                    // Display a message when no notifications are available
                    Text("No notifications available.")
                        .foregroundColor(.gray)             // Text color set to gray
                        .padding()              // Adds padding around the text for spacing
                    }
                else
                {
                    // If there are notifications, display them in a list
                    List(viewModel.notificationUsers, id: \.notification.timestamp) { user in
                        // For each notification user, create a vertical stack
                        VStack(alignment: .leading) {
                            // Horizontal stack to align elements side by side
                            HStack{
                                // Check if the notification is unread
                                if !user.notification.isRead {
                                    // Show a red dot indicator if the notification is unread
                                    Circle()
                                        .fill(Color.red)        // Fill the circle with red color
                                        .frame(width: 10, height: 10) // Size of the red dot
                                }
                                
                                ZStack
                                {
                                    // ZStack is used to overlay multiple views on top of each other. Here, it acts as a container for either the user's profile image or a placeholder icon.
                                    if !user.profileImageUrl.isEmpty
                                        {
                                        // Check if the user has a valid profile image URL. If it is not empty, load and display the profile image.
                                        WebImage(url: URL(string: user.profileImageUrl))
                                        // WebImage is used to load the profile image asynchronously from the provided URL.
                                            .resizable()         // Makes the image resizable to fit a specific frame.
                                            .scaledToFill()     // Scales the image to fill the given frame, cropping if necessary to maintain the aspect ratio.
                                            .frame(width: 40, height: 40)        // Sets the width and height of the image to 40x40 points.
                                            .clipped()
                                        // Ensures that the image is clipped to the bounds of the frame, preventing any overflow.
                                            .cornerRadius(20)
                                        // Applies a corner radius of 20 points to make the image appear circular.
                                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.customPurple, lineWidth: 0.5))
                                        // Adds a rounded border around the image. The border is styled with a custom purple color and a line width of 0.5 points.
                                            .padding(.horizontal, 1)         // Adds horizontal padding of 1 point around the image for slight spacing.
                                            .shadow(radius: 1)       // Adds a subtle shadow with a radius of 1 to give depth to the image.
                                        }
                                    else
                                        {
                                        
                                        Image(systemName: "person.circle.fill") // Uses a system image called "person.circle.fill", which is a placeholder user profile icon.
                                            .resizable()            // Makes the placeholder image resizable to fit a specific frame.
                                            .scaledToFill()         // Scales the placeholder image to fill the given frame, similar to how the profile image was handled.
                                            .frame(width: 40, height: 40)        // Sets the width and height of the placeholder image to 40x40 points, the same as the profile image.
                                            .clipped()       // Sets the width and height of the placeholder image to 40x40 points, the same as the profile image.
                                            .cornerRadius(20)        // Applies a corner radius of 20 points to make the placeholder image circular.
                                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.customPurple, lineWidth: 0.5))
                                        // Adds the same rounded border with the custom purple color and 0.5-point line width as the profile image.
                                            .padding(.horizontal, 1)
                                        // Adds horizontal padding of 1 point around the placeholder image for consistent spacing.
                                                    
                                            .shadow(radius: 1)
                                        // Adds the same subtle shadow with a radius of 1 to give depth to the placeholder image.
                                        }
                                }

                                
                                NavigationLink(destination: ProfileView(user_uid: user.uid)) {
                                    // Creates a navigation link that, when tapped, will navigate to the ProfileView and pass the user's UID.
                                    Text(user.full_message ?? "")   // Displays the notification message. If `full_message` is nil, it will display an empty string.
                                        .font(.subheadline)         // Sets the font of the notification message to `.subheadline`, which is typically a smaller, less prominent font.
                                        .padding(.bottom, 5)
                                    // Adds 5 points of padding to the bottom of the text to ensure it doesn’t touch any content below it.
                                        .lineLimit(nil)
                                    // Allows the text to have an unlimited number of lines, so it can wrap to the next line if necessary.
                                        .fixedSize(horizontal: false, vertical: true)
                                    // Allows the text to resize vertically (i.e., wrap text into multiple lines), but does not constrain horizontal resizing.
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    // Makes the frame of the text view take up the maximum available width, and aligns the text to the leading edge (left).
                                }
                                .buttonStyle(PlainButtonStyle()) // Applies a custom button style to prevent the default button styling (like the blue highlight) applied by `NavigationLink`.
                                // This is helpful when you want to prevent any default visual effects associated with button taps.
                                .listRowBackground(Color.clear)   // Sets the background color of the list row to clear, ensuring that no additional visual elements (such as an arrow) appear.
                                // This is useful to maintain a clean look in the list without added distractions like arrows.

                                if user.notification.type == "friendRequest"
                                {
                                    // Checks if the notification type is "friendRequest", indicating that the user has received a friend request.
                                    
                                    Button(action: {
                                        // Creates a button that performs an action when pressed.
                                        if (user.notification.status == "pending")
                                        {
                                            // Checks if the current status of the notification is "pending", indicating that the friend request is still awaiting confirmation.
                                            // Handle Confirm button action here
                                            print ("Accepting friend request")
                                            // Prints a message to the console indicating that the user is accepting the friend request.
                                            let senderId   = user.notification.senderId
                                            let receiverId = user.notification.receiverId
                                            let requestId = senderId + "_" + receiverId
                                            // Creates a request ID by combining the sender's ID and receiver's ID. This is used to identify the specific friend request.
                                            print ("requestID: \(requestId)")
                                            print ("senderID: \(senderId)")
                                            print ("receiverID: \(receiverId)")
                                            // Prints the generated request ID, sender ID, and receiver ID for debugging purposes.
                                                        
                                            // Update status in the model first
                                            //needs to update notification And send notification to accepted user
                                            if let index = viewModel.notificationUsers.firstIndex(where: { $0.uid == user.uid }) {
                                                // Finds the index of the current user in the `notificationUsers` array in the view model using the user's UID.
                                                viewModel.notificationUsers[index].notification.status = "accepted"
                                                // Updates the status of the notification to "accepted".
                                                viewModel.notificationUsers[index].notification.message = "You and $NAME are now friends."
                                                // Updates the notification message to indicate that the users are now friends.
                                                viewModel.notificationUsers[index].full_message = "You and \(user.name) (@\(user.username) are now friends."
                                                // Updates the full message with the user's name and username to reflect the new friendship.
                                            }
                                            userManager.acceptFriendRequest (requestId: requestId, receiverId: receiverId, senderId: senderId)
                                            // Calls the `acceptFriendRequest` function from `userManager` to accept the friend request.
                                            // It passes the `requestId` (a unique identifier for the friend request), `receiverId` (the user receiving the request), and `senderId` (the user who sent the request).
                                               
                                           // __ accepted your friend request
                                               // This is a comment indicating that the action accepts the friend request. The comment is likely a placeholder for the message the user might see or receive in some UI.
                                               
                                            userManager.sendNotificationToAcceptedUser(receiverId: senderId, senderId: receiverId) { success, error in
                                                // Sends a notification to the user who has been accepted as a friend. The `receiverId` is the sender of the friend request, and `senderId` is the user who accepted the request.
                                                   // The closure returns two parameters: `success` (a boolean indicating if the notification was sent successfully) and `error` (any error that occurred).
                                                   
                                                if success {
                                                    // If the notification was sent successfully, this block of code executes.
                                                    print("Notification sent successfully")
                                                    // Prints a success message to the console indicating the notification was successfully sent.
                                                          
                                                          //can be combined with updateNotificationStatus for efficiency
                                                              // A comment suggesting that sending the notification and updating the notification status can be combined into a single function call for efficiency.
                                                          
                                                    userManager.updateNotificationAccepted (user)
                                                    // Calls the `updateNotificationAccepted` method from `userManager` to update the notification status.
                                                                // This likely marks the friend request as accepted and updates the relevant data for the user.
                                                } else {
                                                    print("Error sending notification: \(String(describing: error))")
                                                    // If the notification failed, this block is executed.
                                                                // It prints the error to the console for debugging purposes, showing the error message returned from the notification function.
                                                }
                                            }

                                        }
                                    }) {
                                        Text(user.notification.status == "pending" ? "Confirm" : "Friends")
                                        // This line displays the text for the button. If the notification status is "pending", it shows "Confirm", otherwise it shows "Friends".
                                           // The ternary operator checks the notification status and determines the label accordingly.
                                           
                                            .font(.subheadline)     // Sets the font size to a smaller subheadline for the displayed text.
                                            .padding(.horizontal, 6)      // Adds horizontal padding around the text (left and right), creating spacing between the text and the button's edges.
                                            .padding(.vertical, 3)
                                        // Adds vertical padding around the text (top and bottom), creating spacing between the text and the button's edges.
                                            .background(user.notification.status == "pending" ? Color(red: 140/255, green: 82/255, blue: 255/255) : Color.gray)
                                        // Sets the background color of the button.
                                           // If the notification status is "pending", the background color is a light purple.
                                           // If the status is anything other than "pending", the background color is gray.
                                           
                                            .foregroundColor(.white)
                                        // Sets the text color to white, ensuring the text stands out against the button background.
                                            .cornerRadius(8)
                                        // Rounds the corners of the button to give it a softer, visually appealing appearance.
                                    }
                                    .contentShape(Rectangle())  // Ensure the button area is tappable
                                    .buttonStyle(PlainButtonStyle())  // Avoid default button styles
                                    
                                    if user.notification.status == "pending"{
                                        // This condition checks if the notification's status is "pending".
                                        // If the status is "pending", it triggers the display of the "Delete" button.

                                        Button(action: {
                                            
                                            deleteFriendRequest (notificationUser: user)
                                            // When the button is tapped, it triggers the `deleteFriendRequest` function.
                                                   // This function likely handles the logic to delete the pending friend request for the user and updates the relevant state or UI.
                                            
                                        }) {
                                            Text("Delete")  // The button displays the text "Delete" when the status is "pending".
                                            // This indicates to the user that they can delete the pending friend request.

                                                .font(.subheadline)  // The font is set to `subheadline`, which gives the text a slightly smaller and less prominent appearance, typical for secondary actions like deletion.
                                                .padding(.horizontal, 8)    // Horizontal padding of 8 points is applied to the button, creating spacing between the text and the button's edge on both sides.
                                            // This ensures the button isn't too narrow, improving its tapability.

                                                .padding(.vertical, 3)   // Vertical padding of 3 points is applied, adding spacing above and below the text, making the button taller and more comfortable to tap.
                                                .background(Color.gray) // The button's background color is set to gray, making it visually distinct from other buttons with different statuses (e.g., "Confirm" or "Friends").
                                           

                                                .foregroundColor(.white)     // The text color is set to white, providing strong contrast against the gray background to make the text more legible.
                                                .cornerRadius(8)     // The corners of the button are rounded with a radius of 8 points, giving it a softer and more modern appearance.
                                        }
                                        .contentShape(Rectangle())  // Ensure the button area is tappable
                                        .buttonStyle(PlainButtonStyle())  // Avoid default button styles
                                        
                                    }
                                    
                                }
                                //like, comment - show pic of post
                                // This comment seems to be a placeholder or reminder that this block of code is related to displaying the post's picture, comments, or likes (though it isn't used directly
                            else
                                {
                                // The else block starts here, meaning the previous conditions were not met, and we are in the 'else' scenario.
                                if let post = user.post, user.post_url != nil {
                                    // This conditional checks if the user has a post and the post URL is not nil.
                                           // If both conditions are true, it will attempt to display the post's image.
                                           

                                WebImage(url: URL(string: user.post_url ?? ""))
                                    // Loads the image from the `post_url` string. The `??` operator ensures the URL is not nil, falling back to an empty st
                                    .resizable()
                                    // Makes the image resizable, allowing it to adjust to different screen sizes or layout constraints.
                                    .scaledToFit()  // Ensures the image fits within the frame without distortion
                                    // `scaledToFit()` ensures the image will resize proportionally to fit the frame, avoiding any stretching or distortion.

                                    .frame(width: 40, height: 40) // Sets the image's width and height to 40x40 points.

                                    .clipped() // Crops any part of the image that exceeds the defined frame size (40x40 points).
                                    // This ensures that only the visible part of the image within the frame is shown.
                                }
                                }
                            }
                            HStack
                                {
                                    // HStack starts here: It arranges its child views horizontally in a stack.
                                Spacer()
                                    // Spacer pushes the following view to the right side of the HStack, ensuring it is aligned properly.
                                
                                Text(user.notification.timeAgo)
                                    // Displays the timestamp or how long ago the notification was created.
                                        // The value comes from `user.notification.timeAgo`, which is expected to be a formatted string like "5 minutes ago" or "2 hours ago".

                                    .font(.footnote)
                                    // Sets the font of the text to `.footnote`, which is typically a smaller font size

                                    .foregroundColor(.gray)
                                    // Sets the text color to gray, providing a subtle contrast against the background to signify that the text is secondary (the timestamp).
                                }

                        }
                        //.padding(.vertical, 5)
                    }
                }
            }
            
            Spacer()  // Pushes content to the top
            // This `Spacer()` pushes the content above it to the top of the view. In a vertical stack (`VStack`), it takes up all available vertical space, ensuring the views following it are aligned at the top.

            
        }
        .onAppear
            {
            print ("notifications view appeared")
                // The `.onAppear` modifier is triggered when the `NotificationView` appears on the screen.
                    // This is often used to initialize or refresh data when the view becomes visible.
                    
                    //viewModel.resetNotificationUsers()
                    //populate notifications
                                        
            isLoading = true
                // Sets `isLoading` to true, indicating that data fetching is in progress. This could trigger a loading indicator in the UI.
                
            userManager.fetchNotifications { result in
                // This initiates a request to fetch notifications via the `userManager`. The result will be handled by the closure.
                switch result {
                case .success(let notifications):
                    // If the fetch is successful, the `notifications` array is returned and handled in this case.
                    
                    print("Fetched \(notifications.count) notifications")
                    // Prints the number of notifications fetched for debugging or informational purposes.
                    viewModel.populateNotificationUsers(notifications: notifications)
                    // Updates the `viewModel` with the fetched notifications, populating the `notificationUsers` array. This likely triggers a UI update.
                    isLoading = false
                    // Once the data has been fetched and processed, sets `isLoading` to false to indicate that the loading state has completed.
                    userManager.markNotificationsAsRead()
                    // Marks all notifications as read using the `userManager`. This could update the UI to reflect that the user has seen the notifications.
                               
                    
                case .failure(let error):
                    // If the fetch fails, an error is returned and handled in this case.
                    print("Error fetching notifications: \(error.localizedDescription)")
                    // Prints the error message for debugging purposes.
                }
            }

            }

        .navigationBarTitle("Notifications", displayMode: .inline)
        // Sets the title of the navigation bar to "Notifications" with an inline style.
        .navigationBarBackButtonHidden(false)
        // Ensures the back button is visible in the navigation bar, allowing the user to navigate back to the previous screen.
        
    }
    
    private func deleteFriendRequest(notificationUser: NotificationUser) {
        // Defines a private function to delete a friend request, taking a `NotificationUser` object as input.
        let senderId = notificationUser.notification.senderId
        // Extracts the sender's ID from the notification associated with the `NotificationUser`.
            
        let receiverId = notificationUser.notification.receiverId
        // Extracts the receiver's ID from the notification associated with the `NotificationUser`.
        let requestId = "\(senderId)_\(receiverId)"
        // Constructs a unique request ID by concatenating the sender and receiver IDs with an underscore. This ID will be used to reference the specific friend request document in the database.

        // Reference to the friend request document
        let requestRef = db.collection("friendRequests").document(requestId)

        // Creates a reference to the specific friend request document in the Firestore database, using the constructed `requestId`.
           
        // Delete the friend request
        requestRef.delete { error in
            // Attempts to delete the friend request document from Firestore. The completion handler is called with an optional error parameter if the operation fails.
            if let error = error {
                // If an error occurs during the deletion, this block is executed.
                print("Error deleting friend request: \(error.localizedDescription)")
                // Logs the error message to the console for debugging or troubleshooting.
            } else {
                // If the deletion is successful, this block is executed.
                print("Friend request deleted successfully!")
                // Logs a success message indicating that the friend request has been successfully deleted.
                
                deleteNotification (notificationUser: notificationUser)
                // Calls another function, `deleteNotification`, passing the `notificationUser` object to delete the notification associated with the friend request.
            }
        }
    }
    
    private func deleteNotification(notificationUser: NotificationUser) {
        // Defines a private function to delete a notification, taking a `NotificationUser` object as input.
        guard let currentUser = userManager.currentUser else { return }
        // Checks if the `currentUser` is available in `userManager`. If not, it returns from the function early.
        let db = FirebaseManager.shared.firestore
        // Retrieves a reference to the Firestore database using the shared instance of `FirebaseManager`.
        let notificationsRef = db.collection("notifications")
        // Creates a reference to the "notifications" collection in Firestore, where notification documents are stored.
          
        // Find the notification by its timestamp and receiverId
        
        
        notificationsRef
            .whereField("timestamp", isEqualTo: notificationUser.notification.timestamp)
        // Queries the "notifications" collection to find a notification with a matching `timestamp` field from the provided `notificationUser`.

            .whereField("receiverId", isEqualTo: currentUser.uid)
        // Further filters the query to find notifications where the `receiverId` matches the `currentUser`'s UID.
            .getDocuments { snapshot, error in
                // Executes the query to get documents from the "notifications" collection. The completion handler is called with the `snapshot` or an error if the query
                if let error = error {
                    // If an error occurs while querying, this block is executed.
                    print("Failed to find notification: \(error.localizedDescription)")
                    // Logs an error message to the console if the query fails, providing the error description.
                    return
                    // Exits the function early since the notification could not be found.
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // Checks if the snapshot contains any documents. If `snapshot` is nil or if no documents are found, it executes the else block.
                       
                    print("No matching notification found.")
                    // Logs a message indicating no matching notification was found in the Firestore query.

                    return
                    // Exits the function early if no documents are found, as there's nothing to delete.
                }

                // Delete the notification
                for document in documents {
                    // Iterates through the documents retrieved in the snapshot. In this case, it assumes that the query might return multiple documents.
                    document.reference.delete { error in
                        // Deletes the document using its reference. The completion handler is triggered once the delete operation finishes.
                                
                        if let error = error {
                            // If an error occurs during the deletion, this block executes.
                            print("Error deleting notification: \(error.localizedDescription)")
                            // Logs the error to the console, showing the error message returned by Firestore.
                            return
                            // Exits the closure early if an error occurred, meaning the notification wasn't deleted successfully.

                        }
                        print("Notification deleted successfully.")
                        // Logs a success message to the console if the notification is deleted without errors.

                    }
                }

                // Remove the notificationUser from viewModel.notificationUsers
                if let index = viewModel.notificationUsers.firstIndex(where: { $0.uid == notificationUser.uid }) {
                    // Searches for the first index of `notificationUser` in the `notificationUsers` array by matching its `uid`.
                    // If a match is found, it proceeds to remove the user from the array.
                        
                    viewModel.notificationUsers.remove(at: index)
                    // Removes the `notificationUser` from the `notificationUsers` array at the found index.
                    print("Notification user removed from viewModel.notificationUsers.")
                    // Logs a message indicating that the `notificationUser` has been successfully removed from the array.
                }
            }
    }

 
}

