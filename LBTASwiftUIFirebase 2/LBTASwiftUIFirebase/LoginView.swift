//
//  ContentView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 06/10/2024.


import SwiftUI
import Firebase
import FirebaseAuth


extension Color {
    static let customPurple = Color(red: 140/255, green: 82/255, blue: 255/255, opacity: 0.81)
}

struct LoginView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false // State for toggling password visibility
    @State var loginStatusMessage = ""
    @State private var showSignUpView = false

    // Popular email domains
    let validDomains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "live.com"]
    
    var body: some View {
        NavigationView {
            VStack {
                VStack      {
                    Spacer()
                        .frame(height: 1)
                    
                    Image("Explore")
//                        .frame(width:50, height: 50)
//                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.60) // Adjusted to 60% of screen width
                    Spacer()
                }
                .frame(height: UIScreen.main.bounds.height * 0.38) // Increased to 40% of screen height
                .frame(maxWidth: .infinity)
                .background(Color.white)
                ScrollView {
                    VStack{
                        Group {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(12)
                                .background(Color.white)
                                .frame(width: 350)
                                .frame(height: 50)
                                .cornerRadius(20)
                                .onChange(of: email) { newValue in
                                    if !isValidEmailDomain(newValue) {
                                        loginStatusMessage = "Please enter a valid email from popular domains."
                                    } else {
                                        loginStatusMessage = ""
                                    }
                                }.padding(.bottom, 25)
                                .padding(.top, 35)
                            
                            
                            ZStack(alignment: .trailing) {
                                if isPasswordVisible {
                                    TextField("Password", text: $password) // Use TextField for visible password
                                        .padding(12)
                                        .background(Color.white)
                                        .frame(width: 350)
                                        .frame(height: 50)
                                        .cornerRadius(20)
                                } else {
                                    SecureField("Password", text: $password) // Use SecureField for hidden password
                                        .padding(12)
                                        .frame(width: 350)
                                        .frame(height: 50)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                }
                                
                                // Toggle Button
                                Button(action: {
                                    isPasswordVisible.toggle() // Toggle password visibility
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye") // Change icon based on visibility
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12) // Add some spacing to the right of the button
                                }
                            }.padding(.bottom, 35)
                        }
                        
                        Button {
                            handleAction()
                        } label:
                        {
                            HStack {
                                
                                Text("Login")
                                    .foregroundColor(.black) // Black text to match the design
                                    .font(.system(size: 16, weight: .bold)) // Keep a bold font
                                    .padding(.vertical, 18) // Adjust vertical padding for button height
                                    .frame(width: 130) // Set a fixed width for a square-like button
                                    .background(Color.white) // White background to match the design
                                    .cornerRadius(16) // Adjust corner radius for square-like shape
                                    .shadow(color: .gray, radius: 5, x: 0, y: 2) // Optional shadow fo
                                
                            }.frame(maxWidth: .infinity) // Center the button within its container
                                .padding(.horizontal, 20) // Padding around the button for screen edges
                            
                        }
                        
                        if !isLoginMode
                        {
                            HStack
                            {
                                Text("Don't have an account? ")
                                    .foregroundColor(.black)
                                
                                Text("Sign up")
                                    .underline() // Underline the text
                                    .foregroundColor(.black) // Change color to indicate it's a link
                                    .onTapGesture {
                                        showSignUpView = true // Set the variable to true when tapped
                                    }
                                
                            }
                            .padding(.top, 50)
                            
                        }
                        
                        Text(self.loginStatusMessage)
                            .foregroundColor(.red)
                    }
                    .padding()
                    
                    
                }
                
                .background(Color.customPurple)
                .navigationViewStyle(StackNavigationViewStyle())
                
                .fullScreenCover(isPresented: $showSignUpView){
                    SignUpView()
                            .environmentObject(appState) // Pass appState to Sign Up link
                        
                    }
                
            }
        }
    }
    
    
    private func isValidEmailDomain(_ email: String) -> Bool {
        // Check if the email contains "@" and get the domain part
        guard let domain = email.split(separator: "@").last else { return false }
        return validDomains.contains(String(domain))
    }
    
    private func handleAction() {
            loginUser()
    }
    
    private func loginUser() {
        if !isValidEmailDomain(email) {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }
        
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login user: ", err)
                self.loginStatusMessage = "Failed to login user: \(err.localizedDescription)"
                return
            }
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            // Updating authentication state
                    DispatchQueue.main.async {
                        self.appState.isLoggedIn = true
                    }
        }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Check for at least 6 characters, at least one number, and at least one special character
        let passwordRegex = "^(?=.*[0-9])(?=.*[!@#$%^&*()_+{}|:<>?~`\\[\\];'\",.\\/])(?=.{6,}).*"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordTest.evaluate(with: password)
    }
    
    private func resetPassword() {
        // Check if the email is valid before querying Firestore
        if !isValidEmailDomain(email) {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }

        // Check if the email exists in Firestore
        let db = FirebaseManager.shared.firestore
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                self.loginStatusMessage = "An error occurred while checking for user: \(error.localizedDescription)"
                return
            }

            // Check if there are any documents with the email
            if let documents = querySnapshot?.documents, documents.isEmpty {
                self.loginStatusMessage = "No user found with this email."
            } else {
                // Email exists, proceed to send password reset email
                FirebaseManager.shared.auth.sendPasswordReset(withEmail: email) { error in
                    if let error = error {
                        print("Failed to send password reset email: ", error)
                        self.loginStatusMessage = "Failed to send password reset email: \(error.localizedDescription)"
                        return
                    }
                    self.loginStatusMessage = "Password reset email sent. Please check your inbox."
                }
            }
        }
    }
}
