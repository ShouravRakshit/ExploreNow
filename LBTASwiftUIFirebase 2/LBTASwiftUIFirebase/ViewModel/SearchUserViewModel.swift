//
//  SearchUserViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class SearchUserViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var users: [ChatUser] = []
    @Published var filteredUsers: [ChatUser] = []
    
    init() {
        loadUsers()
    }
    
    func loadUsers() {
        let db = FirebaseManager.shared.firestore
        
        db.collection("users").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let fetchedUsers = documents.compactMap { doc -> ChatUser? in
                let data = doc.data()
                return ChatUser(data: data)
            }
            
            DispatchQueue.main.async {
                self?.users = fetchedUsers
                self?.filteredUsers = fetchedUsers
            }
        }
    }
    
    func filterUsers(query: String) {
        if query.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                user.email.lowercased().contains(query.lowercased()) ||
                user.name.lowercased().contains(query.lowercased())
            }
        }
    }
}
