//
//  MainMessagesViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

class MainMessagesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    @Published var filteredMessages = [RecentMessage]() // For search results
    @Published var searchQuery = "" // Search query for filtering messages
    
    init() {
        fetchRecentMessages()
    }
    
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: FirebaseConstants.timestamp, descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    self?.errorMessage = "Failed to fetch recent messages: \(error)"
                    print(error)
                    return
                }
                
                self?.recentMessages = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    return RecentMessage(documentId: document.documentID, data: data)
                } ?? []
                
                DispatchQueue.main.async {
                    self?.filteredMessages = self?.recentMessages ?? []
                }
                
                self?.updateRecentMessagesWithUserData()
            }
    }
    
    func filterMessages(query: String) {
        if query.isEmpty {
            filteredMessages = recentMessages // Reset to show all messages
        } else {
            filteredMessages = recentMessages.filter { recentMessage in
                recentMessage.name?.lowercased().contains(query.lowercased()) ?? false
            }
        }
    }
    
    func updateRecentMessagesWithUserData() {
        for (index, recentMessage) in recentMessages.enumerated() {
            let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
            
            fetchUserData(uid: uid) { [weak self] user in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.recentMessages[index].name = user.name
                    self.recentMessages[index].profileImageUrl = user.profileImageUrl
                    self.filterMessages(query: self.searchQuery)
                }
            }
        }
    }
    
    func fetchUserData(uid: String, completion: @escaping (ChatUser) -> Void) {
        let userRef = FirebaseManager.shared.firestore.collection("users").document(uid)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user data: \(error)")
                completion(ChatUser(data: [:]))
                return
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                let user = ChatUser(data: data)
                completion(user)
            } else {
                print("User document does not exist")
                completion(ChatUser(data: [:]))
            }
        }
    }
    
    func handleSignOut() {
        print("Signing out user in handleSignOut")
        do {
            try FirebaseManager.shared.auth.signOut()
            isUserCurrentlyLoggedOut = true
        } catch {
            print("Failed to sign out:", error)
        }
    }
    
    func deleteUserAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
            return
        }
        
        FirebaseManager.shared.auth.currentUser?.delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            FirebaseManager.shared.firestore.collection("users").document(uid).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    func changePassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        FirebaseManager.shared.auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
