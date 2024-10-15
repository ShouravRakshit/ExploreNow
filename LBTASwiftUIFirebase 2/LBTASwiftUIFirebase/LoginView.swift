//
//  ContentView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 06/10/2024.


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false // State for toggling password visibility
    @State var shouldShowImagePicker = false
    @State var image: UIImage?
    @State var loginStatusMessage = ""
    
    // Popular email domains
    let validDomains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "live.com"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login").tag(true)
                        Text("Create Account").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .scaledToFill()
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black, lineWidth: 3))
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .onChange(of: email) { newValue in
                                if !isValidEmailDomain(newValue) {
                                    loginStatusMessage = "Please enter a valid email from popular domains."
                                } else {
                                    loginStatusMessage = ""
                                }
                            }
                        
                        ZStack(alignment: .trailing) {
                            if isPasswordVisible {
                                TextField("Password", text: $password) // Use TextField for visible password
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            } else {
                                SecureField("Password", text: $password) // Use SecureField for hidden password
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                            
                            // Toggle Button
                            Button(action: {
                                isPasswordVisible.toggle() // Toggle password visibility
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye") // Change icon based on visibility
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12) // Add some spacing to the right of the button
                            }
                        }
                    }
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    if isLoginMode {
                        Button(action: {
                            resetPassword()
                        }) {
                            Text("Forgot Password?")
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(LinearGradient(gradient: Gradient(colors: [Color(.purple).opacity(0.5), Color(.purple).opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    private func isValidEmailDomain(_ email: String) -> Bool {
        // Check if the email contains "@" and get the domain part
        guard let domain = email.split(separator: "@").last else { return false }
        return validDomains.contains(String(domain))
    }
    
    private func handleAction() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func loginUser() {
        if !isValidEmailDomain(email) {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }
        
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login user: ", err)
                self.loginStatusMessage = "Failed to login user: \(err.localizedDescription)"
                return
            }
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            self.didCompleteLoginProcess()
        }
    }
    
    private func createNewAccount() {
        if !isValidEmailDomain(email) {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }
        
        if !isValidPassword(password) {
            loginStatusMessage = "Password must be at least 6 characters, including a number and a special character."
            return
        }
        
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image."
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to create user: ", err)
                self.loginStatusMessage = "Failed to create user: \(err.localizedDescription)"
                return
            }
            print("Successfully created user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err.localizedDescription)"
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err.localizedDescription)"
                    return
                }
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err.localizedDescription)"
                    return
                }
                print("User information successfully stored.")
                self.didCompleteLoginProcess()
            }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Check for at least 6 characters, at least one number, and at least one special character
        let passwordRegex = "^(?=.*[0-9])(?=.*[!@#$%^&*()_+{}|:<>?~`\\[\\];'\",.\\/])(?=.{6,}).*"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordTest.evaluate(with: password)
    }
    
    private func resetPassword() {
        // Check if the email is valid before querying Firestore
        if !isValidEmailDomain(email) {
            loginStatusMessage = "Please enter a valid email from popular domains."
            return
        }

        // Check if the email exists in Firestore
        let db = FirebaseManager.shared.firestore
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                self.loginStatusMessage = "An error occurred while checking for user: \(error.localizedDescription)"
                return
            }

            // Check if there are any documents with the email
            if let documents = querySnapshot?.documents, documents.isEmpty {
                self.loginStatusMessage = "No user found with this email."
            } else {
                // Email exists, proceed to send password reset email
                FirebaseManager.shared.auth.sendPasswordReset(withEmail: email) { error in
                    if let error = error {
                        print("Failed to send password reset email: ", error)
                        self.loginStatusMessage = "Failed to send password reset email: \(error.localizedDescription)"
                        return
                    }
                    self.loginStatusMessage = "Password reset email sent. Please check your inbox."
                }
            }
        }
    }
}
