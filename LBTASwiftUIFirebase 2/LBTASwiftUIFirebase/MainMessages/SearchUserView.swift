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
    @State private var searchQuery = ""
    @State private var users: [ChatUser] = []
    @State private var filteredUsers: [ChatUser] = []
    var didSelectUser: (ChatUser) -> Void

    var body: some View {
            VStack(spacing: 0) {
                // Search Bar with purple border
                HStack {
                  
                    TextField("Search", text: $searchQuery)
                        .foregroundColor(.gray)
                        .padding(.leading, 12) // Ensure the placeholder stays left aligned
                        .padding(.vertical, 10)
                    
                    Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.trailing, 10) // Move the icon to the right
                }
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.customPurple, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Users List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredUsers) { user in
                            Button(action: {
                                didSelectUser(user)
                            }) {
                                UserRowView(user: user)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .background(Color(.systemGray6))
            }
            .onAppear(perform: loadUsers)
            .onChange(of: searchQuery) { newValue in
                filterUsers(query: newValue)
            }
        }
    
    private func loadUsers() {
        let db = FirebaseManager.shared.firestore
        
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.users = documents.compactMap { doc -> ChatUser? in
                let data = doc.data()
                return ChatUser(data: data)
            }
            
            self.filteredUsers = self.users
        }
    }
    
    private func filterUsers(query: String) {
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


struct UserRowView: View {
    let user: ChatUser
    
    var body: some View {
        HStack(spacing: 12) {
            WebImage(url: URL(string: user.profileImageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1)
                
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
