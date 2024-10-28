//
//  NavBar.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-21.
//
import SwiftUI
//import UIKit

struct NavBar: View {
    
    //current user
    @State var user: User?
    @EnvironmentObject var userManager: UserManager

    init()
        {
        //UITabBar.appearance().backgroundColor = UIColor(hex: "#8C52FF")
        //UITabBar.appearance().unselectedItemTintColor = UIColor.white
        
        }
    
    var body: some View
    {
    TabView {
        HomeViewTest ()
            .tabItem {
                Image(systemName: "house")
            }
        
        MapPinView ()
            .tabItem {
                Image(systemName: "mappin.and.ellipse")
            }
        
<<<<<<< HEAD
        AddView ()
=======
        AddPostView ()
>>>>>>> 14696e3 (Add Post interface)
            .tabItem {
                Image(systemName: "plus.circle.fill")
            }
        
        MainMessagesView ()
            .tabItem {
                Image(systemName: "message")
            }
        if let user = userManager.currentUser {
            ProfileView (profileImageUrl: user.profileImageUrl, name: user.name)
                .tabItem {
                    Image(systemName: "person")
                }
        }
    }
    .accentColor(.gray) // Change selected tab icon color
    //.edgesIgnoringSafeArea(.bottom) // Optional: Extend background color to the bottom
    }
        
}

struct NavBar_Previews: PreviewProvider
    {
    static var previews: some View
        {
        NavBar()
        }
    }

struct MapPinView: View {
    var body: some View {
        MapViewControllerWrapper()
                  .edgesIgnoringSafeArea(.all)
    }
}

<<<<<<< HEAD
struct AddView: View {
    var body: some View {
        Text("Add New Item")
            .font(.largeTitle)
            .padding()
    }
}
=======
>>>>>>> 14696e3 (Add Post interface)

struct MapViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapController {
        return MapController() // Initialize the view controller
    }

    func updateUIViewController(_ uiViewController: MapController, context: Context) {
        // Update the view controller if needed
    }
}


