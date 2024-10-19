//
//  LBTASwiftUIFirebaseApp.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 06/10/2024.
//

//import SwiftUI
//import FirebaseCore
//import FirebaseAuth
//
//@main
//struct LBTASwiftUIFirebaseApp: App {
//    
//    // Initialize Firebase in the app's init method
//    init() {
//        FirebaseApp.configure() // Configure Firebase here
//       
//    }
//    
//    @Environment(\.scenePhase) private var scenePhase
//    
//    var body: some Scene {
//        WindowGroup {
//            MainMessagesView()
//                .onChange(of: scenePhase) { newPhase in
//                        switch newPhase {
//                        case .background:
//                            // Sign out the user when the app enters the background
//                            do {
//                                try Auth.auth().signOut()
//                                print("User signed out")
//                            } catch let signOutError as NSError {
//                                print("Error signing out: %@", signOutError.localizedDescription)
//                            }
//                        default:
//                            break
//                        }
//                    }
//        }
//    }
//}

import SwiftUI
import FirebaseCore

@main
struct LBTASwiftUIFirebaseApp: App {
    
    @StateObject var appState = AppState() // Initialize AppState
    
    init() {
        FirebaseApp.configure() // Configuring Firebase here
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // Makes appState available to all child views.
        }
    }
}
