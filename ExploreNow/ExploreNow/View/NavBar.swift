//
//  NavBar.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ------------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI

struct NavBar: View {
    @State var user: User? // State to hold user information. It is optional, as the user may or may not be logged in.
    @EnvironmentObject var userManager: UserManager  // Accessing the UserManager environment object for managing the user state.
    
    private let customPurple = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0)  // Custom purple color for the tab bar.
    
    init() {
        // Customizing the appearance of the tab bar.
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()  // Ensures the background is opaque.
        tabBarAppearance.backgroundColor = .white // Sets the background color of the tab bar to white.
        tabBarAppearance.shadowColor = nil // Sets the background color of the tab bar to white.
        
        
        let itemAppearance = UITabBarItemAppearance()
        
        // Selected state
        itemAppearance.selected.iconColor = customPurple // Sets the color of the icon when the tab item is selected. Here, it uses the custom purple color.

        // Normal state
        itemAppearance.normal.iconColor = .systemGray // Sets the color of the icon when the tab item is not selected. Here, it uses the default gray color.
        
        // Apply appearances
        tabBarAppearance.stackedLayoutAppearance = itemAppearance // Applies the itemAppearance to the stacked layout (used for tab bar with multiple items).
        tabBarAppearance.inlineLayoutAppearance = itemAppearance // Applies the itemAppearance to the inline layout (used for the minimal bar when only one item is visible).
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance // Applies the itemAppearance to the compact inline layout (used when there is less space, e.g., on small screens).
        
        // Set the appearance for the standard tab bar appearance across the app.
        UITabBar.appearance().standardAppearance = tabBarAppearance
        // iOS 15 and later provides a new `scrollEdgeAppearance` property for customizing the appearance when the tab bar is scrolled to the edge.
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance // Apply the same appearance settings for the tab bar when it is scrolled to the edge.
        }
        
        // Setting the background color of the tab bar to white
        UITabBar.appearance().backgroundColor = .white // This makes the tab bar background color white across the app. It helps maintain a clean, neutral background for the tab bar items.
        
        // Setting the tint color of the tab bar to the custom purple color
        UITabBar.appearance().tintColor = customPurple // This changes the color of the selected tab item icons to the custom purple color. The tint color is applied to various elements of the tab bar, including icons, text, and selected items.
    }
    
    var body: some View {
        TabView {
            // First Tab: HomeViewTest
            HomeViewTest() // This is the first view displayed in the TabView. When the user taps the corresponding tab, this view will be shown.
                .tabItem {
                    Image(systemName: "house")  // This sets the icon for the tab to a "house" symbol, representing the home section.
                }
                .toolbarBackground(.white, for: .tabBar)  // This applies a white background color to the tab bar when this view is active.
                .toolbarBackground(.visible, for: .tabBar) // This ensures the tab bar remains visible while the HomeViewTest view is displayed.
            
            // Second Tab: MapPinView
            MapPinView() // This is the second view displayed in the TabView. When the user taps the map tab, this view will be shown.
                .tabItem {
                    Image(systemName: "map") // This sets the icon for the tab to a "map" symbol, representing a map or location section.
                }
                .toolbarBackground(.white, for: .tabBar) // This applies a white background color to the tab bar when this view is active.
                .toolbarBackground(.visible, for: .tabBar) // This ensures the tab bar remains visible while the MapPinView view is displayed.

            AddPostView() // This view allows users to add posts in the app. It will be displayed when the "plus" tab is tapped.
                .tabItem {
                    Image(systemName: "plus.circle") // This sets the tab icon to a "plus.circle" system icon, representing the action of adding a post.
                }
                .environmentObject(userManager) // Passes the userManager as an environment object, making it accessible to this view and its children.
                .toolbarBackground(.white, for: .tabBar) // Applies a white background to the tab bar when this tab is selected.
                .toolbarBackground(.visible, for: .tabBar) // Ensures the tab bar remains visible when the IndividualPostView is displayed.

            MainMessagesView() // This view is used to display the main message threads or conversations in the app.
                .tabItem {
                    Image(systemName: "message")  // This sets the tab icon to a "message" system icon, representing the messaging section.
                }
                .environmentObject(userManager) // Passes the userManager as an environment object, making it accessible to this view and its children.
                .toolbarBackground(.white, for: .tabBar) // Applies a white background to the tab bar when this tab is selected.
                .toolbarBackground(.visible, for: .tabBar)  // Ensures the tab bar remains visible when the MainMessagesView is displayed.

            if let user = userManager.currentUser {
                // Check if a current user is available in the userManager
                ProfileView(user_uid: user.uid) // If there is a current user, display the ProfileView and pass the user's UID to it
                    .tabItem {
                        Image(systemName: "person")  // Set the tab icon to a "person" system icon, representing the profile section
                    }
                    .environmentObject(userManager) // Pass the userManager as an environment object, making it accessible within ProfileView and its children
                    .toolbarBackground(.white, for: .tabBar) // Set the background color of the tab bar to white when this tab is selected
                    .toolbarBackground(.visible, for: .tabBar) // Ensure the tab bar remains visible when ProfileView is displayed
            }
        }
        .accentColor(Color(customPurple)) // Set the accent color for all interactive elements within the view to 'customPurple'
        .overlay(
            Rectangle() // Use a rectangle overlay to add a custom visual effect at the bottom of the view
                .frame(height: 0.5) // The height of the rectangle is set to 0.5 points, making it a thin line
                .foregroundColor(Color(UIColor.systemGray5)) // Set the rectangle's color to 'systemGray5', a light gray color, for a subtle line appearance
                .offset(y: -49) // Offset the rectangle 49 points upwards from its original position, placing it slightly above the bottom edge of its container
            , alignment: .bottom // Align the overlay to the bottom of the container view
        )
    }
}

// This struct defines a custom ViewModifier that applies a selected tab background effect
struct SelectedTabBackground: ViewModifier {
    // The body method applies the view modifier to the content
    func body(content: Content) -> some View {
        content
        // The background of the content is modified by a rounded rectangle
            .background(
                // Create a rounded rectangle with a corner radius of 8 points
                RoundedRectangle(cornerRadius: 8)
                // Fill the rectangle with a custom purple color using RGB values
                    .fill(Color(red: 140/255, green: 82/255, blue: 255/255))
                // Apply negative horizontal padding to extend the background beyond the content
                    .padding(.horizontal, -8)
                // Apply negative vertical padding to extend the background vertically
                    .padding(.vertical, -4)
            )
    }
}

// This struct provides a preview for the NavBar view in the SwiftUI Preview pane
struct NavBar_Previews: PreviewProvider
    {
    // The previews static variable that returns a view for rendering in the Preview pane
    static var previews: some View
        {
        NavBar() // Returns an instance of the NavBar view to display in the Preview
        }
    }

// This struct defines the MapPinView, which wraps a MapViewController in a SwiftUI view.
struct MapPinView: View {
    // The body property is required by the View protocol, and it defines the view's content.
    var body: some View {
        // MapViewControllerWrapper is used to wrap a UIKit-based MapViewController in a SwiftUI view.
        MapViewControllerWrapper()
        // Ensure the map view extends under the safe areas, covering the entire screen
            .edgesIgnoringSafeArea(.all)
    }
}

// This struct wraps a UIKit-based MapController into a SwiftUI-compatible view.
struct MapViewControllerWrapper: UIViewControllerRepresentable {
    // This method is used to create and initialize the MapController view controller.
    func makeUIViewController(context: Context) -> MapController {
        // Return an instance of the MapController (UIKit-based view controller)
        return MapController()
    }
    
    // This method is used to update the properties or state of the MapController.
    func updateUIViewController(_ uiViewController: MapController, context: Context) {
        // No updates are being performed in this method. It is left empty for now.
    }
}
