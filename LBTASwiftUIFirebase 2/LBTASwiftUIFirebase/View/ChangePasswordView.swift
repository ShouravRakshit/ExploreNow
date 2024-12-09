//
//  ChangePasswordView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-22.
//

import SwiftUI
import Firebase


//------------------------------------------------------------------------------------
struct ChangePasswordView: View
    {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager
    
    @State var entered_password    : String = ""
    @State var new_password        : String = ""
    @State var confirm_new_password: String = ""

    //State for toggling password visibility
    @State private var isPasswordVisible           = false
    @State private var isNewPasswordVisible        = false
    @State private var isConfirmNewPasswordVisible = false
    
    @State private var showAlert   : Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle  : String = ""

    // State variables for new password validation
    @State private var isLengthValid      : Bool = false
    @State private var hasUppercase       : Bool = false
    @State private var hasSpecialCharacter: Bool = false
    
    @State private var password_changed_success : Bool = false
    
    
    var body: some View
        {
            VStack
                {
                HStack
                    {
                    Image(systemName: "chevron.left")
                        .resizable() // Make the image resizable
                        .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
                        .frame(width: 30, height: 30) // Set size
                        .padding()
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                        .onTapGesture
                            {
                            // Go back to profile page
                            presentationMode.wrappedValue.dismiss()
                            }
                    Spacer() // Pushes the text to the center
                    Text ("Change Password")
                        .font(.custom("Sansation-Regular", size: 30))
                        .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                        .offset(x:-30)
                    Spacer() // Pushes the text to the center
                    }
                    
                ZStack(alignment: .trailing) {
                    if isPasswordVisible {
                        TextField("Enter Current Password", text: $entered_password)
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
                    } else {
                        SecureField("Enter Current Password", text: $entered_password) // Use SecureField for hidden password
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
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
                    
                ZStack(alignment: .trailing) {
                    if isNewPasswordVisible {
                        TextField("Enter New Password", text: $new_password)
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
                            .onChange(of: new_password) { newValue in
                                validatePassword(newValue)
                            }
                    } else {
                        SecureField("Enter New Password", text: $new_password) // Use SecureField for hidden password
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15) // Rounded border
                                    .stroke(Color(red: 140/255, green: 82/255, blue: 255/255), lineWidth: 2) // Border color and width
                            )
                            .frame(width: 335) // Set a fixed width for the TextField
                            .padding(.top, 20) // Space above the text field
                            .autocapitalization(.none) // Prevent first letter from being capitalized
                            .onChange(of: new_password) { newValue in
                                validatePassword(newValue)
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
                    if isConfirmNewPasswordVisible {
                        TextField("Confirm New Password", text: $confirm_new_password)
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
                        
                    } else {
                        SecureField("Confirm New Password", text: $confirm_new_password) // Use SecureField for hidden password
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
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

                if confirm_new_password.count > 0
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
                    
                Button("Save") {
                        // Handle saving the value here
                        // You might want to pass this value back to the main view if needed
                        save_password ()
                        // Go back to profile settings page
                    }
                    .font(.custom("Sansation-Regular", size: 23))
                    .foregroundColor(.white) // Set text color to black
                    .padding()
                    .frame(width: 350) // Same width as TextField
                    .background(Color(red: 140/255, green: 82/255, blue: 255/255)) // Button color
                    .cornerRadius(15) // Rounded corners
                    .padding(.top, (confirm_new_password.count > 0) ? 10 : 30)
                    
                if entered_password.count > 0 && new_password.count > 0 && entered_password == new_password
                    {
                    Text ("Password and New Password Must be Different!")
                        .font(.custom("Sansation-Regular", size: 18))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding ()
                    }
                Spacer()
                }
                //Updates user on success or failure of changing password
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK")) {
                            // Dismiss the view when the alert is dismissed
                            print ("Dismissing change profile view")
                            if self.password_changed_success{
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    )
                }
        }
    
    private func save_password ()
        {
        //if entered password is correct, save password
        if isValidPassword (new_password)
            {
            if (passwordsMatch ())
                {
                update_password (currentPassword: entered_password, newPassword: new_password)
                }
            }
        }
    
    func update_password (currentPassword: String, newPassword: String) {
        FirebaseManager.shared.reauthenticateUser(currentPassword: currentPassword) { success in
            if success {
                FirebaseManager.shared.changePassword(newPassword: newPassword) { success in
                    if success {
                        self.password_changed_success = true
                        showAlert = true
                        alertTitle = "Success"
                        alertMessage = "Password updated successfully!"
                        print(alertMessage)
                    } else {
                        showAlert = true
                        alertTitle = "Error"
                        alertMessage = "Failed to update password."
                        print(alertMessage)
                    }
                }
            } else {
                showAlert = true
                alertMessage = "Incorrect password entered. Try again"
                print(alertMessage)
            }
        }
    }
    
    
    private func passwordsMatch() -> Bool
        {
        if !(new_password == confirm_new_password)
            {
            return false
            }
            
        return true
        }
    
    private func validatePassword(_ newValue: String)
        {
        isLengthValid = newValue.count >= 8
        hasUppercase = newValue.range(of: "[A-Z]", options: .regularExpression) != nil
        hasSpecialCharacter = newValue.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        }
    
    private func isValidPassword(_ password: String) -> Bool
        {
        // Check for at least 6 characters, at least one number, and at least one special character
        isLengthValid = password.count >= 8
        hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        hasSpecialCharacter = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        return isLengthValid && hasUppercase && hasSpecialCharacter
        }
    
    }
