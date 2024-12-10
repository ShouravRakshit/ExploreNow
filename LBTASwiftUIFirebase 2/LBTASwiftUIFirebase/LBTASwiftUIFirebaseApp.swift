//
//  LBTASwiftUIFirebaseApp.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 


import SwiftUI
import FirebaseCore

@main
struct LBTASwiftUIFirebaseApp: App {
    
    @StateObject var appState = AppState() // Initialize AppState
    @StateObject private var userManager = UserManager()
    
    init() {
        FirebaseApp.configure() // Configuring Firebase here
        UITabBar.appearance().backgroundColor = UIColor(hex: "#8C52FF")
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject (appState) // Makes appState available to all child views.
                .environmentObject (userManager)
        }
    }
    
    
}
