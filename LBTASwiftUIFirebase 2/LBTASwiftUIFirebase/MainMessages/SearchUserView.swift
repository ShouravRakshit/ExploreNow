//
//  SearchUserView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 13/10/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct SearchUserView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @State private var users: [ChatUser] = []
    @State private var filteredUsers: [ChatUser] = []
    var didSelectUser: (ChatUser) -> Void // Closure to handle user selection

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search...", text: $searchQuery)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()

                List(filteredUsers) { user in
                    Button(action: {
                        didSelectUser(user) // Call the closure with the selected user
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    }) {
                        HStack {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(25)

                            VStack(alignment: .leading) {
                                Text(user.email)
                                    .font(.headline)
                                Text("Some other info") // Additional user info
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .onAppear(perform: loadUsers)
                .onChange(of: searchQuery) { newValue in
                    filterUsers(query: newValue)
                }
            }
            .navigationTitle("Search Users")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func loadUsers() {
        let db = Firestore.firestore()

        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            // Map the documents to ChatUser instances
            self.users = documents.compactMap { doc -> ChatUser? in
                let data = doc.data()
                return ChatUser(data: data)
            }

            // Initially set filteredUsers to all users
            self.filteredUsers = self.users
        }
    }

    private func filterUsers(query: String) {
        if query.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                user.email.lowercased().contains(query.lowercased())
            }
        }
    }
}
