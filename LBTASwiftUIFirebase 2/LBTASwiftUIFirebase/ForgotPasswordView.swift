//
//  ForgotPasswordView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 07/10/2024.
//
import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var loginStatusMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Forgot Password")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Enter your email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)

                Button(action: resetPassword) {
                    Text("Send Reset Link")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Text(loginStatusMessage)
                    .foregroundColor(.red)
                    .padding()
                
                NavigationLink("Back to Login", destination: LoginView(didCompleteLoginProcess: {
                    // Handle navigation back
                }))
                    .padding()
            }
            .padding()
            .navigationTitle("Forgot Password")
            .background(LinearGradient(gradient: Gradient(colors: [Color(.purple).opacity(0.5), Color(.purple).opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea())
        }
    }
    
    private func resetPassword() {
        // Check if the email is valid before sending a reset password email
        guard isValidEmail(email) else {
            loginStatusMessage = "Please enter a valid email address."
            return
        }
        
        FirebaseAuth.Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Failed to send password reset email: ", error)
                self.loginStatusMessage = "Failed to send password reset email: \(error.localizedDescription)"
                return
            }
            self.loginStatusMessage = "Password reset email sent. Please check your inbox."
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Simple regex for validating email
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
