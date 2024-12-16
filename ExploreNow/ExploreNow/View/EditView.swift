//

//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import Firebase

struct EditView: View {
    @EnvironmentObject var userManager: UserManager  // Access the shared UserManager object from the environment
    @Environment(\.presentationMode) var presentationMode // Environment value to manage the presentation (dismiss the view)
    var fieldName: String // The name of the field being edited (e.g., "Username" or "Email")
    @State private var fieldValue: String = "" // State variable to store the value of the field being edited (starts empty)
    @State private var username_available = true // State variable to track if the username is available (initially true)
    @State private var username_edited = false // State variable to track if the username has been edited (initially false)
    @StateObject private var viewModel = EditViewModel() // Initialize without parameters

    var body: some View {
        VStack {  // Vertical stack to arrange UI elements vertically
 
        HStack
            { // Horizontal stack for the back button and its properties
            Image(systemName: "chevron.left") // A system image for the back button (left arrow)
                .resizable()  // Makes the image resizable
                .aspectRatio(contentMode: .fit) // Maintains the aspect ratio while resizing
                .frame(width: 30, height: 30) // Sets the width and height of the back arrow
                .padding()  // Adds padding around the image to create spacing
                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Sets the color to a specific shade of purple (#8C52FF)
                .onTapGesture
                    {
                        // Adds a tap gesture recognizer to the back button
                        // Go back to the profile page when the back button is tapped
                    presentationMode.wrappedValue.dismiss() // Dismisses the current view to return to the previous screen
                    }
            Spacer()  // Adds flexible space to push the text towards the center of the parent view
            Text ("Edit \(fieldName)")  // Displays a text label indicating the field being edited, such as "Edit Username"
                .font(.custom("Sansation-Regular", size: 30)) // Applies a custom font ("Sansation-Regular") with a size of 30
                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Sets the text color to a specific shade of purple (#8C52FF)
                .offset(x:-30) // Offsets the text 30 points to the left on the x-axis, likely for positioning adjustments
            Spacer() // Adds flexible space to balance the positioning of the text and push it towards the center of the parent view
            }
            
            //Text("Edit \(fieldName)")
            //    .font(.headline)
            //$fieldValue will update as user types
            // TextField for entering the value of the field being edited
            TextField("Enter \(fieldName)", text: $fieldValue)   // Placeholder text dynamically showing the field name (e.g., "Enter Username")
                .padding(12)  // Adds padding inside the text field to create space around the text
                .background(Color.white) // Sets the background color of the text field to white
                .cornerRadius(15) // Rounds the corners of the text field with a radius of 15 points
                .overlay( // Adds an overlay for the border of the text field
                    RoundedRectangle(cornerRadius: 15) // Creates a rounded rectangle with the same corner radius as the text field
                        .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Sets the border color to the same purple and a border width of 2
                )
                .padding() // Adds padding around the text field, providing spacing from other UI elements
                .autocapitalization(.none)  // Prevents the automatic capitalization of the first letter in the text field
                .onChange(of: fieldValue) {  // Tracks changes to the text field and triggers the isUsernameAvailable function
                    self.username_available = viewModel.isUsernameAvailable (fieldValue: fieldValue) // Calls the function to check if the username is available whenever the field value changes
                }
            Button("Save") {
                // Handle saving the value here
                // You might want to pass this value back to the main view if needed
                save_field ()
                // Go back to profile settings page
                presentationMode.wrappedValue.dismiss() // Dismisses the current view and navigates back to the previous page
            }
                .font(.custom("Sansation-Regular", size: 23))  // Applies a custom font "Sansation-Regular" with size 23 to the button label
                .foregroundColor(.white) // Sets the text color of the button label to white
                .padding() // Adds padding inside the button to make it more visually appealing and increase its tap target area
                .frame(width: 350) // Sets the width of the button to 350 points, matching the width of the TextField for consistency
                .background(Color(red: 140/255, green: 82/255, blue: 255/255)) // Sets the background color of the button to a custom purple (#8C52FF)
                .cornerRadius(15)  // Rounds the corners of the button to create a softer, more modern appearance
            
            // Conditional view that shows feedback if the field is a "Username" and has been edited
            if fieldName == "Username" && username_edited
            {
                HStack
                { // Creates a horizontal stack to display the feedback
                    Text(username_available ? "✅" : "❌") // Displays a green checkmark if the username is available, or a red cross if taken
                        .foregroundColor(username_available ? .green : .red) // Sets the color of the icon based on username availability
                    Text(username_available ? "Username is available" : "Username is taken") // Displays a message based on availability
                        .foregroundColor(.black)  // Sets the text color to black for clarity
                        .frame(width: 250, alignment: .leading) // Fixes the width of the text to 250 points and aligns it to the left
                }
                .frame(maxWidth: .infinity, alignment: .center) // Centers the HStack in the available horizontal space
                .padding(.top, 20) // Adds padding at the top to give the message some spacing from other elements
                .offset(x: 30) // Offsets the HStack 30 points to the right, likely for additional alignment adjustments
            }
            
            Spacer() // Adds flexible space at the bottom to push the content upward, ensuring proper layout in the view
        }
        .padding() // Adds padding around the entire VStack to ensure the content doesn’t touch the edges of the screen
        .navigationTitle("Edit \(fieldName)")  // Sets the navigation bar title dynamically to "Edit \(fieldName)", where fieldName could be "Username" or another value
        .onAppear(){
            viewModel.set_fieldName(fieldName: fieldName)
            setTextField ()
        }
    }
    
    private func setTextField ()
    {
        // This block of code is executed when the view appears on the screen.
        if (fieldName == "Name")
        {
            // If the field being edited is "Name"
            if let name = userManager.currentUser?.name
                {
                // If the current user has a name, set the fieldValue to the user's name
                fieldValue = name
                }
        }
        else if (fieldName == "Username")
        {
            // If the field being edited is "Username"
            if let username = userManager.currentUser?.username
                {
                // If the current user has a username, set the fieldValue to the user's username
                fieldValue = username
                }
        }
        else if (fieldName == "Bio")
        {
            // If the field being edited is "Bio"
            if let bio = userManager.currentUser?.bio
                {
                // If the current user has a bio, set the fieldValue to the user's bio
                fieldValue = bio
                }
        }
    }
    
    private func save_field ()
    {
    // Print a message indicating that the field is being saved
    print ("Saving field")
    // Check if the field being edited is "Name"
    if (fieldName == "Name")
        {
        // If the field is "Name", update the user's name using the setCurrentUser_name method
        userManager.setCurrentUser_name (newName: fieldValue)
        }
        // Check if the field being edited is "Username" and if the username is available and edited
        else if (fieldName == "Username" && self.username_available && self.username_edited)
        {
        // If the field is "Username", the username is available, and it was edited, update the user's username
        userManager.setCurrentUser_username (newUsername: fieldValue)
        }
        // Check if the field being edited is "Bio"
    else if (fieldName == "Bio")
        {
        // If the field is "Bio", update the user's bio using the setCurrentUser_bio method
        userManager.setCurrentUser_bio (newBio: fieldValue)
        }
    }
    

}





