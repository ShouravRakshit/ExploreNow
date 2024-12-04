//
//  MainMessagesView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import SwiftUI
import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct MainMessagesView: View {
    @State private var shouldShowLogOutOptions = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowChangePasswordConfirmation = false
    @State private var shouldShowNewMessageScreen = false

    @State private var searchQuery = "" // Search query for filtering messages

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @ObservedObject private var vm = MainMessagesViewModel()
    @State private var selectedChatUser: ChatUser? // Store the selected user for navigation

    var body: some View {
        NavigationView {
            VStack {
                customNavBar

                searchBar

                messagesView

                Spacer()

                // Hidden navigation link for ChatLogView
                NavigationLink(
                    destination: ChatLogView(chatUser: selectedChatUser).environmentObject(userManager),
                    isActive: $shouldNavigateToChatLogView
                ) {
                    EmptyView()
                }
            }
            .background(Color(.systemGray6))
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
                CreateNewMessageView { user in
                    self.selectedChatUser = user
                    self.shouldNavigateToChatLogView = true
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            TextField("Search users...", text: $searchQuery)
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .padding(.horizontal)
                .onChange(of: searchQuery) { newValue in
                    vm.filterMessages(query: newValue)
                }
        }
        .padding(.top, 10)
    }

    // MARK: - Messages View
    private var messagesView: some View {
        VStack {
            ScrollView {
                if vm.filteredMessages.isEmpty {
                    VStack {
                        Spacer()
                        if searchQuery.isEmpty {
                            Button(action: {
                                shouldShowNewMessageScreen = true
                            }) {
                                Text("Click here to start a new chat")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        } else {
                            Text("No matches found.")
                                .foregroundColor(.gray)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Spacer()
                    }
                } else {
                    ForEach(vm.filteredMessages) { recentMessage in
                        VStack {
                            Button {
                                handleChatSelection(recentMessage: recentMessage)
                            } label: {
                                HStack(spacing: 16) {
                                    WebImage(url: URL(string: recentMessage.profileImageUrl))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipped()
                                        .cornerRadius(25)
                                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color(.label), lineWidth: 1))

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(recentMessage.name ?? "")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color(.label))
                                        Text(recentMessage.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(.darkGray))
                                            .lineLimit(1)
                                    }
                                    Spacer()

                                    Text(vm.timeAgo(recentMessage.timestamp.dateValue()))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.lightGray))
                                }
                                .padding(.horizontal)
                            }
                            Divider()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    // MARK: - Custom Nav Bar
    private var customNavBar: some View {
        HStack(spacing: 16) {
            if let currentUser = userManager.currentUser {
                NavigationLink(destination: ProfileView(user_uid: currentUser.uid)) {
                    WebImage(url: URL(string: currentUser.profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(44)
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1))
                        .shadow(radius: 5)
                }
            } else {
                Text("Loading...") // Placeholder for loading state
                    .font(.system(size: 16, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 4) {
                let name = userManager.currentUser?.name ?? ""
                Text(name)
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }

            Spacer()

            // New Message Button
            Button(action: {
                shouldShowNewMessageScreen = true
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
    }

    // MARK: - Helper Functions
    private func handleChatSelection(recentMessage: RecentMessage) {
        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId

        let data = [
            "uid": uid,
            "email": recentMessage.email,
            "profileImageUrl": recentMessage.profileImageUrl,
            "name": recentMessage.name
        ]
        self.selectedChatUser = ChatUser(data: data)
        self.shouldNavigateToChatLogView = true
    }
}
