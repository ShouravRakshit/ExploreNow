//
//  LBTASwiftUIFirebaseApp.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 06/10/2024.
//

import SwiftUI
import FirebaseCore

@main
struct LBTASwiftUIFirebaseApp: App {
    @State private var currentView: CurrentView = .loginView
    @State private var username: String = ""
    
    enum CurrentView {
        case signUp
        case suggestProfilePic
        case mainMessages
        case loginView
    }
    
    // Initialize Firebase in the app's init method
    init() {
        FirebaseApp.configure() // Configure Firebase here
    }
    
    var body: some Scene {
        WindowGroup {
            if currentView == .loginView{
                LoginView(currentView: $currentView)()
            }
            if currentView == .signUp {
                SignUpView(currentView: $currentView, username: $username) // Pass as a binding
            } else if currentView == .suggestProfilePic {
                SuggestProfilePicView(currentView: $currentView, username: username) // Pass the username directly
            } else {
                MainMessagesView() // This will have its own navigation
            }
        }
    }
}
