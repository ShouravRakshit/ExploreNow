//
//  ProfileSettingsView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-19.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI
//------------------------------------------------------------------------------------
struct ProfileSettingsView: View
    {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager
    
    @State var shouldShowImagePicker = false
    @State var image: UIImage?
    
    @State private var selectedRow: String? // Track the selected row
    @State private var showEditView = false
    
    
    var body: some View
        {
        VStack
            {
            //----- TOP ROW --------------------------------------
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
                Text ("Edit Profile")
                    .font(.custom("Sansation-Regular", size: 30))
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                    .offset(x:-30)
                Spacer() // Pushes the text to the center
                }
            //------------------------------------------------
            ZStack
                {
                // Circular border
                Circle()
                    .stroke(Color.black, lineWidth: 4) // Black border
                    .frame(width: 188, height: 188) // Slightly larger than the image
                
                    // User image
                    if let image = self.userManager.currentUser?.profileImageUrl
                        {
                        WebImage(url: URL(string: image ?? ""))
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
            
                if let image = self.userManager.currentUser?.profileImageUrl
                    {
                    Text ("Upload Profile Picture")
                        .padding(.top, 15)
                        .font(.custom("Sansation-Regular", size: 21))
                        .foregroundColor(.blue)
                        .underline() // Underline the text
                        .onTapGesture{
                            shouldShowImagePicker.toggle()
                        }
                        .padding(.bottom, 50)
                    }
                else
                    {
                    Text ("Change Profile Picture")
                        .padding(.top, 15)
                        .font(.custom("Sansation-Regular", size: 21))
                        .foregroundColor(.blue)
                        .underline() // Underline the text
                        .onTapGesture{
                            //shouldShowImagePicker.toggle()
                        }
                        .padding(.bottom, 50)
                    }
               
            
            Grid {
                Divider()
                GridRow {
                        HStack{
                            Text("Name:")
                                .frame(maxWidth: 125, alignment: .leading)
                                .padding (.leading, 10)
                                .font(.custom("Sansation-Bold", size: 20))
                            if let name = self.userManager.currentUser?.name
                            {
                                Text(name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .offset(x: -10)
                                    .font(.custom("Sansation-Regular", size: 20))
                            }
                        }
                    .padding(.vertical, 5)
                    .background(selectedRow == "Name" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
                    .onTapGesture {
                        selectedRow = "Name" // Update selected row
                        showEditView = true
                    }
                }

                Divider()
                
                GridRow {
                        HStack{
                            Text("Username:")
                                .frame(maxWidth: 125, alignment: .leading)
                                .padding (.leading, 10)
                                .font(.custom("Sansation-Bold", size: 20))
                            if let username = self.userManager.currentUser?.username
                            {
                                Text(username)
                                    .offset(x: -10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.custom("Sansation-Regular", size: 20))
                            }
                        }
                    .padding(.vertical, 5)
                    .background(selectedRow == "Username" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
                    .onTapGesture {
                        selectedRow = "Username" // Update selected row
                        showEditView = true
                    }
                }

                Divider()
                
                GridRow {
                        HStack{
                            Text("Bio:")
                                .frame(maxWidth: 125, alignment: .leading)
                                .padding (.leading, 10)
                                .font(.custom("Sansation-Bold", size: 20))
                            if let bio = self.userManager.currentUser?.bio{
                                Text(bio)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .offset(x: -10)
                                    .font(.custom("Sansation-Regular", size: 20))
                                    .lineLimit(nil) // Allow for multiple lines
                                    .fixedSize(horizontal: false, vertical: true) // Allow vertical growth
                            }
                            else{
                                Text(" ")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .offset(x: -10)
                                    .font(.custom("Sansation-Regular", size: 20))
                                    .lineLimit(nil) // Allow for multiple lines
                                    .fixedSize(horizontal: false, vertical: true) // Allow vertical growth
                            }
                        }
                    .padding(.vertical, 5)
                    .background(selectedRow == "Bio" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
                    .onTapGesture {
                        selectedRow = "Bio" // Update selected row
                        showEditView = true
                    }
                }

                Divider()
                }
            
            Text ("Change Password")
                .padding(.top, 50)
                .font(.custom("Sansation-Regular", size: 23))
                .foregroundColor(.blue)
                .underline() // Underline the text
                .onTapGesture{
                    
                }
            
            Spacer() // Pushes content to the top
            }
            .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil)
                {
                ImagePicker(image: $image)
                }
            .fullScreenCover(isPresented: $showEditView) {
                if selectedRow == "Name" {
                    EditView(fieldName: "Name")
                        .environmentObject(userManager)
                } else if selectedRow == "Username" {
                    EditView(fieldName: "Username")
                        .environmentObject(userManager)
                } else if selectedRow == "Bio" {
                    EditView(fieldName: "Bio")
                        .environmentObject(userManager)
                }
            }
            .onAppear
                {
                // Load initial image from user manager
                /*
                if let profileImageUrl = userManager.currentUser?.profileImageUrl {
                    loadImage(from: profileImageUrl) { loadedImage in
                        self.image = loadedImage
                    }
                }
                 */
                }
        }
    
    private func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        guard let imageUrl = URL(string: url) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }


    }

//------------------------------------------------------------------------------------
/*
struct ProfileSettingsView_Previews: PreviewProvider
    {
    static var previews: some View
        {
        ProfileSettingsView()
        }
    }
*/
//------------------------------------------------------------------------------------
