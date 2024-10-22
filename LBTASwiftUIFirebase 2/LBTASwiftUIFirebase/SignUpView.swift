//
//  SignUpView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-15.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct SignUpView: View
{
    @Environment(\.presentationMode) var presentationMode
    
    // Example text field state
    @State private var name             = ""
    @State private var email            = ""
    @State private var password         = ""
    @State private var confirm_password = ""
    @State private var isPasswordVisible = false //State for toggling password visibility
    @State private var isConfirmPasswordVisible = false //State for toggling password
    @State var loginStatusMessage = ""
    // State variables for password validation
    @State private var isLengthValid: Bool = false
    @State private var hasUppercase: Bool = false
    @State private var hasSpecialCharacter: Bool = false
//    @State private var navigateToHome = false
//    @State private var navigateToLogin = false
    @State private var username_available = false
    @State private var username = ""
    @State private var navigateToSuggestProfilePic = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager

//    let didCompleteSignUp: () -> Void
    
    // Popular email domains
    let validDomains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "live.com"]
    
    var body: some View
    {
        NavigationStack {
            VStack
            {
                Text("Sign Up")
                    .font(.custom("Sansation-Regular", size: 48)) // Use Sansation font
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                
                    .frame(maxWidth: .infinity) // Make it stretch to fill available width
                    .multilineTextAlignment(.center) // Center the text alignment
                
                // Add more UI elements here, e.g., text fields, buttons, etc.
                // Smaller text underneath
                Text("Create an Account")
                    .font(.custom("Sansation-Regular", size: 20)) // Use Sansation font
                    .foregroundColor(.black) // Set the text color to black
                    .padding(.top, 0)
                    .offset(y: 15) // Adjust with a negative offset to fine-tune the space
                    .frame(maxWidth: .infinity) // Make it stretch to fill available width
                    .multilineTextAlignment(.center) // Center the text alignment
                
                Text(self.loginStatusMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
                
                // Rounded TextField
                TextField("Name", text: $name) // Example text field
                    .padding(12) // Padding inside the text field
                    .background(Color.white) // Background color
                    .cornerRadius(15) // Rounded corners
                    .overlay(
                        RoundedRectangle(cornerRadius: 15) // Rounded border
                            .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                    )
                    .frame(width: 335) // Set a fixed width for the TextField
                    .padding(.top, 25) // Space above the text field
                
                // Rounded TextField
                TextField("Username", text: $username) // Example text field
                    .padding(12) // Padding inside the text field
                    .background(Color.white) // Background color
                    .cornerRadius(15) // Rounded corners
                    .overlay(
                        RoundedRectangle(cornerRadius: 15) // Rounded border
                            .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                    )
                    .autocapitalization(.none) // Prevent first letter from being capitalized
                    .frame(width: 335) // Set a fixed width for the TextField
                    .padding(.top, 20) // Space above the text field
                    .onChange(of: username) {
                        isUsernameAvailable ()
                    }
                
                if username.count > 0
                {
                    HStack
                    {
                        Text(username_available ? "✅" : "❌")
                            .foregroundColor(username_available ? .green : .red)
                        Text(username_available ? "Username is available" : "Username is taken")
                            .foregroundColor(.black)
                            .frame(width: 250, alignment: .leading) // Fixed width for text
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // Center the entire VStack
                    .padding(.top, 5)
                }
                
                // Rounded TextField
                TextField("Email Address", text: $email) // Example text field
                    .padding(12) // Padding inside the text field
                    .background(Color.white) // Background color
                    .cornerRadius(15) // Rounded corners
                    .overlay(
                        RoundedRectangle(cornerRadius: 15) // Rounded border
                            .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                    )
                    .frame(width: 335) // Set a fixed width for the TextField
                    .padding(.top, 20) // Space above the text field
                    .autocapitalization(.none) // Prevent first letter from being capitalized
                
                
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
                            .onChange(of: password) { newValue in
                                validatePassword(newValue)
                            }
                    } else {
                        SecureField("Password", text: $password) // Use SecureField for hidden password
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .onChange(of: password) { newValue in
                                validatePassword(newValue)
                            }
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
                
                
                VStack {
                    HStack {
                        Text(isLengthValid ? "✅" : "❌")
                            .foregroundColor(isLengthValid ? .green : .red)
                        Text("Must be 8 characters long")
                            .foregroundColor(.black)
                            .frame(width: 250, alignment: .leading) // Fixed width for text
                    }
                    .padding(.top, 10)
                    
                    HStack {
                        Text(hasUppercase ? "✅" : "❌")
                            .foregroundColor(hasUppercase ? .green : .red)
                        Text("Must have 1 uppercase letter")
                            .foregroundColor(.black)
                            .frame(width: 250, alignment: .leading) // Fixed width for text
                    }
                    .padding(.top, 5)
                    
                    HStack {
                        Text(hasSpecialCharacter ? "✅" : "❌")
                            .foregroundColor(hasSpecialCharacter ? .green : .red)
                        Text("Must have 1 special character")
                            .foregroundColor(.black)
                            .frame(width: 250, alignment: .leading) // Fixed width for text
                    }
                    .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, alignment: .center) // Center the entire VStack
                
                ZStack(alignment: .trailing) {
                    if isConfirmPasswordVisible {
                        TextField("Confirm Password", text: $confirm_password)
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
                            .onChange(of: confirm_password) {
                                passwordsMatch()
                            }
                    } else {
                        SecureField("Confirm Password", text: $confirm_password) // Use SecureField for hidden password
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .onChange(of: confirm_password) {
                                passwordsMatch()
                            }
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                    }
                    
                    // Toggle Button
                    Button(action: {
                        isConfirmPasswordVisible.toggle() // Toggle password visibility
                    }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye" : "eye.slash") // Change icon based on visibility
                            .foregroundColor(.gray)
                            .padding(.trailing, 12) // Add some spacing to the right of the button
                            .padding(.top, 20) // Space above the text field
                    }
                }
                
                if confirm_password.count > 0
                {
                    HStack
                    {
                        Text(passwordsMatch() ? "✅" : "❌")
                            .foregroundColor(passwordsMatch() ? .green : .red)
                        Text(passwordsMatch() ? "Passwords Match" : "Passwords do not match")
                            .foregroundColor(.black)
                            .frame(width: 250, alignment: .leading) // Fixed width for text
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // Center the entire VStack
                    .padding(.top, 10)
                }
                
                
                // Sign Up Button
                Button(action:
                        {
                    // Action for sign up
                    print("Sign Up tapped")
                    createNewAccount ()
                })
                {
                    Text("Sign Up")
                        .font(.custom("Sansation-Regular", size: 23))
                        .foregroundColor(.white) // Set text color to black
                        .padding()
                        .frame(width: 350) // Same width as TextField
                        .background(Color(red: 140/255, green: 82/255, blue: 255/255)) // Button color
                        .cornerRadius(15) // Rounded corners
                }
                
                .padding(.top, 15) // Space above the button
                // This NavigationLink is always present in the view hierarchy
                
                
                // "Already have an account? Login" text
                HStack {
                    Text("Already have an account? ")
                        .foregroundColor(.black) // Text color
                    
                    // Login text with underline
                    Text("Login")
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to match the theme
                        .underline() // Underline the text
                        .onTapGesture {
                            // Action for login navigation
                            print("Login tapped")
                            // Navigate to login view (you would implement this based on your navigation logic)
//                            navigateToLogin = true
//                            presentationMode.wrappedValue.dismiss()
                            presentationMode.wrappedValue.dismiss()

                        }
                }
                .padding(.top, 10) // Space above this text
                
                
                Spacer() // Pushes content to the top
                .fullScreenCover(isPresented: $navigateToSuggestProfilePic) {
                    SuggestProfilePicView()
                            .environmentObject(appState)
                            .environmentObject(userManager)
                  }
                
            }
        }
}
        
           
    private func isUsernameAvailable()
        {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("username", isEqualTo: username).getDocuments
                { querySnapshot, error in
                if let error = error
                    {
                    print("Error checking username: \(error)")
                    self.username_available = false // Set to false on error
                    return
                    }
                
                // Update the variable based on query result
                self.username_available = querySnapshot?.isEmpty ?? true // True if empty (available), false if taken
                print("Username availability updated: \(self.username_available)")
                }
        }
        
    
        private func isValidEmailDomain(_ email: String) -> Bool
            {
            // Check if the email contains "@" and get the domain part
            guard let domain = email.split(separator: "@").last else { return false }
            return validDomains.contains(String(domain))
            }

        private func isValidPassword(_ password: String) -> Bool
            {
            // Check for at least 6 characters, at least one number, and at least one special character
            isLengthValid = password.count >= 8
            hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
            hasSpecialCharacter = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            return isLengthValid && hasUppercase && hasSpecialCharacter
            }
            
        private func validatePassword(_ newValue: String)
            {
            isLengthValid = newValue.count >= 8
            hasUppercase = newValue.range(of: "[A-Z]", options: .regularExpression) != nil
            hasSpecialCharacter = newValue.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            }
        
        private func passwordsMatch() -> Bool
            {
            if !(password == confirm_password)
                {
                return false
                }
                
            return true
            }
        

            private func createNewAccount() {
                
                if !isValidEmailDomain(email) {
                    loginStatusMessage = "Please enter a valid email from popular domains."
                    return
                }
                
                if !isValidPassword(password)
                    {
                    loginStatusMessage = "Invalid password."
                    return
                    }

                
                if !passwordsMatch()
                    {
                    loginStatusMessage = "Password and confirm password do not match."
                    return
                    }
                
                if !username_available{
                    loginStatusMessage = "Username is not available"
                    return
                }
                
                FirebaseManager.shared.auth.createUser(withEmail: email, password: password)
                    { result, err in
                    if let err = err
                        {
                        print("Failed to create user: ", err)
                        self.loginStatusMessage = "Failed to create user: \(err.localizedDescription)"
                        return
                        }
                    guard let uid = result?.user.uid else { return }
                    print("Successfully created user: \(result?.user.uid ?? "")")
                    //self.loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
                        
                    // Create a reference to the Firestore database
                    let db = Firestore.firestore()

                    // Store additional user data
                    let userData: [String: Any] =
                        [
                        "username": username,
                        "email": email,
                        "name": name
                        ]
                        // Save user data under the user's UID
                        db.collection("users").document(uid).setData(userData)
                        { error in
                        if let error = error
                            {
                            print("Failed to add user data to Firestore: \(error)")
                            self.loginStatusMessage = "Failed to save user data: \(error.localizedDescription)"
                            }
                        else
                            {
                            print("Successfully saved user data to Firestore")
                            // Navigation link to the HomeView, activated by the state variable
                            // Initialize UserManager after successful signup
                            DispatchQueue.main.async
                                {
                                // Now you can use userManager in your views or pass it to the environment
                                userManager.fetchCurrentUser()
                                // Navigate to the next view if needed
                                navigateToSuggestProfilePic = true
                                }
                            }
                        }
                        
                    }
            }
    
        
        }
    


// Preview for SignUpView
//struct SignUpView_Previews: PreviewProvider
//    {
//    static var previews: some View
//        {
//        SignUpView()
//        }
//    }
