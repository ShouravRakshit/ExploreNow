//
//  PostCardView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct PostCardView: View {
    // Define a struct that conforms to the 'View' protocol for creating a custom card for a post
    @StateObject private var viewModel: PostCardViewModel
    // Declare a view model for handling state related to the post card view.
       
    let post: Post
    // Declare a constant to hold the post data, which is passed to this view.
    var onDelete: ((Post) -> Void)?
    // Declare an optional closure that handles the deletion of the post.

    init(post: Post, onDelete: ((Post) -> Void)? = nil) {
        // Initialize the view with a post object and an optional delete closure.
        self.post = post
        self.onDelete = onDelete
        _viewModel = StateObject(wrappedValue: PostCardViewModel(post: post))
        // Initialize the view model and bind it to this view.
    }

    var body: some View {
        // The body property defines the UI layout of this view.
        NavigationLink(destination: IndividualPostView(post: post, likesCount: viewModel.likesCount, liked: viewModel.liked)) {
            // Wrap the entire card in a NavigationLink that leads to the IndividualPostView.
            VStack(alignment: .leading, spacing: 0) {
                // Stack elements vertically with leading alignment, with no spacing between the elements.
                // Header Section
                HStack(spacing: 12) {
                    // Horizontal stack to arrange items with a fixed spacing of 12.
                                        
                    // Profile Image
                    if let imageUrl = URL(string: post.userProfileImageUrl) {
                        // Try to create a URL from the 'userProfileImageUrl' string in the 'post' object.
                        // If the URL is valid, execute the following block of code.

                        WebImage(url: imageUrl)
                        // Use WebImage to load and display the image from the given URL.
                            .resizable()
                        // Make the image resizable to fit the desired frame size.
                            .scaledToFill()
                        // Scale the image to fill the space of its frame (may crop if aspect ratio is different).
                            .frame(width: 40, height: 40)
                        // Set the frame of the image to be 40x40 points.
                            .clipShape(Circle())
                        // Clip the image into a circular shape.
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.lightPurple, lineWidth: 2)
                                // Add a circular border around the image with a purple color (from AppTheme) and a line width of 2.
                            )
                    } else {
                        // If the URL is invalid or empty, display a default placeholder image.
                        Image(systemName: "person.circle.fill")
                        // Use a built-in system image of a filled circle representing a person as a placeholder.
                            .resizable()
                        // Make the placeholder image resizable to fit the desired frame size.
                            .frame(width: 40, height: 40)
                        // Set the frame of the image to be 40x40 points, same as the profile image.
                            .foregroundColor(AppTheme.secondaryText)
                        // Apply a color to the placeholder image (from AppTheme) for better visibility.
                            .clipShape(Circle())
                        // Clip the placeholder image into a circular shape, similar to the profile image.
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Create a vertical stack (VStack) with leading alignment and a spacing of 2 points between elements.

                        // Username
                        NavigationLink(destination: ProfileView(user_uid: post.uid)) {
                            // Wrap the username text inside a NavigationLink, which will navigate to the ProfileView
                            // when the username is tapped. The destination view takes the user UID as a parameter.

                            Text(post.username)
                            // Display the username from the 'post' object.
                                .font(.system(size: 16, weight: .semibold))
                            // Set the font to a system font with a size of 16 points and semibold weight.
                                .foregroundColor(AppTheme.primaryPurple)
                            // Set the text color to primaryPurple from the AppTheme.
                        }
                        
                        // Location
                        HStack(spacing: 4) {
                            // Create a horizontal stack (HStack) with 4 points of spacing between the elements.
                            Image(systemName: "mappin.circle.fill")
                            // Display a system image representing a location pin (mappin.circle.fill).
                                .font(.system(size: 12))
                            // Set the font size of the location pin to 12 points.
                            Text(post.locationAddress)
                            // Display the location address from the 'post' object.
                                .font(.system(size: 12))
                            // Set the font size of the location text to 12 points.
                                .lineLimit(1)
                            // Limit the text to a single line, ensuring that it doesn't overflow to multiple lines.
                        }
                        .foregroundColor(AppTheme.secondaryText)
                        // Set the text color for the location elements to secondaryText from the AppTheme.
                    }
                    
                    Spacer()
                    // Add a spacer at the bottom to push the content upwards and take up remaining vertical space.
                    
                    // Timestamp
                    Text(viewModel.formatDate(post.timestamp))
                    // Display the formatted timestamp of the post by using a function (formatDate) from the ViewModel.
                        .font(.system(size: 12))
                    // Set the font size to 12 points.
                        .foregroundColor(AppTheme.secondaryText)
                    // Set the text color to 'secondaryText' from the custom AppTheme
                    
                    if viewModel.isCurrentUserPost {
                        // Check if the post belongs to the current user by evaluating 'isCurrentUserPost' in the ViewModel.
                        // If true, it allows showing a delete button for the user to delete their own post.

                        Button(action: {
                            // Define the action when the delete button is tapped.
                            viewModel.showDeleteConfirmation = true
                            // Set 'showDeleteConfirmation' to true to show the delete confirmation alert.
                            onDelete?(post)
                            // Call the 'onDelete' closure if provided, passing the current post to it.
                        }) {
                            Image(systemName: "trash")
                            // Display a trash can icon using a system image ("trash").
                                .font(.system(size: 18))
                            // Set the icon's font size to 18 points.
                                .foregroundColor(.red)
                            // Set the icon color to red to indicate a delete action.
                        }
                        .alert(isPresented: $viewModel.showDeleteConfirmation) {
                            // Display an alert when 'showDeleteConfirmation' is true.
                            Alert(
                                title: Text("Delete Post"),
                                // Set the title of the alert to "Delete Post."
                                message: Text("Are you sure you want to delete this post?"),
                                // Set the alert message asking for confirmation to delete the post.
                                primaryButton: .destructive(Text("Delete")) {
                                    viewModel.deletePost()
                                    // If the user confirms, call the 'deletePost' function from the ViewModel to delete the post.
                                },
                                secondaryButton: .cancel()
                                // Provide a cancel button to dismiss the alert without deleting the post.
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                // Apply horizontal padding (16 points) to the entire VStack or container.
                .padding(.vertical, 12)
                // Apply vertical padding (12 points) to the entire VStack or container.
                
                // Images Section
                if !post.imageUrls.isEmpty {
                    // Check if the post contains any image URLs. If there are no URLs, this section will be skipped.
                    TabView(selection: $viewModel.currentImageIndex) {
                        // Create a TabView, which will allow users to swipe through the images.
                        // Bind the selection to `viewModel.currentImageIndex` to track the currently selected image.

                        ForEach(post.imageUrls.indices, id: \.self) { index in
                            // Iterate over each index of the image URLs array. The `id: \.self` ensures each image is uniquely identified by its index.
                            if let imageUrl = URL(string: post.imageUrls[index]) {
                                // Try to convert the current image URL string into a URL object. If it succeeds, the WebImage is displayed.
                                WebImage(url: imageUrl)
                                // Use `WebImage` to asynchronously load and display the image from the URL.
                                    .resizable()
                                // Make the image resizable, so it can adapt to the frame size.
                                    .scaledToFill()
                                // Scale the image to fill the frame while maintaining its aspect ratio.
                                    .frame(maxWidth: .infinity)
                                // Set the maximum width of the image frame to expand across the available width.
                                    .frame(height: 300)
                                // Set the height of the image frame to 300 points.
                                    .clipped()
                                // Clip the image to ensure it fits within the frame and avoids overflowing.
                                    .tag(index)
                                // Tag the image view with its index to link it to the TabView's selection. This helps in page navigation.
                            } else {
                                // If the URL is invalid or cannot be converted, display a default photo icon.
                                Image(systemName: "photo")
                                // Use the system's "photo" icon to represent an image
                                    .resizable()
                                // Make the icon resizable to adapt to the frame.
                                    .scaledToFit()
                                // Scale the icon to fit the frame while maintaining its aspect ratio.
                                    .frame(height: 300)
                                // Set the height of the icon to 300 points.
                                    .foregroundColor(AppTheme.secondaryText)
                                // Set the icon color to the `secondaryText` color defined in the app's theme.
                                    .tag(index)
                                // Tag the icon with its index for TabView navigation.
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    // Apply a `PageTabViewStyle` to make the TabView behave like a page-view control, with swiping gestures.
                    .frame(height: 300)
                    // Set the height of the entire TabView to 300 points, ensuring it fits the layout.
                }
                
                // Interaction Bar
                HStack(spacing: 20) {
                    // Create a horizontal stack (HStack) with 20 points of spacing between its elements.
                    // Like Button
                    Button(action: { viewModel.toggleLike() }) {
                        // Create a button. When tapped, it triggers the `toggleLike()` method in the `viewModel` to toggle the like state.
                        HStack(spacing: 6) {
                            // Inside the button, another HStack is used to align the heart icon and the likes count horizontally with 6 points of spacing between them.
                            Image(systemName: viewModel.liked ? "heart.fill" : "heart")
                            // Display a heart icon. If `viewModel.liked` is true, a filled heart is shown ("heart.fill"); otherwise, an empty heart is shown ("heart").
                                .font(.system(size: 20))
                            // Set the font size of the icon to 20 points.
                                .foregroundColor(viewModel.liked ? .red : AppTheme.secondaryText)
                            // Change the color of the heart icon. If liked, it turns red, otherwise it uses a secondary text color from the app's theme.
                            
                            Text("\(viewModel.likesCount)")
                            // Display the number of likes from `viewModel.likesCount`. The number is shown dynamically.
                                .font(.system(size: 14))
                            // Set the font size of the likes count text to 14 points.
                                .foregroundColor(AppTheme.secondaryText)
                            // Set the color of the likes count to a secondary text color defined in the app's theme.
                        }
                    }
                    
                    // Comment Button
                    HStack(spacing: 6) {
                        // Create another HStack for the comment button with 6 points of spacing between the elements.
                        Image(systemName: "bubble.right")
                        // Display a speech bubble icon (representing comments).
                            .font(.system(size: 20))
                        // Set the font size of the bubble icon to 20 points.
                            .foregroundColor(AppTheme.primaryPurple)
                        // Set the color of the speech bubble icon to the primary purple color defined in the app's theme.
                        Text("\(viewModel.comments.count)")
                        // Display the number of comments from `viewModel.comments.count`. This dynamically updates with the number of comments.
                            .font(.system(size: 14))
                        // Set the font size of the comments count text to 14 points.
                            .foregroundColor(AppTheme.secondaryText)
                        // Set the color of the comments count to a secondary text color from the app's theme.
                    }
                    
                    Spacer()
                    // Add a Spacer to push the previous elements to the left side, making sure the content is aligned on the left side of the screen.
                    
                    // Rating
                    HStack(spacing: 4) {
                        // Create a horizontal stack (HStack) to arrange the star icons with a spacing of 4 points between each icon.
                        ForEach(1...5, id: \.self) { index in
                            // Iterate over a range from 1 to 5 (to represent the 5 stars for rating). For each index, the body of the closure is executed.
                            Image(systemName: index <= post.rating ? "star.fill" : "star")
                            // Display a star icon. If the index is less than or equal to the post's rating, a filled star ("star.fill") is displayed; otherwise, an empty star ("star") is shown.
                                .font(.system(size: 12))
                            // Set the font size of the star icon to 12 points.
                                .foregroundColor(index <= post.rating ? .yellow : AppTheme.secondaryText)
                            // If the index is within the post's rating, the star is yellow, indicating that the star is "filled". If the index is greater than the rating, the star is colored using the secondary text color from the app's theme.
                        }
                    }
                }
                .padding(.horizontal, 16)
                // Add horizontal padding of 16 points to the entire HStack, ensuring the content doesn't touch the screen edges.
                .padding(.vertical, 12)
                // Add vertical padding of 12 points to the entire HStack, creating some space around the star rating.
                
                // Description
                if !post.description.isEmpty {
                    // Check if the post description is not empty before displaying it. This ensures that the description section is shown only if there is content.
                    Text(post.description)
                    // Display the description of the post. `post.description` holds the content of the description.
                        .font(.system(size: 14))
                    // Set the font size of the description text to 14 points.
                        .foregroundColor(AppTheme.primaryText)
                    // Set the text color to the primary text color from the app's theme.
                        .padding(.horizontal, 16)
                    // Add horizontal padding of 16 points around the description text.
                        .padding(.bottom, 16)
                    // Add bottom padding of 16 points to give space after the description text.
                        .lineLimit(3)
                    // Limit the description text to a maximum of 3 lines. If the description is longer than 3 lines, it will be truncated.
                }
            }
            .background(AppTheme.background)
            // Set the background color of the entire content (post card) to the background color defined in the app's theme.
            .cornerRadius(16)
            // Apply rounded corners with a radius of 16 points to the entire content to give it a smooth appearance.
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            // Add a subtle shadow effect with a black color at 5% opacity. The shadow has a radius of 8 points, with an offset of 0 in the horizontal direction (x) and 2 points in the vertical direction (y).
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                // Add a border with rounded corners of radius 16 points over the content.
                    .stroke(Color(.systemGray6), lineWidth: 1)
                // The border is gray with a line width of 1 point. This gives the content a light outline, making it more distinguishable.
            )
        }
        .buttonStyle(PlainButtonStyle())
        // This modifier is applied to a button or any element that can trigger an action.
        // `PlainButtonStyle()` ensures that the button does not have any default styling (e.g., no background or padding).
         
        .onAppear {
            // The `onAppear` modifier is called when the view appears on the screen.
            // This is useful for executing code or performing tasks when a view is presented, such as setting up listeners or fetching data.

            viewModel.setupListeners()
            // Call the `setupListeners()` function in the `viewModel`.
            // This function could be used to set up event listeners, observe changes, or perform any initialization tasks
            // necessary for the view when it first appears.
        }
    }
}
