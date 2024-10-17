//
//  SuggestProfilePicView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-17.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct SuggestProfilePicView: View
    {
    @State var image: UIImage?
    @State var navigateToMainMessages = false
    @State private var user: User? // State variable to hold the retrieved user
    @State var statusMessage = ""
    @State var shouldShowImagePicker = false
    @Binding var currentView: LBTASwiftUIFirebaseApp.CurrentView
    var username: String // Accept username as a parameter
    
    var body: some View
        {
        VStack
            {
            Text("Welcome, \(username)") // Use the username in the view
                .padding(.top, 50)
                .font(.custom("Sansation-Regular", size: 35)) // Use Sansation font
                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
            
                .frame(maxWidth: .infinity) // Make it stretch to fill available width
                .multilineTextAlignment(.center) // Center the text alignment
            
            ZStack
                {
                // Circular border
                Circle()
                    .stroke(Color.black, lineWidth: 4) // Black border
                    .frame(width: 188, height: 188) // Slightly larger than the image
                
                // User image
                if let image = self.image
                    {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle()) // Clip to circle shape
                        .frame(width: 180, height: 180) // Set size
                    }
                else
                    {
                    Image(systemName: "person.fill")
                        .font(.system(size: 64))
                        .padding()
                        .foregroundColor(Color(.label))
                        .frame(width: 180, height: 180) // Set size for placeholder
                        .background(Color.gray.opacity(0.2)) // Optional background
                        .clipShape(Circle()) // Clip to circle shape
                    }
                }
            .padding(.top, 30)
                
            Text("Upload Profile Picture")
                .foregroundColor(Color.blue) // Link color
                .font(.custom("Sansation-Regular", size: 25)) // Use Sansation font
                .padding(.top, 10)
                .underline() // Underline the text
                .onTapGesture {
                    shouldShowImagePicker.toggle()
                }
                
            Button(action: {
                        // Action for the button goes here
                persistImageToStorage()
                }) {
                    Text ("Set Profile Picture")
                        .foregroundColor(.white) // Change to your preferred color
                        .font(.custom("Sansation-Regular", size: 20)) // Use Sansation font
                        .padding()
                        .frame(width: 335, alignment: .center)
                        .background(Color(red: 140/255, green: 82/255, blue: 255/255)) // Button color
                        .cornerRadius(15) // Rounded corners
                    }
                .padding(.top, 30)
                .disabled(self.image == nil)
                
            Text("Skip for now")
                .foregroundColor(Color.black) // Link color
                .font(.custom("Sansation-Regular", size: 20)) // Use Sansation font
                .padding(.top, 50)
                .underline() // Underline the text
                .onTapGesture {
                    self.navigateToMainMessages = true
                    currentView = .mainMessages
                }
            Spacer() // Pushes content to the top
            }
            
            .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
                ImagePicker(image: $image)
            }
        }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.statusMessage = "Failed to push image to Storage: \(err.localizedDescription)"
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                    self.statusMessage = "Failed to retrieve downloadURL: \(err.localizedDescription)"
                    return
                }
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL)
        {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }

        // Create userData dictionary to store only the profileImageUrl
        let userData = ["profileImageUrl": imageProfileUrl.absoluteString]

        FirebaseManager.shared.firestore.collection("users")
            .document(uid).updateData(userData) { err in // Use updateData to modify existing data
                if let err = err {
                    print(err)
                    self.statusMessage = "\(err.localizedDescription)"
                    return
                }
                print("Profile image URL successfully stored.")
                self.navigateToMainMessages = true
                currentView = .mainMessages
                // self.didCompleteLoginProcess() // Uncomment if needed
            }
        }
    
    }
