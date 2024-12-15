//
//  ChangePasswordView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import Firebase


//------------------------------------------------------------------------------------
struct ChangePasswordView: View
    {
    @Environment(\.presentationMode) var presentationMode     // Accesses the presentation mode environment variable, allowing control over the view's navigation stack (e.g., to dismiss the current view).
    @EnvironmentObject var userManager: UserManager  // Accesses a shared instance of `UserManager` from the environment, allowing interaction with user management logic (e.g., fetching or updating user data).
    
    @State var entered_password    : String = ""   // Declares a state variable to store the entered current password, initially set to an empty string. This is used for user input.
    @State var new_password        : String = ""     // Declares a state variable to store the new password entered by the user, initially set to an empty string.
    @State var confirm_new_password: String = ""    // Declares a state variable to store the confirmed new password, initially set to an empty string.

    //State for toggling password visibility
    @State private var isPasswordVisible           = false  // Declares a state variable to toggle the visibility of the current password. Initially set to `false` (hidden).
    @State private var isNewPasswordVisible        = false  // Declares a state variable to toggle the visibility of the new password. Initially set to `false` (hidden).
    @State private var isConfirmNewPasswordVisible = false   // Declares a state variable to toggle the visibility of the confirm new password. Initially set to `false` (hidden).
    
    @State private var showAlert   : Bool = false        // Declares a state variable to control the display of alerts. Initially set to `false`, meaning no alert is shown.
    @State private var alertMessage: String = ""        // Declares a state variable to store the message to be displayed in the alert. Initially set to an empty string.
    @State private var alertTitle  : String = ""        // Declares a state variable to store the title of the alert. Initially set to an empty string.

    // State variables for new password validation
    @State private var isLengthValid      : Bool = false     // Declares a state variable to track if the new password meets the length requirement (e.g., at least 8 characters). Initially set to `false`.
    @State private var hasUppercase       : Bool = false      // Declares a state variable to track if the new password contains at least one uppercase letter. Initially set to `false`.
    @State private var hasSpecialCharacter: Bool = false    // Declares a state variable to track if the new password contains at least one special character. Initially set to `false`.
    
    @State private var password_changed_success : Bool = false  // Declares a state variable to track if the password change was successful. Initially set to `false`.
    
    
    var body: some View         // Defines the main body of the SwiftUI view.
        {
            VStack              // Arranges the elements vertically in a stack.
                {
                HStack      // Arranges the elements horizontally in a stack.
                    {
                        Image(systemName: "chevron.left")        // Displays a left arrow icon.
                        .resizable() // Make the image resizable
                        .aspectRatio(contentMode: .fit)  // Ensures the image maintains its aspect ratio.
                        .frame(width: 30, height: 30) // Sets the size of the image to 30x30.
                        .padding()      // Adds padding around the image.
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Sets the image color to a purple shade (#8C52FF).
                        .onTapGesture           // Adds a tap gesture to the image.
                            {
                                // Action when the image is tapped.
                                presentationMode.wrappedValue.dismiss()  // Dismisses the current view to go back to the previous page.
                            }
                    Spacer() // Pushes the text to the center
                    Text ("Change Password")    // Displays the title text.
                            .font(.custom("Sansation-Regular", size: 30))    // Sets a custom font and size for the text.
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                        .offset(x:-30)      // Moves the text slightly to the left by 30 points.
                    Spacer() // Adds space to balance the layout and keep the title centered.
                    }
                    
                    ZStack(alignment: .trailing)     // Checks if the password visibility toggle is on.
                    {
                    if isPasswordVisible {
                        TextField("Enter Current Password", text: $entered_password)    // A plain text field for entering the current password.
                            .padding(12)        // Adds padding inside the text field.
                            .background(Color.white)        // Sets the background color of the text field to white.
                            .cornerRadius(15)       // Rounds the corners of the text field with a radius of 15.
                            .overlay(       // Adds a border overlay to the text field.
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                    } else {
                        SecureField("Enter Current Password", text: $entered_password) // Use SecureField for hidden password
                            .padding(12)        // Adds padding inside the secure text field.
                            .background(Color.white)        // Sets the background color of the secure text field to white.
                            .cornerRadius(8)    // Rounds the corners of the secure text field with a radius of 8.
                            .overlay(
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                    }
                    
                    // Toggle Button
                    Button(action: {
                        isPasswordVisible.toggle() // Toggle password visibility
                    }) {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash") // Change icon based on visibility
                            .foregroundColor(.gray)
                            .padding(.trailing, 12) // Add some spacing to the right of the button
                            .padding(.top, 20) // Space above the text field
                    }
                }
                    
                ZStack(alignment: .trailing) {  // Stacks elements on top of each other, aligning them to the trailing (right) edge.
                    if isNewPasswordVisible {   // Checks if the new password visibility toggle is on.
                        TextField("Enter New Password", text: $new_password)     // A plain text field for entering the new password.
                            .padding(12)    // Adds padding inside the text field.
                            .background(Color.white)        // Sets the background color of the text field to white.
                            .cornerRadius(15)    // Rounds the corners of the text field with a radius of 15.
                            .overlay(   // Adds a border overlay to the text field.
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                            .onChange(of: new_password) { newValue in   // Observes changes to the new password.
                                validatePassword(newValue)  // Calls the `validatePassword` function to validate the new password as it is typed.
                            }
                    } else {    // Executes when `isNewPasswordVisible` is false, meaning the password input should be hidden.
                        SecureField("Enter New Password", text: $new_password) // Use SecureField for hidden password
                            .padding(12)    // Adds 12 points of padding inside the secure text field.
                            .background(Color.white)    // Sets the background color of the secure text field to white.
                            .cornerRadius(8)    // Rounds the corners of the secure text field with a radius of 8.
                            .overlay(    // Adds an overlay to the secure text field.
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                            .onChange(of: new_password) { newValue in   // Observes changes to the `new_password` state variable.
                                validatePassword(newValue)   // Calls the `validatePassword` function whenever the password is updated, allowing for real-time validation.
                            }
                    }
                    
                    // Toggle Button
                    Button(action: {
                        isNewPasswordVisible.toggle() // Toggle password visibility
                    }) {
                        Image(systemName: isNewPasswordVisible ? "eye" : "eye.slash") // Change icon based on visibility
                            .foregroundColor(.gray)
                            .padding(.trailing, 12) // Add some spacing to the right of the button
                            .padding(.top, 20) // Space above the text field
                    }
                }
                    
                VStack {    // Creates a vertical stack to arrange the password validation messages vertically.
                    HStack {    // Creates a horizontal stack to arrange the checkmark or cross symbol and validation text side by side.
                        Text(isLengthValid ? "✅" : "❌") // Displays a green checkmark (✅) if `isLengthValid` is true, otherwise displays a red cross (❌).
                            .foregroundColor(isLengthValid ? .green : .red) // Sets the color of the symbol to green if valid, otherwise red for invalid.
                        Text("Must be 8 characters long")    // Displays the password validation message for minimum length.
                            .foregroundColor(.black)     // Sets the text color to black for readability.
                            .frame(width: 250, alignment: .leading) // Sets a fixed width of 250 points for the text and aligns it to the left within the frame.
                    }
                    .padding(.top, 10)  // Adds 10 points of padding above the HStack to create spacing from the previous element.
                    
                    HStack {    // Creates another horizontal stack for the next validation message.
                        Text(hasUppercase ? "✅" : "❌")  // Displays a green checkmark (✅) if `hasUppercase` is true, otherwise displays a red cross (❌).
                            .foregroundColor(hasUppercase ? .green : .red)   // Sets the color of the symbol to green if valid, otherwise red for invalid.
                        Text("Must have 1 uppercase letter")    // Displays the password validation message for the presence of at least one uppercase letter.
                            .foregroundColor(.black)     // Sets the text color to black for readability.
                            .frame(width: 250, alignment: .leading) // Sets a fixed width of 250 points for the text and aligns it to the left within the frame.
                    }
                    .padding(.top, 5)   // Adds 5 points of padding above this HStack to create spacing from the previous validation message.
                    
                    HStack {    // Creates a horizontal stack to display the special character validation message.
                        Text(hasSpecialCharacter ? "✅" : "❌")   // Displays a green checkmark (✅) if `hasSpecialCharacter` is true, otherwise a red cross (❌).
                            .foregroundColor(hasSpecialCharacter ? .green : .red)   // Sets the color to green if valid, otherwise red for invalid.
                        Text("Must have 1 special character")   // Describes the validation rule for at least one special character in the password.
                            .foregroundColor(.black)    // Ensures the text color is black for readability.
                            .frame(width: 250, alignment: .leading)  // Sets the text to have a fixed width of 250 points and aligns it to the left.
                    }
                    .padding(.top, 5)   // Adds a 5-point vertical padding above the HStack for spacing from the previous message.
                }
                .frame(maxWidth: .infinity, alignment: .center) // Center the entire VStack
                    
                    
                ZStack(alignment: .trailing) {  // Creates a ZStack for layering the password confirmation field and its visibility toggle button.
                    if isConfirmNewPasswordVisible {     // Checks whether the confirmation password should be visible.
                        TextField("Confirm New Password", text: $confirm_new_password)  // Displays a regular `TextField` for entering the confirmation password if visibility is enabled.
                            .padding(12)    // Adds internal padding inside the text field for better spacing.
                            .background(Color.white)     // Sets the background color of the text field to white for visibility.
                            .cornerRadius(15)    // Adds rounded corners to the text field with a radius of 15 points.
                            .overlay(   // Adds a border overlay around the text field.
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                        
                    } else {
                        SecureField("Confirm New Password", text: $confirm_new_password) // Use SecureField for hidden password entry to ensure confidentiality.
                            .padding(12)     // Adds 12 points of internal padding inside the field for better spacing and a comfortable appearance.
                            .background(Color.white)    // Sets the background color of the SecureField to white for visibility and contrast against other UI elements.
                            .cornerRadius(8)    // Applies rounded corners with a radius of 8 points to give the field a modern, softer design.
                            .overlay(   // Adds a border overlay to the field for enhanced visual clarity.
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                        /*
                            .onChange(of: confirm_new_password) {
                                passwordsMatch()
                            }
                         */
                    }
                    
                    // Toggle Button
                    Button(action: {
                        isConfirmNewPasswordVisible.toggle() // Toggle password visibility
                    }) {
                        Image(systemName: isConfirmNewPasswordVisible ? "eye" : "eye.slash") // Change icon based on visibility
                            .foregroundColor(.gray)
                            .padding(.trailing, 12) // Add some spacing to the right of the button
                            .padding(.top, 20) // Space above the text field
                    }
                }

                if confirm_new_password.count > 0   // Checks if the user has entered any text in the "Confirm New Password" field.
                    {
                    HStack   // Arranges the checkmark (or cross) and text in a horizontal layout.
                        {
                            Text(passwordsMatch() ? "✅" : "❌")   // Displays a green checkmark if passwords match, otherwise a red cross.
                                .foregroundColor(passwordsMatch() ? .green : .red)  // Sets the color based on whether the passwords match or not.
                            Text(passwordsMatch() ? "Passwords Match" : "Passwords do not match")   // Dynamically displays appropriate feedback text.
                                .foregroundColor(.black)    // Sets the text color to black for readability.
                                .frame(width: 250, alignment: .leading) // Ensures the text has a fixed width and aligns to the left for consistency.
                        }
                        .frame(maxWidth: .infinity, alignment: .center)  // Centers the entire HStack horizontally within its parent container
                        .padding(.top, 10)  // Adds 10 points of padding above the HStack for spacing from the previous element.
                    }
                    
                Button("Save") {
                        // Handle saving the value here
                        // You might want to pass this value back to the main view if needed
                        save_password ()
                        // Go back to profile settings page
                    }
                    .font(.custom("Sansation-Regular", size: 23))   // Applies a custom font "Sansation-Regular" with a size of 23 to the button text.
                    .foregroundColor(.white) // Set text color to black
                    .padding()  // Adds padding around the button's text to increase clickable area and improve layout.
                    .frame(width: 350) // Same width as TextField
                    .background(Color(red: 140/255, green: 82/255, blue: 255/255)) // Button color
                    .cornerRadius(15) // Rounded corners
                    .padding(.top, (confirm_new_password.count > 0) ? 10 : 30)   // Dynamically adjusts the top padding: 10 if `confirm_new_password` has input, otherwise 30 for spacing.
                    
                    if entered_password.count > 0 && new_password.count > 0 && entered_password == new_password  // Checks if both fields have input and the entered password matches the new password.
                    {
                        Text ("Password and New Password Must be Different!")    // Displays a warning message if the old and new passwords are identical.
                        .font(.custom("Sansation-Regular", size: 18))   // Uses a smaller custom font for the warning message.
                        .foregroundColor(.red)  // Sets the message text color to red to indicate an error or warning.
                        .frame(maxWidth: .infinity, alignment: .center)  // Centers the text horizontally within its parent container.
                        .padding ()  // Adds padding around the message for spacing from other elements.
                    }
                Spacer()    // Adds flexible space below the content to push other elements upward, ensuring a balanced layout.
                }
                //Updates user on success or failure of changing password
                .alert(isPresented: $showAlert) {   // Triggers an alert when `showAlert` is true.
                    Alert(
                        title: Text(alertTitle),     // Displays a dynamic title for the alert (e.g., "Success" or "Error").
                        message: Text(alertMessage),    // Shows a detailed message explaining the success or failure.
                        dismissButton: .default(Text("OK")) {   // Provides a default dismiss button labeled "OK."
                            // Dismiss the view when the alert is dismissed
                            print ("Dismissing change profile view")    // Debug statement to log the dismissal.
                            if self.password_changed_success{    // Checks if the password change was successful.
                                presentationMode.wrappedValue.dismiss() // Dismisses the current view if the password change succeeded.
                            }
                        }
                    )
                }
        }
    
    private func save_password ()   // Declares a private function named `save_password` for encapsulated functionality.
        {
        //if entered password is correct, save password
        if isValidPassword (new_password)   // Checks if the new password meets validation criteria (e.g., length, characters).
            {
            if (passwordsMatch ())  // Checks if the new password and confirmation password match.
                {
                update_password (currentPassword: entered_password, newPassword: new_password)
                // Calls a function to update the password, passing the current password and the new password as arguments.
                }
            }
        }
    
    func update_password (currentPassword: String, newPassword: String) {
        // Calls FirebaseManager to reauthenticate the user using their current password.
        FirebaseManager.shared.reauthenticateUser(currentPassword: currentPassword) { success in
            if success {
                // If reauthentication is successful, attempts to change the password to the new one.
                FirebaseManager.shared.changePassword(newPassword: newPassword) { success in
                    if success {
                        // If the password change is successful:
                        self.password_changed_success = true    // Sets a flag to indicate success.
                        showAlert = true         // Triggers the display of an alert.
                        alertTitle = "Success"      // Sets the alert title to "Success".
                        alertMessage = "Password updated successfully!" // Sets the success message for the alert.
                        print(alertMessage)     // Logs the success message to the console.
                    } else {
                        // If the password change fails:
                        showAlert = true             // Triggers the display of an alert.
                        alertTitle = "Error"        // Sets the alert title to "Error".
                        alertMessage = "Failed to update password."  // Sets the error message for the alert.
                        print(alertMessage)     // Logs the error message to the console.
                    }
                }
            } else {
                // If reauthentication fails:
                showAlert = true         // Triggers the display of an alert.
                alertMessage = "Incorrect password entered. Try again"      // Sets the error message for the alert.
                print(alertMessage)     // Logs the error message to the console.
            }
        }
    }
    
    
    private func passwordsMatch() -> Bool
        {
        // Checks if the new password matches the confirmed new password.
        if !(new_password == confirm_new_password)
            {
            return false        // Returns false if the passwords do not match.
            }
            
        return true     // Returns true if the passwords match.
        }
    
    private func validatePassword(_ newValue: String)
        {
        // Checks if the password length is at least 8 characters.
        isLengthValid = newValue.count >= 8
        // Checks if the password contains at least one uppercase letter using a regular expression.
        hasUppercase = newValue.range(of: "[A-Z]", options: .regularExpression) != nil
        // Checks if the password contains at least one special character using a regular expression.
        hasSpecialCharacter = newValue.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        }
    
    private func isValidPassword(_ password: String) -> Bool
        {
        // Check if the password meets the length requirement (at least 8 characters).
        isLengthValid = password.count >= 8
        // Check if the password contains at least one uppercase letter using a regular expression.
        hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        // Check if the password contains at least one special character using a regular expression.
        hasSpecialCharacter = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            // Return true if all conditions are met; otherwise, return false.
        return isLengthValid && hasUppercase && hasSpecialCharacter
        }
    
    }
