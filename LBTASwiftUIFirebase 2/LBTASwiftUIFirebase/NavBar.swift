//
//  NavBar.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-21.
//
import SwiftUI
//import UIKit

struct NavBar: View {
    @State var user: User?
    @EnvironmentObject var userManager: UserManager

    init() {
        // Set consistent appearance for all tabs
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        let customPurpleUIColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0)

        tabBarAppearance.backgroundColor = customPurpleUIColor
        
        // Update selected and unselected item colors
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.gray)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
        
        // Set the appearance for both standard and scrolling
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    var body: some View {
       // NavigationView {
            TabView {
                
                HomeViewTest()
                    .tabItem {
                        Image(systemName: "house")
                    }
                
                MapPinView()
                    .tabItem {
                        Image(systemName: "mappin.and.ellipse")
                    }
                
                AddPostView()
                    .tabItem {
                        Image(systemName: "plus.circle.fill")
                    }
                    .environmentObject(userManager)
                
                MainMessagesView()
                    .tabItem {
                        Image(systemName: "message")
                    }
                    .environmentObject(userManager)
                
                if let user = userManager.currentUser {
                    ProfileView(user_uid: user.uid)
                        .tabItem {
                            Image(systemName: "person")
                        }
                        .environmentObject(userManager)
                }
            }
            .accentColor(.white) // Use your custom purple color
      //  }
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


struct MapViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapController {
        return MapController() // Initialize the view controller
    }

    func updateUIViewController(_ uiViewController: MapController, context: Context) {
        // Update the view controller if needed
    }
}


