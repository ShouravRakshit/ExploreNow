//
//  ProfileView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-10-19.
//

import SwiftUI
import SDWebImageSwiftUI


struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var description = "Travel Blogger DM for collabs" // Editable from Settings
    @State private var postCount = 600
    @State private var friendsCount = 1100
    @State private var posts = Array(1...5) // Dummy posts array
    var profileImageUrl: String? // getting the profile image URL
    var name: String // getting the name

    var body: some View {

            NavigationView
                {
                    VStack(alignment: .leading) {
                        // Profile Info Section
                        HStack {
                            Spacer()
                            NavigationLink(destination: SettingsPage(description: $description)) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(Color(red: 0.45, green: 0.3, blue: 0.7))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Profile Image and Counts Section
                        HStack {
                            WebImage(url: URL(string: profileImageUrl ?? ""))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(40)
                                .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.customPurple, lineWidth: 1))
                            
                                .padding(.horizontal, 1)
                            
                            // Post Counts
                            VStack {
                                Text("\(postCount)")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Posts")
                                    .font(.system(size: 16))
                            }.padding(.horizontal, 40)
                            
                            
                            
                            // Friends Counts
                            VStack {
                                Text("\(friendsCount)")
                                    .font(.system(size: 20, weight: .bold))
                                Text("Friends")
                                    .font(.system(size: 16))
                            }.padding(.horizontal, 10)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Username and Description
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.system(size: 24, weight: .bold))
                            Text(description)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 21)
                        .padding(.top, 8)
                        
                        // Posts Section
                        ScrollView {
                            VStack {
                                ForEach(posts, id: \.self) { post in
                                    PostCard(postId: post).padding(.top, 10)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    Spacer() 
                    }
                    .navigationBarHidden(true)
                    .background(Color.white) // Ensure the background is consistent
            }
        }
}

// PostCard Component
struct PostCard: View {
    var postId: Int
    @State private var showingAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    showingAlert = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.gray)
                }
            }
            .padding([.top, .trailing])
            
            Rectangle()
                .fill(Color(red: 217/255, green: 217/255, blue: 217/255)) // Fill with #D9D9D9
                .frame(height: 172)
                .padding(.horizontal, 10)
                .padding(.top, 6)
            
            HStack {
                Image(systemName: "bubble.right").foregroundColor(Color.customPurple)
                Text("600")
                
                Spacer()
                    HStack(spacing: 10) {  // creating a separate HStack for the heart and location
                        Image(systemName: "heart.fill").foregroundColor(Color.customPurple)
                        Text("1.2k")
                        Image(systemName: "mappin.and.ellipse").foregroundColor(Color.customPurple)
                        Text("Location")
                    }
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .padding(.top, 5)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        
        // adding purple border
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.customPurple, lineWidth: 1))
        // giving the alert message before you delete the post.
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Delete Post"),
                message: Text("Are you sure you want to delete this post?"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting post with ID \(postId)")
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct SettingsPage: View {
    @Binding var description: String
    @State private var newDescription = ""
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .padding()
        }
        .padding()
        .navigationTitle("Settings")
    }
}

struct ProfilePage_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(profileImageUrl: "https://example.com/sample-image.jpg", name: "Naruto Uzumaki")
    }
}
