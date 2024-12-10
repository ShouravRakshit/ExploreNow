//
//  UserSettingsManager.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import FirebaseFirestore

class UserSettingsManager {
    let db = Firestore.firestore()
    var publicAccount: Bool = false // Local variable for the 'public' field
    
    /// Retrieves the `public` field for a user. If it doesn't exist, sets `publicAccount` to `false`.
    func fetchUserSettings(userId: String, completion: @escaping (Bool) -> Void) {
        let settingsRef = db.collection("settings").document(userId)
        
        settingsRef.getDocument { document, error in
            // Handle errors from Firestore
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)") // Consider logging for better error tracking
                self.publicAccount = false // Default to `false` if there's an error
                completion(false) // Return `false` to indicate failure
                return
            }
            
            // Process the document if it exists
            if let document = document, document.exists {
                // Check for the 'public' field in the document
                if let publicField = document.get("public") as? Bool {
                    self.publicAccount = publicField // Update the local variable
                    completion(publicField) // Pass the value to the completion handler
                } else {
                    print("Field 'public' not found, setting to false.") // Inform about the missing field
                    self.publicAccount = false // Default to `false` if the field is missing
                    completion(false)  // Return `false`
                }
            } else {
                // Handle the case where the document doesn't exist
                print("Document does not exist, setting default value.") // Inform about the missing document
                self.publicAccount = false // Default to `false`
                completion(false) // Return `false`
            }
        }
    }
}
