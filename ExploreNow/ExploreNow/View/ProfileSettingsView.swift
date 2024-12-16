//
// ProfileSettingsView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import Firebase
import SDWebImageSwiftUI
struct ProfileSettingsView: View {
    // Use @Environment to access the presentation mode (for dismissing the view)
    @Environment(\.presentationMode) var presentationMode
    // Access the UserManager object from the environment to manage user data
    @EnvironmentObject var userManager: UserManager
    // Access the AppState object from the environment to manage the app's global state
    @EnvironmentObject var appState: AppState
    // Create an instance of UserSettingsManager to handle user settings
    let settingsManager = UserSettingsManager()
  

    // Create a state object for the ProfileSettingsViewModel, passing appState and userManager to it
    @StateObject private var viewModel: ProfileSettingsViewModel

    // Initialize the ProfileSettingsViewModel with appState and userManager when the view is created
    init(appState: AppState, userManager: UserManager) {
        // Initialize the viewModel with the passed appState and userManager
        _viewModel = StateObject(wrappedValue: ProfileSettingsViewModel(appState: appState, userManager: userManager))
    }
    
    // State variable to hold the selected image for profile settings
    @State var image: UIImage?
    // State variable to control the display of the image source options
    @State private var showImageSourceOptions = false
    // State variable to control the display of an image picker from Pixabay
    @State private var showPixabayPicker = false
    // State variable to track the selected row in a list or table
    @State private var selectedRow: String?
    // State variable to control whether to show the edit view for profile settings
    @State private var showEditView       = false
    // State variable to control whether to show the change password view
    @State private var showChangePassword = false
    // State variable to manage the visibility of the blocked users list
    @State private var showBlockedUsers   = false
    // State variable to control whether to show an alert
    @State private var showingAlert = false
    
    
    // Define the body of the view
    var body: some View {
        VStack {
            //----- TOP ROW --------------------------------------
            HStack {
                // Create a back button (chevron icon)
                Image(systemName: "chevron.left")
                    .resizable()                // Make the image resizable
                    .aspectRatio(contentMode: .fit)     // Maintain aspect ratio while resizing
                    .frame(width: 25, height: 25)       // Set the frame size to 25x25
                    .padding()       // Add padding around the image
                    .foregroundColor(Color.customPurple)         // Set the image color to custom purple
                    .onTapGesture {
                        // When the back button is tapped, dismiss the current view (go back to profile page)
                        presentationMode.wrappedValue.dismiss()
                    }
                Spacer()            // Spacer to push elements to the left
                
                // Display the "Settings" title text
                Text("Settings")
                    .font(.custom("Sansation-Regular", size: 25))   // Set a custom font and size for the text
                    .foregroundColor(Color.customPurple)        // Set the text color to custom purple
                    .offset(x: -30)      // Offset the text slightly to the left to create spacing
                Spacer()        // Spacer to push elements to the right
            }
            .padding(.top, 20)  // Add padding to the top of the HStack to create space between the top of the screen and the row
            //------------------------------------------------
            ZStack {
                // Circular border
                Circle()
                    .stroke(Color.customPurple, lineWidth: 4) // Purple border
                    .frame(width: 188, height: 188) // Set the size of the circular border, slightly larger than the image
                if viewModel.isUploading {
                    // Show loading spinner while image is being uploaded
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .customPurple))  // Set the style of the progress view to be circular and custom purple color
                        .frame(width: 180, height: 180) // Set the size of the progress view to match the image size
                }
                else if let selectedImage = self.image {
                    // Display the newly selected image if one exists
                    Image(uiImage: selectedImage)
                        .resizable()         // Allow the image to be resized
                        .scaledToFill()     // Ensure the image covers the frame while maintaining aspect ratio
                        .clipShape(Circle())     // Clip the image to a circular shape
                        .frame(width: 180, height: 180) // Set the frame size for the image
                } else if let imageUrl = self.userManager.currentUser?.profileImageUrl, !imageUrl.isEmpty {
                    // Display existing profile image if available from the user's URL
                    WebImage(url: URL(string: imageUrl))        // Load the image from the provided URL
                        .resizable()            // Allow the image to resize
                        .scaledToFill()         // Ensure the image scales correctly to fill the frame
                        .clipShape(Circle())         // Clip the image into a circular shape
                        .frame(width: 180, height: 180)     // Set the image frame size
                } else {
                    // If no image is available, show a placeholder
                    Image(systemName: "person.fill")         // Use a system icon as a placeholder
                        .resizable()            // Make the placeholder resizable
                        .scaledToFill()          // Ensure the placeholder fills the circular frame
                        .frame(width: 180, height: 180)     // Set the frame size of the placeholder image
                        .foregroundColor(Color(.label))     // Set the color of the placeholder to match the label color (dark/light mode)
                        .background(Color.gray.opacity(0.2))    // Set a light gray background for the placeholder
                        .clipShape(Circle())            // Clip the placeholder image into a circular shape
                }
            }
            .padding(.top, 10)      // Add top padding to the ZStack for spacing
            
            Button(action: {
                showImageSourceOptions = true   // When the button is pressed, set showImageSourceOptions to true to display the action sheet
            }) {
               
                Text(self.userManager.currentUser?.profileImageUrl == nil || (self.userManager.currentUser?.profileImageUrl?.isEmpty ?? true) ? "Upload Profile Picture" : "Change Profile Picture")
                // Check if the current user has a profile image URL:
                // - If there is no URL or the URL is empty, show "Upload Profile Picture"
                // - Otherwise, show "Change Profile Picture"
                    .padding(.top, 15)      // Add top padding to the text for spacing
                    .font(.custom("Sansation-Regular", size: 21))   // Set the font and size for the text
                    .foregroundColor(.blue)     // Set the text color to blue
                    .underline()                 // Underline the text to indicate it is clickable
                    .padding(.bottom, 20)           // Add bottom padding to give some spacing below the text
            }.actionSheet(isPresented: $showImageSourceOptions) {
                // This presents an ActionSheet when showImageSourceOptions is true
                ActionSheet(title: Text("Select Image Source"), message: nil, buttons: [
                    .default(Text("Photo Library")) {
                        showPixabayPicker = true // If "Photo Library" is selected, show the Pixabay picker
                    },
                    .cancel()       // Add a cancel button to close the action sheet
                ])
            }.fullScreenCover(isPresented: $showPixabayPicker) {
                // This presents a full-screen cover when showPixabayPicker is true
                // The content of the cover is the PixabayImagePickerView.
                   
                PixabayImagePickerView(allowsMultipleSelection: false) { selectedImages in
                    // Initializes the Pixabay image picker. It only allows selecting a single image (allowsMultipleSelection: false).
                    // The closure receives an array of selected images.
                    if let selectedImage = selectedImages.first,
                       let urlString = selectedImage.largeImageURL,
                       let url = URL(string: urlString) {
                        // If the first selected image exists, and it contains a valid URL string for the large image,
                        // attempt to convert the string to a URL.
                        viewModel.downloadImage(from: url) { downloadedImage in
                            // Call the view model’s downloadImage method to download the image from the URL.
                            if let downloadedImage = downloadedImage {
                                // If the image is successfully downloaded, set it to the `image` property.
                                self.image = downloadedImage
                                // Call persistImageToStorage() to store the image in storage after it’s set.
                                viewModel.persistImageToStorage(image: downloadedImage)
                            } else {
                                // If the image download failed, print an error message.
                                print("Image download failed.")
                            }
                            // Dismiss the image picker once the image is handled.
                            self.showPixabayPicker = false
                        }
                    } else {
                        // If the selected image is invalid or no image was selected, print an error message.
                        print("Invalid image selection.")
                        // Dismiss the image picker even if the selection is invalid.
                        self.showPixabayPicker = false
                    }
                }
            }
            
            // Profile Information Grid
            Grid {
                // Creates a grid container, which arranges elements in a grid layout (rows and columns).
                Divider()
                // Adds a divider to separate sections of the grid for visual distinction.
                GridRow {
                    // Defines a single row inside the grid.
                    HStack {
                        // Creates a horizontal stack to arrange views (Text) in a horizontal line.
                        Text("Name:")
                            .frame(maxWidth: 125, alignment: .leading)
                            .padding(.leading, 10)
                            .font(.custom("Sansation-Bold", size: 20))
                        // The label "Name" displayed in bold, with custom font and padding.
                        // The `frame(maxWidth: 125)` ensures the label has a maximum width of 125 points.
                        // The alignment `.leading` makes sure the text is aligned to the left.

                        if let name = self.userManager.currentUser?.name {
                            // Checks if the current user's name exists in the `userManager`.
                            // If the name is available, it displays it.
                            Text(name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: -10)
                                .font(.custom("Sansation-Regular", size: 20))
                            // Displays the current user's name with custom font size.
                            // The `frame(maxWidth: .infinity)` makes sure the name takes up the available space.
                            // The `offset(x: -10)` shifts the text slightly to the left to adjust the positioning.
                        }
                    }
                    .padding(.vertical, 5)
                    // Adds vertical padding (top and bottom) to the HStack, making it less cramped.
                    .background(selectedRow == "Name" ? Color.blue.opacity(0.1) : Color.clear)
                    // Applies a background color to the row if it’s the selected row (in this case, "Name").
                    // If the row is selected, it highlights with a light blue color (opacity 0.1), otherwise, it’s transparent (clear).
                            
                    .onTapGesture {
                        selectedRow = "Name" // Updates the selected row to "Name" when the row is tapped.
                        showEditView = true // Triggers the view to show an edit view for the "Name" section.
                    }
                }
                
                Divider()
                // Adds another divider after the row to separate it from the next section.
                
                GridRow {
                    // Defines a new row inside the grid.
                    HStack {
                        // Creates a horizontal stack to arrange the views inside this row horizontally.
                        Text("Username:")
                            .frame(maxWidth: 125, alignment: .leading)
                            .padding(.leading, 10)
                            .font(.custom("Sansation-Bold", size: 20))
                        // The label "Username" is displayed with custom styling:
                        //  - Maximum width is set to 125 points, with left alignment.
                        //  - Padding of 10 points is added to the left side of the label.
                        //  - The font is set to a custom bold font at size 20.


                        if let username = self.userManager.currentUser?.username {
                            // Checks if the `currentUser` has a `username` available in the `userManager`.
                            // If `username` exists, it displays it.
                            Text(username)
                                .offset(x: -10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.custom("Sansation-Regular", size: 20))
                            // Displays the current user's username.
                            //  - The `offset(x: -10)` shifts the text slightly to the left for alignment.
                            //  - The frame takes the maximum available width, and the text is aligned to the left.
                            //  - The font is set to a custom regular font at size 20.
                        }
                    }
                    .padding(.vertical, 5)
                    // Adds vertical padding (top and bottom) to the HStack for spacing between rows.
                    .background(selectedRow == "Username" ? Color.blue.opacity(0.1) : Color.clear)
                    // Applies a background color to the row if it's selected:
                    //  - If the row is selected (`selectedRow == "Username"`), a light blue color (opacity 0.1) is applied.
                    //  - If the row is not selected, it remains transparent (`Color.clear`).

                    .onTapGesture {
                        selectedRow = "Username" // Updates the selected row to "Username" when tapped.
                        showEditView = true // Triggers the display of the edit view for "Username".
                    }
                    // When the row is tapped, it updates the `selectedRow` to "Username" and triggers the `showEditView` to display the edit view.
                }
                
                Divider()
                // Adds a divider after the row to visually separate this section from the next in the grid.
                
                GridRow {
                    // Defines a new row inside the grid.
                    HStack {
                        // Creates a horizontal stack to arrange the views inside this row horizontally.
                        Text("Bio:")
                            .frame(maxWidth: 125, alignment: .leading)
                            .padding(.leading, 10)
                            .font(.custom("Sansation-Bold", size: 20))
                        // The label "Bio" is displayed with custom styling:
                        //  - Maximum width is set to 125 points, with left alignment.
                        //  - Padding of 10 points is added to the left side of the label.
                        //  - The font is set to a custom bold font at size 20.
                        if let bio = self.userManager.currentUser?.bio {
                            // Checks if the `currentUser` has a `bio` available in the `userManager`.
                            // If `bio` exists, it displays it.
                            Text(bio)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: -10)
                                .font(.custom("Sansation-Regular", size: 20))
                                .lineLimit(nil) // Allow for multiple lines
                                .fixedSize(horizontal: false, vertical: true) // Allow the bio text to grow vertically
                            // Displays the user's bio with custom regular font and alignment.
                            //  - `lineLimit(nil)` ensures the bio can take multiple lines if needed.
                            //  - `fixedSize(horizontal: false, vertical: true)` allows the bio to grow vertically without
                        } else {
                            // If there is no bio, an empty text view is displayed.
                            Text(" ")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: -10)
                                .font(.custom("Sansation-Regular", size: 20))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            // This ensures that if no bio is set, the layout remains consistent with an empty space.
                        }
                    }
                    .padding(.vertical, 5)
                    // Adds vertical padding (top and bottom) to the HStack for spacing between rows.
                    .background(selectedRow == "Bio" ? Color.blue.opacity(0.1) : Color.clear)
                    // Applies a background color to the row if it's selected:
                    //  - If the row is selected (`selectedRow == "Bio"`), a light blue color (opacity 0.1) is applied.
                    //  - If the row is not selected, it remains transparent (`Color.clear`).

                    .onTapGesture {
                        selectedRow = "Bio" // Updates the selected row to "Bio" when tapped.
                        showEditView = true  // Triggers the display of the edit view for "Bio".
                    }
                    // When the row is tapped, it updates the `selectedRow` to "Bio" and triggers the `showEditView` to display the edit view.
                   
                }
                
                Divider()
                // This divider creates a visual separation between sections of the UI, helping to organize content visually.

            }
            .padding (.top, 5)
            // Adds a small padding of 5 points above the divider to ensure it doesn't touch the preceding UI elements.
            
            Text("Blocked Users >")
            // A label that provides a link to manage blocked users. The ">" symbol indicates that tapping the text leads to more details or a separate view.
                .padding(.top, 10)
            // Adds 10 points of padding above the text for spacing, ensuring it isn't too close to the preceding UI elements.
                .font(.custom("Sansation-Regular", size: 18))
            // Specifies a custom font ("Sansation-Regular") with a size of 18 for the text, ensuring consistency in the app's typography.
                .foregroundColor(.red)
            // Sets the text color to red, emphasizing the importance or danger associated with the action (e.g., managing blocked users).
                .onTapGesture {
                    // When the user taps on the "Blocked Users" text, this triggers the action to show a list or a new view for blocked users.
                    showBlockedUsers = true
                }
            
            ToggleButtonView(userId: userManager.currentUser?.uid ?? "")
            // A custom toggle button component (ToggleButtonView) that likely handles toggling a setting, such as blocking/unblocking a user.
            // The user's ID is passed to manage the state for the current user.

            Button(action: {
                showChangePassword = true
            }) {
                // A button that triggers a password change flow when pressed.
                Text("Change Password")
                    .font(.custom("Sansation-Regular", size: 16))
                // Uses the same custom font ("Sansation-Regular") with a size of 16 for the button text.
                    .frame(width: 360, height: 50)
                // Sets the button dimensions to 360 points wide and 50 points high for a larger tap target.
                    .background(Color.purple)
                // Sets the button's background color to purple for visual emphasis.
                    .foregroundColor(.white)
                // Sets the button's text color to white for contrast against the purple background.
                    .cornerRadius(22)
                // Rounds the corners of the button, giving it a soft, modern appearance.
                    .shadow(radius: 4)
                // Adds a shadow effect to the button to make it stand out more against the background.
            }
            .padding(.top, 5)
            // Adds 5 points of top padding, ensuring there is space between this button and the elements above it.
            
            
            // "Delete Account" Button
            Button(action: {
                showingAlert = true         // When the button is tapped, this triggers an alert to show, confirming account deletion.
            }) {
                Text("Delete Account")
                    .font(.custom("Sansation-Regular", size: 16))
                // Applies the custom "Sansation-Regular" font with a size of 16 to the button text for consistency in typography.
                    .frame(width: 360, height: 50)
                // Sets the button's width to 360 points and height to 50 points, ensuring a large, easy-to-tap area.
                    .background(Color.red)
                // Sets the button's background color to red, signaling caution or danger, as it relates to deleting an account.
                    .foregroundColor(.white)
                // Sets the button's text color to white to contrast against the red background for better visibility.
                    .cornerRadius(22)
                // Applies rounded corners to the button, providing a soft and modern appearance.
                    .shadow(radius: 4)
                // Adds a shadow effect to the button, helping it stand out visually from the background and other UI elements.
            }
            .padding(.top, 5)
            // Adds 5 points of padding above the button, ensuring there is space between it and any elements above.
            
            Spacer()
            // Adds a spacer to push the content upward, making the layout more flexible and preventing elements from sticking to the bottom of the screen.
            Spacer()
            // Another spacer to ensure that any content below this button is pushed down, creating more space above the button.
        }
        .padding(.horizontal, 15)
        // Adds 15 points of horizontal padding around the entire content, ensuring it doesn't touch the screen's edges for a more polished look.
    
        .fullScreenCover(isPresented: $showEditView) {
            // This line presents a full-screen modal view when the 'showEditView' state variable is true.
            if selectedRow == "Name" {
                // If the selected row is "Name", present the 'EditView' for editing the Name field.
                EditView(fieldName: "Name")
                    .environmentObject(userManager)
                // Passes the 'userManager' environment object to the 'EditView' for access to the user's data.
            } else if selectedRow == "Username" {
                // If the selected row is "Username", present the 'EditView' for editing the Username field.
                EditView(fieldName: "Username")
                    .environmentObject(userManager)
            } else if selectedRow == "Bio" {
                // If the selected row is "Bio", present the 'EditView' for editing the Bio field.
                EditView(fieldName: "Bio")
                    .environmentObject(userManager)
            
            }
        }
        .fullScreenCover(isPresented: $showChangePassword) {
            // Presents a full-screen modal when the 'showChangePassword' state variable is true.
            ChangePasswordView()
                .environmentObject(userManager)
            // Passes the 'userManager' environment object to the 'ChangePasswordView' for accessing user data.
        }
        .fullScreenCover(isPresented: $showBlockedUsers) {
            // Presents a full-screen modal when the 'showBlockedUsers' state variable is true.
            BlockedUsersView()
                .environmentObject(userManager)
            // Passes the 'userManager' environment object to the 'BlockedUsersView' for managing blocked users.
        }
        .alert(isPresented: $showingAlert) {
            // Displays an alert when the 'showingAlert' state variable is true.
             Alert(
                 title: Text("Delete Account?"),
                 // Sets the alert's title to "Delete Account?".
                 message: Text("Are you sure you want to delete your account?"),
                 // Sets the alert's message prompting the user to confirm the account deletion.
                 primaryButton: .destructive(Text("Delete")) {
                     // Sets the primary button to a destructive style, meaning it will indicate an action that cannot be undone (deleting the account).
                     viewModel.deleteAccount { result in
                         // Calls the 'deleteAccount' method in the view model, passing a completion handler to handle success or failure.
                         switch result {
                             // Switch statement to handle different outcomes of the deletion process.
                         case .success:
                             print("Account deleted successfully.")
                             // Prints a success message when the account is deleted successfully.
                             viewModel.signOut()
                             // Signs the user out after successful account deletion.
                         case .failure(let error):
                             print("Failed to delete account:", error.localizedDescription)
                             // Prints an error message if the account deletion fails.
                         }
                     }
                 },
                 secondaryButton: .cancel {
                     // Sets the secondary button to "Cancel", which dismisses the alert without performing any action.
                     print("Delete Account canceled.")
                     // Prints a cancellation message when the user cancels the account deletion.
                 }
             )
         }
    }
 
}

struct ToggleButtonView: View {
    // Defines the 'ToggleButtonView' struct as a custom view.
    @State private var isPublic: Bool = false
    // State variable to track whether the account is public or private. Default is 'false' (private).
    @State private var isLoading: Bool = true
    // State variable to track the loading state. The default value is 'true', meaning it's loading initially.

    let userId: String
    // A constant property that represents the user ID, passed into the view.
    
    var body: some View {
        VStack {
            // Vertical stack to organize the elements in a column.
            if isLoading {
                // Conditionally displays the loading indicator if 'isLoading' is true.
                ProgressView("Loading...")
                // Displays a loading spinner with the text "Loading..."
            } else {
                // If not loading, display the toggle switch for the "Public Account" setting.
                Toggle("Public Account", isOn: $isPublic)
                // A toggle switch that lets the user enable or disable a public account.
                    .toggleStyle(SwitchToggleStyle())
                // Applies the standard switch-style toggle appearance.
                    .onChange(of: isPublic) { newValue in
                        // Monitors the state change of 'isPublic' and triggers an action when the value changes.
                        updatePublicSetting(isPublic: newValue)
                        // Calls a method to update the public setting based on the new value.
                    }
                    .padding()
                // Adds padding around the toggle for spacing.
            }
        }
        .onAppear {
            // Triggers the action when the view appears on the screen.
            fetchPublicSetting()
            // Calls a method to fetch the current public setting for the user.
        }
        .padding()
        // Adds padding around the entire VStack to space it from surrounding content.
    }

    /// Fetch the public field from Firestore
    // This function retrieves the "public" field from Firestore for the current user's settings document.
    private func fetchPublicSetting() {
        // Defines the function as private, meaning it can only be accessed within this file.
        let db = Firestore.firestore()
        // Gets an instance of Firestore to interact with the database.
        let settingsRef = db.collection("settings").document(userId)
        // Creates a reference to the "settings" collection and the specific document for the user, identified by `userId`.

        settingsRef.getDocument { document, error in
            // Fetches the document from Firestore asynchronously. The closure provides either the document or an error.
            if let error = error {
                // Checks if there was an error during the fetch operation.
                print("Error fetching document: \(error.localizedDescription)")
                // Logs the error message to the console.
                isPublic = false
                // Defaults `isPublic` to `false` if an error occurs.
                isLoading = false
                // Sets `isLoading` to `false` to indicate loading is complete, even though there was an error.
                return
                // Exits the function early since an error occurred.
            }

            if let document = document, document.exists {
                // Checks if the document exists in Firestore.
                isPublic = document.get("public") as? Bool ?? false
                // Retrieves the "public" field from the document. If it's not a Bool or doesn't exist, defaults to `false`.
            } else {
                // Executes if the document does not exist.
                print("Document does not exist, creating default record.")
                // Logs a message indicating that the document is missing and a default one will be created.
                isPublic = false
                // Sets `isPublic` to `false` as the default value.
                // Create a new document with default values
                settingsRef.setData(["public": isPublic]) { error in
                    // Sets a new document in Firestore with the default "public" field.
                    if let error = error {
                        // Checks if there was an error while creating the document.
                        print("Error creating default document: \(error.localizedDescription)")
                        // Logs the error message to the console.
                    } else {
                        // Executes if the document was successfully created.
                        print("Default document created successfully.")
                        // Logs a success message to indicate the default document was added.
                    }
                }
            }

            isLoading = false
            // Indicates that loading is complete by setting `isLoading` to `false`.
        }
    }


    /// Update the public field in Firestore
    // This function updates the "public" field in the Firestore document for the current user.
    private func updatePublicSetting(isPublic: Bool) {
        // Defines the function as private and accepts a parameter `isPublic` to indicate the desired public setting.
        let db = Firestore.firestore()
        // Gets an instance of Firestore to interact with the database.
        let settingsRef = db.collection("settings").document(userId)
        // Creates a reference to the "settings" collection and the specific document for the user, identified by `userId`.

        settingsRef.setData(["public": isPublic], merge: true) { error in
            // Updates the "public" field in the Firestore document. The `merge: true` option ensures other fields in the document are not overwritten.
            if let error = error {
                // Checks if there was an error during the update operation.
                print("Error updating document: \(error.localizedDescription)")
                // Logs the error message to the console.
            } else {
                // Executes if the update operation is successful.
                print("Public setting updated to \(isPublic).")
                // Logs a success message indicating the new value of the "public" field.
            }
        }
    }
}

