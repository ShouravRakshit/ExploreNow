//
//  SignUpView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct SignUpView: View
{
    @Environment(\.presentationMode) var presentationMode
    // The `presentationMode` environment variable is used to control the view's navigation stack,
    // specifically to allow dismissing or popping the view when needed (e.g., after a successful sign-up).
    
    // Example text field state
    @State private var name             = ""
    @State private var email            = ""
    @State private var password         = ""
    @State private var confirm_password = ""
    // These are the state variables that store user input for the sign-up form fields:
    // - `name`: Stores the user's name.
    // - `email`: Stores the user's email.
    // - `password`: Stores the user's chosen password.
    // - `confirm_password`: Stores the confirmation password to validate it matches `password`.
    @State private var isPasswordVisible = false //State for toggling password visibility
    @State private var isConfirmPasswordVisible = false //State for toggling confirm password visibility
    // These two state variables are used to toggle visibility of the password fields.
    // If set to `true`, the password will be visible; if `false`, it will be hidden (typically represented by asterisks).
    @State var loginStatusMessage = ""
    // This state variable is used to store a message that indicates the status of the login or sign-up process,
    // for example, "Password is too short" or "Sign-up successful".

    // State variables for password validation
    @State private var isLengthValid: Bool = false
    @State private var hasUppercase: Bool = false
    @State private var hasSpecialCharacter: Bool = false
    
    // These three state variables track whether the password meets certain validation criteria:
    // - `isLengthValid`: Checks if the password is of a valid length (e.g., at least 8 characters).
    // - `hasUppercase`: Checks if the password contains at least one uppercase letter.
    // - `hasSpecialCharacter`: Checks if the password contains at least one special character.

       
//    @State private var navigateToHome = false
//    @State private var navigateToLogin = false
    @State private var username_available = false
    
    // This state variable tracks whether the chosen username is available.
    // It is set after performing a Firestore query to see if the username is already in use.
    @State private var username = ""
    // This state variable stores the username input by the user.

    @State private var navigateToSuggestProfilePic = false
    // This state variable is used to determine if the user should be navigated to a profile picture suggestion screen
    // after completing the sign-up process (triggered after successful account creation).

    @EnvironmentObject var appState: AppState
    // The `appState` environment object is used to manage the application's global state.
    // It could contain data related to the user’s session, authentication state, or app-wide settings.
    @EnvironmentObject var userManager: UserManager
    // The `userManager` environment object is used to handle user-related operations (e.g., signing up, logging in, fetching user data).
  

//    let didCompleteSignUp: () -> Void
    
    // Popular email domains
    let validDomains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "live.com"]
    // This constant array contains popular email domains that can be checked against the user's inputted email
    // to validate the email format or provide suggestions during sign-up.
    var body: some View
    {
        NavigationStack {
            VStack
            {
                // Main heading text ("Sign Up")
                Text("Sign Up")
                    .font(.custom("Sansation-Regular", size: 48)) // Use the Sansation font with a size of 48 for the title
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set the font color to a custom purple (#8C52FF)
                
                    .frame(maxWidth: .infinity) // Ensure the text stretches to fill the available width
                    .multilineTextAlignment(.center) // Center the text horizontally within the frame
                
                // Subtitle text ("Create an Account")
                Text("Create an Account")
                    .font(.custom("Sansation-Regular", size: 20)) // Use the same Sansation font, but with a smaller size (20)
                    .foregroundColor(.black)  // Set the text color to black for the subtitle
                    .padding(.top, 0)       // Add no extra padding at the top of the text
                    .offset(y: 15) // Adjust vertical position with a positive offset (15 points down)
                    .frame(maxWidth: .infinity) // Stretch the text to fill available width
                    .multilineTextAlignment(.center) // Ensure the text is centered horizontally within the frame
                
                // Login status message (e.g., error or success message)
                Text(self.loginStatusMessage)
                    .foregroundColor(.red)      // Set the text color to red for the error message
                    .padding(.top, 10)          // Add padding above the error message for spacing
                
                // Rounded TextField for user input (Name)
                TextField("Name", text: $name) // Bind the text field to the 'name' state variable
                    .padding(12) // Add padding inside the text field to give it space around the text
                    .background(Color.white)  // Set a white background color for the text field
                    .cornerRadius(15) // Make the corners of the text field rounded (15 radius)
                    .autocapitalization(.none)   // Disable auto-capitalization for the text input
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)  // Add a rounded border around the text field
                            .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Set the border color to the same custom purple as the title and give it a line width of 2
                    )
                    .frame(width: 335) // Set a fixed width of 335 points for the text field
                    .padding(.top, 25) // Add 25 points of padding above the text field to create space between it and previous elements
                
               
                TextField("Username", text: $username) // Example text field for username input
                    .padding(12) // Padding inside the text field to provide space between text and border
                    .background(Color.white)  // Set the background color of the text field to white
                    .cornerRadius(15) // Round the corners of the text field with a radius of 15 for a smooth appearance
                    .overlay(
                        RoundedRectangle(cornerRadius: 15) // Add a rounded border with the same corner radius of 15
                            .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2)  // Set a custom purple border color (#8C52FF) and line width of 2
                    )
                    .autocapitalization(.none) // Disable auto-capitalization, ensuring the first letter isn't automatically capitalized for the username input
                    .frame(width: 335) // Set a fixed width for the text field, ensuring consistency across different devices
                    .padding(.top, 20) // Add top padding (20 points) to give space between the text field and any UI elements above it
                    .onChange(of: username) {   // Monitor changes to the username text field
                        isUsernameAvailable ()  // Call the function to check if the username is available each time the username changes
                    }
                
                if username.count > 0
                {
                    HStack
                    {
                        Text(username_available ? "✅" : "❌")                      // Display a check or cross depending on the availability of the username
                            .foregroundColor(username_available ? .green : .red)    // Color the checkmark green if the username is available, otherwise red
                        Text(username_available ? "Username is available" : "Username is taken")                                                // Display a message based on username availability
                            .foregroundColor(.black)                              // Set the text color to black for readability
                            .frame(width: 250, alignment: .leading) // Set a fixed width for the text to keep the layout consistent and align the text to the left
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // Ensure the entire HStack is centered horizontally
                    .padding(.top, 5) // Add padding above the HStack to create space between this section and the elements above it
                }
                
                // Rounded TextField for Email Address input
                TextField("Email Address", text: $email) // The text field is used to capture the user's email input
                    .padding(12)  // Padding inside the text field to provide space around the text
                    .background(Color.white) // Set the background color of the text field to white
                    .cornerRadius(15) // Apply rounded corners with a radius of 15
                    .overlay(
                        RoundedRectangle(cornerRadius: 15) // Add a rounded border around the text field
                            .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Define the border color (purple-ish) and set the border width to 2
                    )
                    .frame(width: 335)  // Set a fixed width of 335 points for the text field
                    .padding(.top, 20)  // Add a top padding of 20 points to create space above the text field
                    .autocapitalization(.none) // Disable autocapitalization for the email field to prevent automatic uppercase of the first letter
                
                ZStack(alignment: .trailing) {
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                        // Listen for changes in the password field and validate the password
                            .onChange(of: password) { newValue in
                                validatePassword(newValue) // Call the validatePassword function with the new password value whenever it changes
                            }
                    } else {
                        // Use SecureField for hiding password input
                        SecureField("Password", text: $password)         // SecureField is used here to mask the password input
                            .padding(12)                                 // Add 12 points of padding inside the SecureField for spacing
                            .background(Color.white)                    // Set the background color of the SecureField to white
                            .cornerRadius(8)                            // Apply rounded corners with a radius of 8 to the SecureField
                            .overlay(
                                // Apply a border around the SecureField with rounded corners
                                RoundedRectangle(cornerRadius: 15)      // Add a border with rounded corners and a radius of 15
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2)        // Define a purple border color and set its width to 2 points
                            )
                            .onChange(of: password) { newValue in
                                validatePassword(newValue)               // Call the validatePassword function with the new value of password
                            }
                            .frame(width: 335)                             // Set the fixed width of the SecureField to 335 points
                            .padding(.top, 20)                           // Add space above the SecureField (top padding of 20 points)
                            .autocapitalization(.none)                  // Disable autocapitalization to prevent the first letter from being capitalized (important for passwords)
                    }
                    
                    // Toggle Button
                    Button(action: {
                        isPasswordVisible.toggle()  // Toggle the boolean value of isPasswordVisible when the button is pressed
                    }) {
                        // The button's content is an image that switches between "eye" and "eye.slash" based on the visibility of the password
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")  // If password is visible, show "eye" icon, else "eye.slash"
                            .foregroundColor(.gray)                                 // Set the icon color to gray
                            .padding(.trailing, 12)                                 // Add padding on the right side of the button for spacing
                            .padding(.top, 20)                                      // Add padding on the top side of the button to provide space above it
                    }
                }
                
                
                VStack {
                    // First validation check: Password length
                    HStack {
                        Text(isLengthValid ? "✅" : "❌")                       // Display a check mark or cross based on the password length validity
                            .foregroundColor(isLengthValid ? .green : .red)     // Green if valid, red if invalid
                        Text("Must be 8 characters long")                       // Instruction text for the password length requirement
                            .foregroundColor(.black)                            // Standard black text color

                            .frame(width: 250, alignment: .leading)             // Fixed width for the instruction text, left-aligned
                    }
                    .padding(.top, 10)                                          // Add space between the first validation and the next section
                    
                    // Second validation check: Uppercase letter
                    HStack {
                        Text(hasUppercase ? "✅" : "❌")                       // Display check mark or cross based on the uppercase letter requirement
                            .foregroundColor(hasUppercase ? .green : .red)     // Green if the condition is met, red otherwise
                        Text("Must have 1 uppercase letter")                   // Instruction text for the uppercase requirement
                            .foregroundColor(.black)                           // Standard black text color
                            .frame(width: 250, alignment: .leading)            // Fixed width for the instruction text, left-aligned
                    }
                    .padding(.top, 5)                                          // Add space between this validation and the next one
                    
                    // Third validation check: Special character
                    HStack {
                        Text(hasSpecialCharacter ? "✅" : "❌")                     // Display check mark or cross based on special character presence
                            .foregroundColor(hasSpecialCharacter ? .green : .red)   // Green if condition is met, red if not
                        Text("Must have 1 special character")                       // Instruction text for the special character requirement
                            .foregroundColor(.black)                                // Standard black text color
                            .frame(width: 250, alignment: .leading)                 // Fixed width for the instruction text, left-aligned
                    }
                    .padding(.top, 5)                                                // Add space between this validation and the next section
                }
                .frame(maxWidth: .infinity, alignment: .center)                     // Center the entire VStack and allow it to stretch to full width
                
                ZStack(alignment: .trailing) {
                    // Conditionally show TextField or SecureField based on the visibility of the password
                    if isConfirmPasswordVisible {
                        // TextField for confirming password when password visibility is ON
                        TextField("Confirm Password", text: $confirm_password)   // Display a standard TextField for confirming the password
                            .padding(12)                                         // Add padding inside the text field for better spacing
                            .background(Color.white)                             // White background for the text field
                            .cornerRadius(15)                                    // Rounded corners to give it a softer look
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)              // Rounded border around the text field
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2)                 // Border color (light purple) and width
                            )
                            .frame(width: 335)                                   // Set a fixed width for the text field to maintain uniformity
                            .padding(.top, 20)                                  // Space above the text field for proper layout separation
                            .autocapitalization(.none)                          // Prevent the first letter from being capitalized in the text field
                            .onChange(of: confirm_password) {                   // Monitor changes to the 'confirm_password' text field
                                passwordsMatch()                                 // Call the passwordsMatch function to validate if the passwords match
                            }
                    } else {
                        // SecureField for confirming password when password visibility is OFF
                        SecureField("Confirm Password", text: $confirm_password)  // Use SecureField for hiding the entered password
                            .padding(12)                                          // Add padding inside the secure field for consistent spacing
                            .background(Color.white)                              // White background for the secure field
                            .cornerRadius(8)                                      // Rounded corners with a smaller radius for a slightly different look
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)              // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2)                 // Border color and width
                            )
                            .onChange(of: confirm_password) {
                                passwordsMatch()                                // Call passwordsMatch() function when the confirm_password field changes
                            }
                            .frame(width: 335)                                  // Set a fixed width for the TextField
                            .padding(.top, 20)                                   // Space above the text field
                            .autocapitalization(.none)                            // Prevent first letter from being capitalized
                    }
                    
                    // Toggle Button to show/hide password.
                    Button(action: {
                        isConfirmPasswordVisible.toggle()                       // Button to trigger password visibility toggle.
                    }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye" : "eye.slash")                                                        // Change the icon depending on the password visibility status
                            .foregroundColor(.gray)                             // Sets the icon color to gray.
                            .padding(.trailing, 12)                             // Adds padding to the right of the icon for spacing.
                            .padding(.top, 20)                                  // Adds top padding to position the button.
                    }
                }
                
                if confirm_password.count > 0                                   // Check if the confirm password text field is not empty.
                {
                    HStack                                                      // Horizontal stack to display two elements side by side (checkbox and text).
                    {
                        Text(passwordsMatch() ? "✅" : "❌")                      // Displays a checkmark (✅) if passwords match, otherwise a cross (❌).
                            .foregroundColor(passwordsMatch() ? .green : .red)  // Sets the color to green if passwords match, red otherwise.
                        Text(passwordsMatch() ? "Passwords Match" : "Passwords do not match")                                             // Displays text based on whether passwords match or not.
                            .foregroundColor(.black)                            // Set the text color to black.
                            .frame(width: 250, alignment: .leading)             // Sets a fixed width for the text and aligns it to the left.
                    }
                    .frame(maxWidth: .infinity, alignment: .center)             // Centers the entire HStack within its parent container.
                    .padding(.top, 10)                                          // Adds padding to the top of the HStack for spacing.
                }
                
                
                // Sign Up Button
                Button(action:                          // Button action when tapped.
                        {
                    // Action for sign up
                    print("Sign Up tapped")             // Prints a message to the console when the button is tapped (for debugging purposes).
                    createNewAccount ()                 // Calls the createNewAccount function to trigger the account creation process.
                })
                {
                    Text("Sign Up")                                          // The text displayed on the button.
                        .font(.custom("Sansation-Regular", size: 23))       // Sets the font for the button text with a custom font and size.
                        .foregroundColor(.white)                             // Sets the text color to white.
                        .padding()                                           // Adds padding inside the button for spacing around the text.
                        .frame(width: 350)                                  // Sets a fixed width for the button (same as the text field width for consistency).
                        .background(Color(red: 140/255, green: 82/255, blue: 255/255))  // Sets the button background color using a custom RGB color (light purple).
                        .cornerRadius(15)                                   // Rounds the corners of the button for a smoother appearance.
                }
                
                .padding(.top, 15)      // Adds padding above the element, creating space between it and the previous component.
                // This NavigationLink is always present in the view hierarchy
                
                
                // "Already have an account? Login" text
                HStack {                                           // Horizontal stack to place the text side by side.
                    Text("Already have an account? ")               // Static text asking if the user already has an account.
                        .foregroundColor(.black)                    // Sets the text color to black for the question.
                    
                    // Login text with underline
                   
                    Text("Login")                                   // Static text showing "Login."
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Sets the text color to a custom purple color matching the theme.
                        .underline() // Underlines the "Login" text to make it look like a clickable link.
                        .onTapGesture {         // Gesture recognizer for tapping the "Login" text.
                            // Action for login navigation
                            print("Login tapped")       // Prints a message when the "Login" text is tapped, useful for debugging.
                            // Navigate to login view (you would implement this based on your navigation logic)
//                            navigateToLogin = true
//                            presentationMode.wrappedValue.dismiss()
                            presentationMode.wrappedValue.dismiss()     // Dismisses the current view directly when "Login" is tapped.

                        }
                }
                .padding(.top, 10)     // Adds padding above the horizontal stack to separate it from the previous UI element.
                
                
                Spacer() // Adds a flexible space between elements, pushing content to the top of the screen.
                .fullScreenCover(isPresented: $navigateToSuggestProfilePic) {   // Conditional modifier to present a full-screen cover when 'navigateToSuggestProfilePic' is true.
                    SuggestProfilePicView()                   // The view that will be presented when the condition is met.
                        .environmentObject(appState)         // Passes the appState object to the presented view.
                            .environmentObject(userManager)     // Passes the userManager object to the presented view.
                  }
                
            }
        }
}
        
           
    private func isUsernameAvailable()
    
    // Define a private function that checks if the entered username is available in the Firestore database.
        {
        let db = Firestore.firestore()
            // Get a reference to the Firestore database. 'Firestore.firestore()' returns the shared Firestore instance for the app.
        
        db.collection("users").whereField("username", isEqualTo: username).getDocuments
                { querySnapshot, error in
                    // Access the "users" collection in Firestore. Then, use 'whereField' to filter documents where the 'username' field is equal to the current value of the 'username' variable.
                    // The 'getDocuments' method fetches the documents that match the filter. The closure handles the results (querySnapshot) or any error.

                if let error = error
                    {
                    // Check if there was an error with the query.
                    print("Error checking username: \(error)")
                    // Print the error message to the console for debugging purposes.
                    self.username_available = false // Set 'username_available' to false because there was an error.
                    return
                    // Return early to avoid further code execution if an error occurred.
                    }
                
                    // Update the variable based on the query result
                self.username_available = querySnapshot?.isEmpty ?? true
                    // If 'querySnapshot' is nil, 'self.username_available' is set to true (username is available).
                    // If 'querySnapshot' is not nil, 'isEmpty' checks whether there are any documents with the given username.
                    // If there are no matching documents, the username is available (true). If there are documents, the username is taken (false).
                print("Username availability updated: \(self.username_available)")
                    // Print the updated availability status to the console for debugging purposes.
                }
        }
        
    
        private func isValidEmailDomain(_ email: String) -> Bool
            {
                // Defines a private function to validate the domain of an email address.
                    
                // Check if the email contains "@" and get the domain part
            guard let domain = email.split(separator: "@").last else { return false }
                // Splits the email string into two parts by the "@" separator. If there is no "@" in the email, the function returns false.
                // If the email contains "@", the domain part after the "@" is assigned to 'domain'.
            return validDomains.contains(String(domain))
                // Checks if the extracted domain exists in the 'validDomains' array (or list).
                // Returns true if the domain is valid, otherwise returns false.
            }

        private func isValidPassword(_ password: String) -> Bool
            {
                // Defines a private function that validates the password based on specific criteria.
                    
                // Check for at least 8 characters, at least one number, and at least one special character
            isLengthValid = password.count >= 8
                // Checks if the password has at least 8 characters. Sets 'isLengthValid' to true if the condition is met, otherwise false.
                    
            hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
                // Checks if the password contains at least one uppercase letter using a regular expression pattern.
                // If the password matches the pattern, 'hasUppercase' is set to true; otherwise, it's false.
            hasSpecialCharacter = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
                // Checks if the password contains at least one special character (anything other than letters and numbers).
                // If the password matches the pattern, 'hasSpecialCharacter' is set to true; otherwise, it's false.
            return isLengthValid && hasUppercase && hasSpecialCharacter
                // Returns true if all validation conditions (length, uppercase, special character) are satisfied, otherwise returns false.
            }
            
        private func validatePassword(_ newValue: String)
            {
                // Defines a private function to validate the password whenever it changes.
                    
            isLengthValid = newValue.count >= 8
                // Checks if the new password is at least 8 characters long and updates 'isLengthValid'.
            hasUppercase = newValue.range(of: "[A-Z]", options: .regularExpression) != nil
                // Checks if the new password contains at least one uppercase letter and updates 'hasUppercase'.
            hasSpecialCharacter = newValue.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
                // Checks if the new password contains at least one special character and updates 'hasSpecialCharacter'.
            }
        
        private func passwordsMatch() -> Bool
            {
                // Defines a private function to check if the password and confirm password are the same.
            if !(password == confirm_password)
                {
                // If the password does not match the confirm password, return false.
                return false
                }
                
            return true
                // If the passwords match, return true.
            }
        

            private func createNewAccount() {
                // Defines a private function that handles the account creation process.
                if !isValidEmailDomain(email) {
                    // If the email domain is not valid, update the login status message and return.
                    loginStatusMessage = "Please enter a valid email from popular domains."
                    return
                }
                
                if !isValidPassword(password)
                    {
                    // If the password is invalid, update the login status message and return.
                    loginStatusMessage = "Invalid password."
                    return
                    }

                
                if !passwordsMatch()
                    {
                    // If the password and confirm password do not match, update the login status message and return.
                    loginStatusMessage = "Password and confirm password do not match."
                    return
                    }
                
                if !username_available{
                    // If the username is not available, update the login status message and return.
                    loginStatusMessage = "Username is not available"
                    return
                }
                
                FirebaseManager.shared.auth.createUser(withEmail: email, password: password)
                // Calls Firebase's authentication service to create a new user with the provided email and password.

                
                { result, err in
                    // Closure that handles the result or error after trying to create the user.
                    if let err = err
                        {
                        // If there was an error during the user creation process.
                        print("Failed to create user: ", err)
                        // Prints the error to the console.
                        self.loginStatusMessage = "Failed to create user: \(err.localizedDescription)"
                        // Sets the status message to indicate user creation failure and displays the error's localized description.
                        return
                        // Exits the closure early, preventing further execution if there was an error.
                        }
                    guard let uid = result?.user.uid else { return }
                    
                    // Uses guard to safely unwrap the `uid` of the newly created user.
                    // If `uid` is nil, it exits the closure without proceeding further.
                    print("Successfully created user: \(result?.user.uid ?? "")")
                    // Prints a success message with the user's UID.
                    // If the UID is nil, it defaults to an empty string.

                    // Create a reference to the Firestore database
                    let db = Firestore.firestore()
                    // Creates a reference to Firestore, which will be used to store user data.
                    // Store additional user data
                    let userData: [String: Any] =
                        [
                        "username": username,
                        "email": email,
                        "name": name,
                        "bio": "",
                        "uid": uid,
                        "profileImageUrl": ""
                        ]
                    // Creates a dictionary `userData` containing the user's details to be stored in Firestore.
                    // It includes the username, email, name, bio, UID (from the `createUser` result), and a placeholder for the profile image URL.
                        // Save user data under the user's UID
                        db.collection("users").document(uid).setData(userData)
                        // Accesses the Firestore "users" collection and attempts to add or update a document with the specified `uid`.
                        // The `userData` dictionary is saved to the document for that user.
                        { error in
                            // Closure to handle the result of the `setData` operation. `error` will be non-nil if the operation fails.
                        if let error = error
                            {
                            // If an error occurs during saving the user data to Firestore.
                            print("Failed to add user data to Firestore: \(error)")
                            // Prints the error message to the console for debugging.
                            self.loginStatusMessage = "Failed to save user data: \(error.localizedDescription)"
                            // Sets the `loginStatusMessage` to show the user-friendly error message.
                            }
                        else
                            {
                            // If the operation succeeds (no error).
                            print("Successfully saved user data to Firestore")
                            // Prints a success message to the console indicating that the user data has been saved.

                            // Navigation link to the HomeView, activated by the state variable
                            // Initialize UserManager after successful signup
                            DispatchQueue.main.async
                                {
                            // Switches to the main queue to update the UI since Firestore operations happen on a background thread.
                                                userManager.fetchCurrentUser()
                                userManager.fetchCurrentUser()
                            // Calls `fetchCurrentUser` on `userManager` to load the current user's data into the app state.

                            // Navigate to the next view if needed
                                navigateToSuggestProfilePic = true
                                    // Sets the state variable `navigateToSuggestProfilePic` to true, which is  used to trigger a navigation to a view where the user can set their profile picture.
                                }
                            }
                        }
                        
                    }
            }
    
        
        }

