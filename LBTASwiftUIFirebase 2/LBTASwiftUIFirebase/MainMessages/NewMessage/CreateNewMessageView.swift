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

    init() {
        fetchAllUsers()
    }

    private func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection("users").getDocuments { documentsSnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch users: \(error)"
                print("Failed to fetch users: \(error)")
                return
            }

            var allUsers = [ChatUser]()
            documentsSnapshot?.documents.forEach { snapshot in
                let data = snapshot.data()
                let user = ChatUser(data: data)
                // Exclude the current user
                if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    allUsers.append(user)
                }
            }

            DispatchQueue.main.async {
                self.users = allUsers
                self.filterUsers()
            }
        }
    }

    func filterUsers() {
        if searchQuery.isEmpty {
            filteredUsers = []
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
                if vm.filteredUsers.isEmpty && !vm.searchQuery.isEmpty {
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Spacer()
                } else if vm.searchQuery.isEmpty {
                    // Optional: Display a prompt to start typing
                    Text("Start typing to search for users")
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
                                .padding(.leading, 70) // Align divider with text
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
        .padding(.top, 10) // Add space between title and search bar
    }
}
