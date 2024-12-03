//
//  LoginViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import Foundation
import Firebase

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var loginStatusMessage: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var isPasswordVisible: Bool = false
    
    let validDomains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "live.com"]
    
    func isValidEmailDomain(_ email: String) -> Bool {
        guard let domain = email.split(separator: "@").last else { return false }
        return validDomains.contains(String(domain))
    }
    
    func loginUser(appState: AppState, userManager: UserManager) {
        guard isValidEmailDomain(email) else {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }
        
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login user: \(err)")
                DispatchQueue.main.async {
                    self.loginStatusMessage = "Failed to login user: \(err.localizedDescription)"
                }
                return
            }
            
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            DispatchQueue.main.async {
                self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
                appState.isLoggedIn = true
                userManager.fetchCurrentUser()
            }
        }
    }
    
    func resetPassword() {
        guard isValidEmailDomain(email) else {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }
        
        FirebaseManager.shared.auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Failed to send password reset email: \(error)")
                DispatchQueue.main.async {
                    self.loginStatusMessage = "Failed to send password reset email: \(error.localizedDescription)"
                }
                return
            }
            
            DispatchQueue.main.async {
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

