//
//  LoginViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, --------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import Firebase

// ViewModel responsible for managing login logic
class LoginViewModel: ObservableObject {
    
    // Published properties that are bound to the UI
    @Published var email: String = "" // User's email input
    @Published var password: String = "" // User's password input
    @Published var loginStatusMessage: String = "" // Message displayed for login status
    @Published var isLoggedIn: Bool = false // Flag to indicate if the user is logged in
    @Published var isPasswordVisible: Bool = false // Flag to control visibility of the password input
    
    // List of valid email domains for login validation
    let validDomains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "live.com"]

    // Function to validate if the provided email belongs to a valid domain
    func isValidEmailDomain(_ email: String) -> Bool {
        // Split the email by '@' and check if the domain is in the list of valid domains
        guard let domain = email.split(separator: "@").last else { return false }
        return validDomains.contains(String(domain)) // Return true if domain matches, else false
    }

    // Function to handle the login process
    func loginUser(appState: AppState, userManager: UserManager) {
        // First, validate the email domain
        guard isValidEmailDomain(email) else {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }
        
        // Attempt to sign in the user using Firebase authentication
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            // Handle errors in login attempt
            if let err = err {
                print("Failed to login user: \(err)")
                DispatchQueue.main.async {
                    // Update login status message on main thread in case of failure
                    self.loginStatusMessage = "Failed to login user: \(err.localizedDescription)"
                }
                return
            }
            
            // Successfully logged in
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            DispatchQueue.main.async {
                // Update login status message on main thread
                self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
                // Update the app state and trigger user data fetching
                appState.isLoggedIn = true
                userManager.fetchCurrentUser()
            }
        }
    }


    func resetPassword() {
        // First, check if the email domain is valid using a helper function
        guard isValidEmailDomain(email) else {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }
        
        // Attempt to send a password reset email via Firebase Authentication
        FirebaseManager.shared.auth.sendPasswordReset(withEmail: email) { error in
            // If there was an error in sending the reset email, handle it
            if let error = error {
                print("Failed to send password reset email: \(error)")
                DispatchQueue.main.async {
                    // Update the status message to inform the user of the error
                    self.loginStatusMessage = "Failed to send password reset email: \(error.localizedDescription)"
                }
                return
            }
            
            // If the password reset email was sent successfully
            DispatchQueue.main.async {
                // Update the status message to inform the user
                self.loginStatusMessage = "Password reset email sent. Please check your inbox."
            }
        }
    }

    
    // Add handleLogin function here
    func handleLogin(appState: AppState, userManager: UserManager) {
        loginUser(appState: appState, userManager: userManager)
    }
    
    // Toggle the visibility of the password
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
}

