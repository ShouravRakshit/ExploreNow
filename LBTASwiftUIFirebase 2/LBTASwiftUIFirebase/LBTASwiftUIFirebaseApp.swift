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
