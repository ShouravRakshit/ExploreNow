//
//  NavBar.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-21.
//
import SwiftUI

struct NavBar: View {
    @State var user: User?
    @EnvironmentObject var userManager: UserManager
    
    private let customPurple = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0)
    
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .white
        tabBarAppearance.shadowColor = nil
        
        let itemAppearance = UITabBarItemAppearance()
        
        // Selected state
        itemAppearance.selected.iconColor = customPurple
        
        // Normal state
        itemAppearance.normal.iconColor = .systemGray
        
        // Apply appearances
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        UITabBar.appearance().backgroundColor = .white
        UITabBar.appearance().tintColor = customPurple
    }
    
    var body: some View {
        TabView {
            HomeViewTest()
                .tabItem {
                    Image(systemName: "house")
                }
                .toolbarBackground(.white, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            MapPinView()
                .tabItem {
                    Image(systemName: "map")
                }
                .toolbarBackground(.white, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

            AddPostView()
                .tabItem {
                    Image(systemName: "plus.circle")
                }
                .environmentObject(userManager)
                .toolbarBackground(.white, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

            MainMessagesView()
                .tabItem {
                    Image(systemName: "message")
                }
                .environmentObject(userManager)
                .toolbarBackground(.white, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

            if let user = userManager.currentUser {
                ProfileView(user_uid: user.uid)
                    .tabItem {
                        Image(systemName: "person")
                    }
                    .environmentObject(userManager)
                    .toolbarBackground(.white, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
            }
        }
        .accentColor(Color(customPurple))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.systemGray5))
                .offset(y: -49)
            , alignment: .bottom
        )
    }
}


struct SelectedTabBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 140/255, green: 82/255, blue: 255/255))
                    .padding(.horizontal, -8)
                    .padding(.vertical, -4)
            )
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
        return MapController()
    }
    
    func updateUIViewController(_ uiViewController: MapController, context: Context) {
    }
}
