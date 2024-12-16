//
//  EditViewModel.swift
//  ExploreNow
//
//  Created by Alisha Lalani on 2024-12-13.
//

import Firebase
import SwiftUI

class EditViewModel: ObservableObject {
    @Published var username_available: Bool   = true // Availability of username
    @Published var username_edited   : Bool   = false // Whether the username was edited
    @Published var fieldName         : String = ""
    
    @EnvironmentObject var userManager: UserManager // Injected from the environment
    
    func set_fieldName (fieldName: String)
        {
        self.fieldName = fieldName
        }
 
    func isUsernameAvailable (fieldValue: String) -> Bool
        {
        var username_available = false
        // Check if the current user's username exists
        if let username = userManager.currentUser?.username
            {
            // If the field being edited is "Username" and the new value is different from the current username
            if fieldName == "Username" && !(username == fieldValue)
                {
                // Mark the username as edited
                self.username_edited = true
                // Get a reference to the Firestore database
                let db = Firestore.firestore()
                // Query Firestore for a user with the same username
                db.collection("users").whereField("username", isEqualTo: fieldValue).getDocuments
                { querySnapshot, error in
                    // Handle any errors that occur during the query
                    if let error = error
                    {
                        print("Error checking username: \(error)")
                        username_available = false  // Set to false if there is an error
                        return
                    }
                    
                    // Check if the query returned any results, if empty, the username is available
                    username_available = querySnapshot?.isEmpty ?? true // True if empty (available), false if taken
                    print("Username availability updated: \(self.username_available)")
                }
                }
            // If the field is "Username" and the current value is the same as the new value, mark it as not edited
            else if fieldName == "Username" && (username == fieldValue){
                self.username_edited = false
                }
            }
            
            // Return the current state of username_edited
            return username_available
        }
    
}
