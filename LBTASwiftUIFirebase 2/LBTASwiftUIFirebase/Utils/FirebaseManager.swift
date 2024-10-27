//
//  FirebaseManager.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 07/10/2024.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    static let shared = FirebaseManager()
    
    override init() {
        //FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
    
    func reauthenticateUser(currentPassword: String, completion: @escaping (Bool) -> Void) {
        guard let user = auth.currentUser else {
            completion(false)
            return
        }
        
        // Reauthenticate with email and password
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
        
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                print("Reauthentication failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func changePassword(newPassword: String, completion: @escaping (Bool) -> Void) {
        guard let user = auth.currentUser else {
            completion(false)
            return
        }
        
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                print("Password update failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
}
