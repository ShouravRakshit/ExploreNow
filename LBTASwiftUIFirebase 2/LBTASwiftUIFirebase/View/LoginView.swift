//
//  LoginView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import SwiftUI

extension Color {
    static let customPurple = Color(red: 140/255, green: 82/255, blue: 255/255, opacity: 0.81)
}

// LoginView
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @State private var showSignUpView = false
    
    var body: some View {
        VStack {
            // Image and Spacer
            VStack {
                Spacer().frame(height: 1)
                Image("Explore")
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * 0.60)
                Spacer()
            }
            .frame(height: UIScreen.main.bounds.height * 0.38)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            
            // Scrollable content
            ScrollView {
                VStack {
                    // Email TextField with validation
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(12)
                        .background(Color.white)
                        .frame(width: 350, height: 50)
                        .cornerRadius(20)
                        .onChange(of: viewModel.email) { _ in
                            if !viewModel.isValidEmailDomain(viewModel.email) {
                                viewModel.loginStatusMessage = "Please enter a valid email from popular domains."
                            } else {
                                viewModel.loginStatusMessage = ""
                            }
                        }
                        .padding(.bottom, 25)
                        .padding(.top, 35)
                    
                    // Password TextField with visibility toggle
                    ZStack(alignment: .trailing) {
                        if viewModel.isPasswordVisible {
                            TextField("Password", text: $viewModel.password)
                                .padding(12)
                                .background(Color.white)
                                .frame(width: 350, height: 50)
                                .cornerRadius(20)
                        } else {
                            SecureField("Password", text: $viewModel.password)
                                .padding(12)
                                .background(Color.white)
                                .frame(width: 350, height: 50)
                                .cornerRadius(20)
                        }
                        Button(action: {
                            viewModel.togglePasswordVisibility()
                        }) {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    }
                    .padding(.bottom, 35)

                    
                    // Login Button
                    Button(action: {
                        viewModel.handleLogin(appState: appState, userManager: userManager)
                    }) {
                        HStack {
                            Text("Login")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .bold))
                                .padding(.vertical, 18)
                                .frame(width: 130)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .gray, radius: 5, x: 0, y: 2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                    }

                    // Sign up navigation
                    HStack {
                        Text("Don't have an account? ")
                            .foregroundColor(.black)
                        
                        Text("Sign up")
                            .underline()
                            .foregroundColor(.black)
                            .onTapGesture {
                                showSignUpView = true
                            }
                    }
                    .padding(.top, 50)
                    
                    // Login status message
                    Text(viewModel.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .background(Color.customPurple) // Using custom purple color as background
            .fullScreenCover(isPresented: $showSignUpView) {
                SignUpView()
                    .environmentObject(appState)
                    .environmentObject(userManager)
            }
        }
    }
}
