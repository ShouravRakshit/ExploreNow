//
//  AllUsersSearchView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-19.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct AllUsersSearchView: View {
    @ObservedObject var vm = AllUsersSearchViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        VStack {
            searchBar

            if vm.filteredUsers.isEmpty {
                Text("No users found")
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                Spacer()
            } else {
                ScrollView {
                    ForEach(vm.filteredUsers) { user in
                        NavigationLink(destination: ProfileView(user_uid: user.uid)) {
                            UserRow(user: user, isBlocked: vm.blockedUsers.contains(user.uid))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onTapGesture {
                            print("NavigationLink tapped for user: \(user.uid)")
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Search Users", displayMode: .inline)
        //.navigationBarBackButtonHidden(false) // Ensure back button is shown
        /*
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    print("Search view dismissed")
                }) {
                    Text("Cancel")
                }
            }
        }*/
        .onAppear {
            print("AllUsersSearchView appeared")
            vm.fetchAllUsers()
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
