//
//  UserSettingsManager.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-11-17.
//

import FirebaseFirestore

class UserSettingsManager {
    let db = Firestore.firestore()
    var publicAccount: Bool = false // Local variable for the 'public' field
    
    /// Retrieves the `public` field for a user. If it doesn't exist, sets `publicAccount` to `false`.
    func fetchUserSettings(userId: String, completion: @escaping (Bool) -> Void) {
        let settingsRef = db.collection("settings").document(userId)
        
        settingsRef.getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                self.publicAccount = false
                completion(false)
                return
            }
            
            if let document = document, document.exists {
                if let publicField = document.get("public") as? Bool {
                    self.publicAccount = publicField
                    completion(publicField)
                } else {
                    print("Field 'public' not found, setting to false.")
                    self.publicAccount = false
                    completion(false)
                }
            } else {
                print("Document does not exist, setting default value.")
                self.publicAccount = false
                completion(false)
            }
        }
    }
}
