//
//  AppState.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-10-17.
//

import SwiftUI
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    init() {
        // Check if the user is already authenticated
        self.isLoggedIn = Auth.auth().currentUser != nil
    }
}
