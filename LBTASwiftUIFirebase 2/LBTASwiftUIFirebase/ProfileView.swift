//
//  ProfileView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-10-19.
//

import SwiftUI
import SDWebImageSwiftUI


struct ProfileView: View {
    @State private var description = "Travel Blogger DM for collabs" // Editable from Settings
    @State private var postCount = 600
    @State private var friendsCount = 1100
    @State private var posts = Array(1...2) // Dummy posts array
    var profileImageUrl: String? // getting the profile image URL
    var name: String // getting the name

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Profile Info Section
                HStack {
                    WebImage(url: URL(string: profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(40)
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color(.label), lineWidth: 1))
                    
                    Spacer()
                    
                    // Post and Friends Counts
                    VStack {
                        Text("\(postCount)")
                            .font(.system(size: 20, weight: .bold))
                        Text("Posts")
                            .font(.system(size: 12))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(friendsCount)")
                            .font(.system(size: 20, weight: .bold))
                        Text("Friends")
                            .font(.system(size: 12))
                    }
                    
                    Spacer()
                    
                    // Settings Icon
                    NavigationLink(destination: SettingsPage(description: $description)) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0.415, green: 0.105, blue: 0.605))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Username and Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 24, weight: .bold))
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Posts Section
                ScrollView {
                    VStack {
                        ForEach(posts, id: \.self) { post in
                            PostCard(postId: post)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// PostCard Component
struct PostCard: View {
    var postId: Int
    @State private var showingAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: {
                    showingAlert = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .cornerRadius(10)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text("Location")
                Spacer()
                Image(systemName: "heart.fill")
                Text("1.2k")
                Spacer()
                Image(systemName: "bubble.right")
                Text("600")
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.vertical)
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
