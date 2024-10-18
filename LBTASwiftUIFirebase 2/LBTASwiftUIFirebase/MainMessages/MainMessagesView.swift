//
//  MainMessagesView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 06/10/2024.
//

import SwiftUI
import SDWebImageSwiftUI

class MainMessagesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @State private var showUserDetail = false
    

    init() {
        checkUserLoggedOut()
        fetchCurrentUser()
    }

    private func checkUserLoggedOut() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        print("Is user currently logged out: \(self.isUserCurrentlyLoggedOut)")
        if !self.isUserCurrentlyLoggedOut{
           //handleSignOut ()
        }
    }

    func fetchCurrentUser() {
        print ("Fetching current user")
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find Firebase UID"
            print ("Could not find Firebase UID")
            self.isUserCurrentlyLoggedOut = true
            return
        }
        
        print ("UID: \(uid)")

        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error.localizedDescription)"
                return
            }

            guard let data = snapshot?.data() else {
                self.errorMessage = "No data found"
                return
            }

            self.chatUser = ChatUser(data: data)
        }
    }

    func handleSignOut() {
        print ("Signing out user in handleSignOut")
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
}

struct MainMessagesView: View {
    @State private var shouldShowLogOutOptions = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowChangePasswordConfirmation = false
    @State private var shouldShowNewMessageScreen = false
    @ObservedObject private var vm = MainMessagesViewModel()
    @State private var selectedChatUser: ChatUser? // Store the selected user for navigation

    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messagesView

                NavigationLink(destination: ChatLogView(chatUser: selectedChatUser), isActive: $shouldNavigateToChatLogView) {
                    EmptyView()
                }
            }
            .overlay(newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
            
        }
    }

    private var customNavBar: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(44)
                .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)

            VStack(alignment: .leading, spacing: 4) {
                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                Text(email)
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
            Button(action: {
                shouldShowLogOutOptions.toggle()
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            ActionSheet(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .default(Text("Change Password"), action: {
                    shouldShowChangePasswordConfirmation.toggle()
                }),
                .destructive(Text("Sign Out"), action: {
                    vm.handleSignOut()
                }),
                .destructive(Text("Delete Account"), action: {
                    showDeleteAccountConfirmation()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
        .alert(isPresented: $shouldShowChangePasswordConfirmation) {
            Alert(
                title: Text("Change Password"),
                message: Text("A password reset link will be sent to your email."),
                primaryButton: .default(Text("OK"), action: {
                    if let email = vm.chatUser?.email {
                        vm.changePassword(email: email) { result in
                            switch result {
                            case .success:
                                print("Password reset email sent.")
                            case .failure(let error):
                                print("Failed to send password reset email:", error.localizedDescription)
                            }
                        }
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }

    private func showDeleteAccountConfirmation() {
        let alert = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to delete your account? This action cannot be undone.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            vm.deleteUserAccount { result in
                switch result {
                case .success:
                    print("Account deleted successfully.")
                    vm.handleSignOut()
                case .failure(let error):
                    print("Failed to delete account:", error.localizedDescription)
                }
            }
        }))

        DispatchQueue.main.async {
            if let topController = UIApplication.shared.windows.first?.rootViewController {
                topController.present(alert, animated: true)
            }
        }
    }

    private var messagesView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    NavigationLink(destination: Text("Destination")) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .padding(8)
                                .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label), lineWidth: 1))

                            VStack(alignment: .leading) {
                                Text("Username")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Message sent to user")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.lightGray))
                            }
                            Spacer()
                            Text("22d")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
    }

    private var newMessageButton: some View {
        Button(action: {
            shouldShowNewMessageScreen.toggle()
        }) {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            SearchUserView(didSelectUser: { user in
                self.selectedChatUser = user // Set the selected user
                self.shouldNavigateToChatLogView = true // Navigate to ChatLogView
                self.shouldShowNewMessageScreen = false // Dismiss the SearchUserView
            })
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
            .preferredColorScheme(.dark)
        
        MainMessagesView()
    }
}
