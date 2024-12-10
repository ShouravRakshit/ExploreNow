//
//  AppState.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    init() {
        // Check if the user is already authenticated
        self.isLoggedIn = Auth.auth().currentUser != nil
    }
}
