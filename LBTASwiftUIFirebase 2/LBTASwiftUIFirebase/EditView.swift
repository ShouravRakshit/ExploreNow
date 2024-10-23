//
//  EditView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-22.
//
import SwiftUI
import Firebase

struct EditView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    var fieldName: String
    @State private var fieldValue: String = "" // Start with an empty field
    @State private var username_available = true
    @State private var username_edited = false

    var body: some View {
        VStack {
 
        HStack
            {
            Image(systemName: "chevron.left")
                .resizable() // Make the image resizable
                .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
                .frame(width: 30, height: 30) // Set size
                .padding()
                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                .onTapGesture
                    {
                    // Go back to profile page
                    presentationMode.wrappedValue.dismiss()
                    }
            Spacer() // Pushes the text to the center
            Text ("Edit \(fieldName)")
                .font(.custom("Sansation-Regular", size: 30))
                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                .offset(x:-30)
            Spacer() // Pushes the text to the center
            }
            
            //Text("Edit \(fieldName)")
            //    .font(.headline)
            //$fieldValue will update as user types
            TextField("Enter \(fieldName)", text: $fieldValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none) // Prevent first letter from being capitalized
                .onChange(of: fieldValue) {
                    isUsernameAvailable ()
                }
            Button("Save") {
                // Handle saving the value here
                // You might want to pass this value back to the main view if needed
                save_field ()
                // Go back to profile settings page
                presentationMode.wrappedValue.dismiss()
            }
                .font(.custom("Sansation-Regular", size: 23))
                .foregroundColor(.white) // Set text color to black
                .padding()
                .frame(width: 350) // Same width as TextField
                .background(Color(red: 140/255, green: 82/255, blue: 255/255)) // Button color
                .cornerRadius(15) // Rounded corners
            
            if fieldName == "Username" && username_edited
            {
                HStack
                {
                    Text(username_available ? "✅" : "❌")
                        .foregroundColor(username_available ? .green : .red)
                    Text(username_available ? "Username is available" : "Username is taken")
                        .foregroundColor(.black)
                        .frame(width: 250, alignment: .leading) // Fixed width for text
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
                .offset(x: 30)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Edit \(fieldName)")
        .onAppear(){
            if (fieldName == "Name")
            {
                if let name = userManager.currentUser?.name
                    {
                    fieldValue = name
                    }
            }
            else if (fieldName == "Username")
            {
                if let username = userManager.currentUser?.username
                    {
                    fieldValue = username
                    }
            }
            else if (fieldName == "Bio")
            {
                if let bio = userManager.currentUser?.bio
                    {
                    fieldValue = bio
                    }
            }
        }
    }
    
    
    private func save_field ()
    {
    print ("Saving field")
    if (fieldName == "Name")
        {
        userManager.setCurrentUser_name (newName: fieldValue)
        }
        else if (fieldName == "Username" && self.username_available && self.username_edited)
        {
        userManager.setCurrentUser_username (newUsername: fieldValue)
        }
    else if (fieldName == "Bio")
        {
        userManager.setCurrentUser_bio (newBio: fieldValue)
        }
    }
    
    private func isUsernameAvailable()
        {
        if let username = userManager.currentUser?.username
            {
            if fieldName == "Username" && !(username == fieldValue)
                {
                username_edited = true
                
                let db = Firestore.firestore()
                
                db.collection("users").whereField("username", isEqualTo: fieldValue).getDocuments
                { querySnapshot, error in
                    if let error = error
                    {
                        print("Error checking username: \(error)")
                        self.username_available = false // Set to false on error
                        return
                    }
                    
                    // Update the variable based on query result
                    self.username_available = querySnapshot?.isEmpty ?? true // True if empty (available), false if taken
                    print("Username availability updated: \(self.username_available)")
                }
                }
            else if fieldName == "Username" && (username == fieldValue){
                username_edited = false
                }
            }
        }
}





