//
//  CreateNewMessageView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import SwiftUI
import SDWebImageSwiftUI

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
