//
//  CreateNewMessageView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 07/10/2024.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    @Published var searchQuery = ""          // Added
    @Published var filteredUsers = [ChatUser]() // Added
    @Published var blockedUsers: [String] = []
    @Published var blockedByUsers: [String] = []


    init() {
            fetchBlockedUsers {
                self.fetchBlockedByUsers {
                    self.fetchFriends()
                }
            }
        }
    
    func fetchBlockedByUsers(completion: @escaping () -> Void) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            completion()
            return
        }

        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .getDocument { documentSnapshot, error in
                if let error = error {
                    print("Error fetching blockedBy users: \(error)")
                }
                if let data = documentSnapshot?.data() {
                    self.blockedByUsers = data["blockedByIds"] as? [String] ?? []
                } else {
                    self.blockedByUsers = []
                }
                completion()
            }
    }

    
    func fetchUsers(withUIDs uids: [String]) {
        var users = [ChatUser]()
        let dispatchGroup = DispatchGroup()
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        for uid in uids {
            // Skip if the user is in blockedByUsers
            if self.blockedByUsers.contains(uid) {
                continue
            }

            dispatchGroup.enter()
            FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { documentSnapshot, error in
                if let error = error {
                    print("Failed to fetch user with uid \(uid): \(error.localizedDescription)")
                } else if let data = documentSnapshot?.data() {
                    let user = ChatUser(data: data)
                    if user.uid != currentUserId && !self.blockedUsers.contains(user.uid) {
                        users.append(user)
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.users = users
            self.filterUsers()
        }
    }


    
    func fetchFriends() {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let friendsRef = FirebaseManager.shared.firestore.collection("friends").document(currentUserId)
        friendsRef.getDocument { document, error in
            if let error = error {
                self.errorMessage = "Failed to fetch friends: \(error.localizedDescription)"
                return
            }

            guard let document = document, document.exists else {
                self.errorMessage = "No friends list found"
                return
            }

            if let friendUIDs = document.data()?["friends"] as? [String], !friendUIDs.isEmpty {
                self.fetchUsers(withUIDs: friendUIDs)
            } else {
                self.errorMessage = "No friends found"
                DispatchQueue.main.async {
                    self.users = []
                    self.filterUsers()
                }
            }
        }
    }
    
    func fetchBlockedUsers(completion: @escaping () -> Void) {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }

        FirebaseManager.shared.firestore.collection("blocks").document(currentUserId)
            .getDocument { documentSnapshot, error in
                if let error = error {
                    print("Error fetching blocked users: \(error)")
                }
                if let data = documentSnapshot?.data() {
                    self.blockedUsers = data["blockedUserIds"] as? [String] ?? []
                } else {
                    self.blockedUsers = []
                }
                completion()
            }
    }

    func filterUsers() {
        if searchQuery.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                user.name.lowercased().contains(searchQuery.lowercased()) ||
                user.email.lowercased().contains(searchQuery.lowercased())
            }
        }
    }

}

struct CreateNewMessageView: View {
    let didSelectNewUser: (ChatUser) -> ()

    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var vm = CreateNewMessageViewModel()

    var body: some View {
        NavigationView {
            VStack {
                searchBar

                if vm.filteredUsers.isEmpty {
                    Text("No friends found")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Spacer()
                } else {
                    ScrollView {
                        ForEach(vm.filteredUsers) { user in
                            Button {
                                presentationMode.wrappedValue.dismiss()
                                didSelectNewUser(user)
                            } label: {
                                HStack {
                                    WebImage(url: URL(string: user.profileImageUrl))
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipped()
                                        .cornerRadius(50)
                                        .overlay(RoundedRectangle(cornerRadius: 50)
                                            .stroke(Color(.label), lineWidth: 2)
                                        )
                                    VStack(alignment: .leading) {
                                        Text(user.name)
                                            .foregroundColor(Color(.label))
                                        Text(user.email)
                                            .foregroundColor(.gray)
                                            .font(.system(size: 12))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .onChange(of: vm.searchQuery) { _ in
                vm.filterUsers()
            }
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("Search", text: $vm.searchQuery)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
        .padding(.top, 10)
    }
}
