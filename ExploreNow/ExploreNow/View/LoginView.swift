//
//  LoginView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI

extension Color {
    static let customPurple = Color(red: 140/255, green: 82/255, blue: 255/255, opacity: 0.81)
}

// LoginView
// LoginView - A view for user login with email and password
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()  // ViewModel to handle login logic
    @EnvironmentObject var appState: AppState             // App state to manage app-wide settings
    @EnvironmentObject var userManager: UserManager       // User manager to handle user data
    @State private var showSignUpView = false             // State to toggle sign-up view visibility
    
    var body: some View {
        VStack {
            // Image and Spacer - Displays branding image and adds flexible space
            VStack {
                Spacer().frame(height: 1)  // Small space to separate image from top
                Image("Explore")
                    .scaledToFit()  // Ensures the image scales properly to fit the screen width
                    .frame(width: UIScreen.main.bounds.width * 0.60) // Sets width to 60% of screen width
                Spacer()
            }
            .frame(height: UIScreen.main.bounds.height * 0.38) // Takes up 38% of the screen height
            .frame(maxWidth: .infinity) // Ensures it stretches across the screen width
            .background(Color.white) // Background color for the top section
            
            // Scrollable content - Allows the login form to be scrollable
            ScrollView {
                VStack {
                    // Email TextField with validation for email format
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)  // Specifies email keyboard
                        .autocapitalization(.none)    // Disables autocapitalization for email input
                        .padding(12)  // Padding for comfortable touch interaction
                        .background(Color.white)  // Background color for input field
                        .frame(width: 350, height: 50)  // Fixed width and height for consistency
                        .cornerRadius(20)  // Rounded corners for the text field
                        .onChange(of: viewModel.email) { _ in
                            // Validates email domain and shows a message if invalid
                            if !viewModel.isValidEmailDomain(viewModel.email) {
                                viewModel.loginStatusMessage = "Please enter a valid email from popular domains."
                            } else {
                                viewModel.loginStatusMessage = ""  // Clears the message if valid
                            }
                        }
                        .padding(.bottom, 25)  // Adds space between fields
                        .padding(.top, 35)     // Adds space from the top
                    
                    // Password TextField with visibility toggle functionality
                    ZStack(alignment: .trailing) {
                        if viewModel.isPasswordVisible {
                            // Password is visible as plain text
                            TextField("Password", text: $viewModel.password)
                                .padding(12)
                                .background(Color.white)
                                .frame(width: 350, height: 50)
                                .cornerRadius(20)
                        } else {
                            // Password is hidden with SecureField
                            SecureField("Password", text: $viewModel.password)
                                .padding(12)
                                .background(Color.white)
                                .frame(width: 350, height: 50)
                                .cornerRadius(20)
                        }
                        // Button to toggle password visibility
                        Button(action: {
                            viewModel.togglePasswordVisibility()  // Calls a method to toggle visibility
                        }) {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")  // Eye icon
                                .foregroundColor(.gray)  // Sets the icon color to gray
                                .padding(.trailing, 12)   // Padding to avoid overlap with text
                        }
                    }
                    .padding(.bottom, 35)  // Adds space below the password field
                    
                    
                    // Login Button
                    Button(action: {
                        // Handles the login action, passing appState and userManager for login logic
                        viewModel.handleLogin(appState: appState, userManager: userManager)
                    }) {
                        HStack {
                            // Label for the login button
                            Text("Login")
                                .foregroundColor(.black) // Sets the text color to black
                                .font(.system(size: 16, weight: .bold)) // Defines the font size and weight
                                .padding(.vertical, 18) // Adds vertical padding inside the button
                                .frame(width: 130) // Sets a fixed width for the button
                                .background(Color.white) // Sets the button's background color to white
                                .cornerRadius(16) // Rounds the corners of the button
                                .shadow(color: .gray, radius: 5, x: 0, y: 2) // Adds shadow effect to the button
                        }
                        .frame(maxWidth: .infinity) // Makes the button's width stretch to fill available space horizontally
                        .padding(.horizontal, 20) // Adds horizontal padding around the button
                    }
                    
                    // Sign up navigation
                    HStack {
                        // Text to prompt the user to sign up if they don't have an account
                        Text("Don't have an account? ")
                            .foregroundColor(.black) // Sets the color to black for the text
                        
                        // Link to navigate to the sign-up page
                        Text("Sign up")
                            .underline() // Underlines the "Sign up" text to indicate it's clickable
                            .foregroundColor(.black) // Sets the color to black for the text
                            .onTapGesture {
                                // When "Sign up" is tapped, set showSignUpView to true to show the SignUpView
                                showSignUpView = true
                            }
                    }
                    .padding(.top, 50) // Adds padding above the sign-up prompt
                    
                    // Display the login status message (e.g., error messages or status updates)
                    Text(viewModel.loginStatusMessage)
                        .foregroundColor(.red) // Sets the text color to red for error messages or notifications
                    
                }
                .padding()
            }
            .background(Color.customPurple) // Sets the background color to a custom purple color defined in the Color extension
            
            // Full screen cover to present the SignUpView when showSignUpView is true
            .fullScreenCover(isPresented: $showSignUpView) {
                // Presents the SignUpView when the condition is met
                SignUpView()
                    .environmentObject(appState) // Passes the appState to the SignUpView for state management
                    .environmentObject(userManager) // Passes the userManager to the SignUpView to manage user-related operations
            }
            
        }
    }
}
