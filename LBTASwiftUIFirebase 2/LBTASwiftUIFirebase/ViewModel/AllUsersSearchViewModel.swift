//
//  AllUsersSearchViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-19.
//

import Foundation

class AllUsersSearchViewModel: ObservableObject {
    @Published var users = [User]() // Use your User model
    @Published var filteredUsers = [User]()
    @Published var searchQuery = ""{
        didSet {
            filterUsers()
        }
    }
    @Published var blockedUsers: [String] = []
    @Published var blockedByUsers: [String] = []
    private var currentUserId: String?

    private var searchCache: [String: [User]] = [:] // Cache for search queries
    
    init() {
        currentUserId = FirebaseManager.shared.auth.currentUser?.uid
        fetchBlockedUsers {
            self.fetchBlockedByUsers {
                self.fetchAllUsers()
            }
        }
    }
    
    func fetchBlockedByUsers(completion: @escaping () -> Void) {
        guard let currentUserId = currentUserId else {
            completion()
            return
        }

        // Fetch the 'blockedByIds' array from the current user's 'blocks' document
        let currentUserBlocksRef = FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
        currentUserBlocksRef.getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching blockedBy users: \(error)")
                self.blockedByUsers = []
                completion()
            } else if let data = documentSnapshot?.data() {
                self.blockedByUsers = data["blockedByIds"] as? [String] ?? []
                completion()
            } else {
                self.blockedByUsers = []
                completion()
            }
        }
    }

    func fetchBlockedUsers(completion: @escaping () -> Void) {
        guard let currentUserId = currentUserId else { return }
        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .getDocument { documentSnapshot, error in
                if let data = documentSnapshot?.data() {
                    self.blockedUsers = data["blockedUserIds"] as? [String] ?? []
                } else {
                    self.blockedUsers = []
                }
                completion()
            }
    }

    func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection("users")
            .getDocuments { snapshot, error in
                var allUsers = [User]()
                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        let user = User(data: data, uid: document.documentID)
                        if user.uid != self.currentUserId &&
                            !self.blockedByUsers.contains(user.uid) {
                            allUsers.append(user)
                        }
                    }
                    DispatchQueue.main.async {
                        self.users = allUsers
                        self.filterUsers()
                    }
                }
            }
    }

    func filterUsers() {
            DispatchQueue.main.async {
                let query = self.searchQuery.lowercased()

                if query.isEmpty {
                    self.filteredUsers = []
                } else if let cachedResults = self.searchCache[query] {
                    // Use cached results
                    self.filteredUsers = cachedResults
                } else {
                    // Perform filtering and cache the results
                    let results = self.users.filter { user in
                        user.name.lowercased().contains(query) ||
                        user.username.lowercased().contains(query)
                    }
                    self.searchCache[query] = results
                    self.filteredUsers = results
                }
            }
        }
    }

