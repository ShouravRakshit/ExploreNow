//
//  MainMessagesView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 06/10/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore

struct RecentMessage: Identifiable {
    var id: String { documentId }

    let documentId: String
    let text: String
    let fromId: String
    let toId: String
    let timestamp: Timestamp
    let email: String
    var profileImageUrl: String
    var name: String?

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.text = data[FirebaseConstants.text] as? String ?? ""
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
        self.email = data[FirebaseConstants.email] as? String ?? ""
        self.profileImageUrl = data[FirebaseConstants.profileImageUrl] as? String ?? ""
    }
}

class MainMessagesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()

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
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch recent messages: \(error)"
                    print(error)
                    return
                }

                self.recentMessages = querySnapshot?.documents.compactMap({ document in
                    let data = document.data()
                    return RecentMessage(documentId: document.documentID, data: data)
                }) ?? []
                self.updateRecentMessagesWithUserData()

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
}

struct MainMessagesView: View {
    @State private var shouldShowLogOutOptions = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowChangePasswordConfirmation = false
    @State private var shouldShowNewMessageScreen = false

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @ObservedObject private var vm = MainMessagesViewModel()
    @State private var selectedChatUser: ChatUser? // Store the selected user for navigation

    var body: some View {
        NavigationView {
            VStack {
                customNavBar

                messagesView

                Spacer()

                NavigationLink(
                    destination: ChatLogView(chatUser: selectedChatUser).environmentObject(userManager),
                    isActive: $shouldNavigateToChatLogView
                ) {
                    EmptyView()
                }
            }
            .background(Color(.systemGray6))
            .toolbarBackground(Color.black, for: .navigationBar) // Set navigation bar background to black
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
                CreateNewMessageView { user in
                    self.selectedChatUser = user
                    self.shouldNavigateToChatLogView = true
                }
            }
        }
    }

    private var messagesView: some View {
        ScrollView {
            if vm.recentMessages.isEmpty {
                VStack {
                    Spacer()
                    Button(action: {
                        shouldShowNewMessageScreen = true
                    }) {
                        Text("Click here to start a new chat")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Spacer()
                }
            } else {
                ForEach(vm.recentMessages) { recentMessage in
                    VStack {
                        Button {
                            let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                            
                            let data = [
                                "uid": uid,
                                "email": recentMessage.email,
                                "profileImageUrl": recentMessage.profileImageUrl,
                                "name": recentMessage.name
                            ]
                            let chatUser = ChatUser(data: data)
                            self.selectedChatUser = chatUser
                            self.shouldNavigateToChatLogView = true
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

                                Text(timeAgo(recentMessage.timestamp.dateValue()))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(.lightGray))
                            }
                            .padding(.horizontal)
                        }
                        Divider()
                    }
                    .padding(.vertical, 8)
                    .onAppear(){
                        updateRecentMessagesWithNames ()
                    }
                }
            }
        }
    }

    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func handleSignOut() {
        do {
            try FirebaseManager.shared.auth.signOut()
            appState.isLoggedIn = false // Update authentication state
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError.localizedDescription)
        }
    }

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
                // Fallback UI in case the currentUser is nil
                Text("Loading...") // or any other placeholder
                    .font(.system(size: 16, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 4) {
                let name = userManager.currentUser?.name ?? ""
                Text(name)
                    .font(.system(size: 24, weight: .bold))
                    .onAppear {
                        print("Name fetched from Firestore is \(name)")
                    }
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

            // Add New Message Button
            Button(action: {
                shouldShowNewMessageScreen = true
            }) {
                Image(systemName: "square.and.pencil")
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
                    handleSignOut()
                }),
                .destructive(Text("Delete Account"), action: {
                    showDeleteAccountConfirmation()
                }),
                .cancel()
            ])
        }
        .alert(isPresented: $shouldShowChangePasswordConfirmation) {
            
            Alert(
                
                title: Text("Change Password"),
                message: Text("A password reset link will be sent to your email."),
                primaryButton: .default(Text("OK"), action: {
                    if let email = userManager.currentUser?.email {
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
                    handleSignOut()
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
    
    
    
    func updateRecentMessagesWithNames() {
        // Iterate over each message in recentMessages
        for (index, recentMessage) in vm.recentMessages.enumerated() {
            // Determine which user (fromId or toId) to fetch the name for
            let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
            
            // Fetch the user's name using the uid
            fetchUserName(uid: uid) { userName in
                // Update the recentMessage's name field once the name is fetched
                DispatchQueue.main.async {
                    // Update the message at the correct index with the fetched name
                    vm.recentMessages[index].name = userName
                }
            }
        }
    }
    
    func fetchUserName(uid: String, completion: @escaping (String) -> Void) {
        print("Fetching user for UID: \(uid)")  // Debugging line
        let userRef = FirebaseManager.shared.firestore.collection("users").document(uid)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let name = data?["name"] as? String {
                    print("Fetched name: \(name)")  // Debugging line
                    completion(name)
                } else {
                    print("Name field not found")  // Debugging line
                    completion("Unknown")
                }
            } else {
                print("Error fetching user: \(error?.localizedDescription ?? "No error description")")  // Debugging line
                completion("Unknown")
            }
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
