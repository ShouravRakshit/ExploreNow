//
//  AddPostView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import SDWebImageSwiftUI
import MapKit


struct AddPostView: View {
    // Access the UserManager environment object
    @EnvironmentObject var userManager: UserManager
    // The `userManager` environment object is used to manage and access user-related data throughout the app.
    // This allows any changes in user data to automatically update the views that are observing this object.

    let locationManager = CustomLocationManager()    // Initialize a custom location manager
    // A custom location manager instance is created here. This manager likely handles location services such as
    // fetching the user's current location or interacting with APIs for geolocation features.

    @ObservedObject var viewModel = AddPostViewModel()
    // The `viewModel` property is an observed object that manages the state and logic of the "Add Post" view.
    // It handles tasks like post creation, data validation, and communicates with other parts of the app or backend.


    
    @State private var showPixabayPicker = false
    // A state variable used to toggle the visibility of the Pixabay image picker, which allows the user to select an image
    // from the Pixabay service. It is initially set to `false`, meaning the picker is hidden when the view is first loaded.

    @State private var showImageSourceOptions = false
    // Another state variable used to control the display of image source options
    // for selecting an image. It is also initially set to `false`.

    
    @Environment(\.dismiss) var dismiss    // Dismiss the current view
    // This environment variable provides a way to dismiss the current view. The dismiss function is typically used when
    // you want to navigate back or close a modal view, enabling the user to return to the previous screen.
    
    var body: some View {
        // The body of the view, which defines the UI and structure of the "Add Post" screen.
        NavigationView {
            // NavigationView is used to enable navigation features, such as a navigation bar and push/pop of views.
            ScrollView {
                // ScrollView is used to make the content scrollable, useful if the content exceeds the screen size.
                VStack(spacing: 24) {
                    // VStack arranges the child views vertically with a spacing of 24 points between them.
                    // Sections of the view
                    imagesSection
                    descriptionSection
                    locationSection
                    ratingSection
                    statusMessage
                    postButton
                }
                .padding(.vertical, 16)
                // Adds vertical padding to the VStack to space out the content within the scroll view.

            }
            .navigationBarTitleDisplayMode(.inline)
            // This sets the title display mode for the navigation bar to `.inline`, meaning the title will be shown inline
            // with the navigation bar, instead of taking up the full width.
            .toolbar {
                // The toolbar modifier is used to add items to the navigation bar.
                ToolbarItem(placement: .principal) {
                    // The principal placement is used for the main title of the navigation bar.
                    Text("New Post")
                        .font(.system(size: 17, weight: .semibold))
                    // Sets the title "New Post" with a specific font style and weight.
                }
            }
            .background(AppTheme.background)
            // Sets the background color or style for the entire view. `AppTheme.background` refers to a custom
            // theme color defined elsewhere in the app to ensure consistent styling.
        }
        .sheet(isPresented: $showPixabayPicker) {
            // This `.sheet` modifier presents a modal sheet view when the `showPixabayPicker` state is `true`.
            // The sheet will display the `PixabayImagePickerView`, which allows users to select images
            PixabayImagePickerView(allowsMultipleSelection: true) { selectedImages in
                // The `PixabayImagePickerView` is initialized with the option to allow multiple image selection.
                // The closure captures the selected images and passes them to the `handleSelectedImages` function for further processing.

                handleSelectedImages(selectedImages)   // Handle selected images
                // The selected images are passed to the `handleSelectedImages` function, where additional actions can be taken,
                // such as storing the images or updating the UI.
            }
        }
        .actionSheet(isPresented: $showImageSourceOptions) {
            // This `.actionSheet` modifier presents an action sheet when the `showImageSourceOptions` state is `true`.
            // The action sheet provides a set of options for the user to choose from.

            ActionSheet(
                title: Text("Select Image Source"),
                message: nil,               // The action sheet does not have a message, only a title.
                buttons: [
                    // Buttons for the action sheet, allowing the user to choose an image source.
                    .default(Text("Photo Library")) { showPixabayPicker = true },
                    // A default button labeled "Photo Library". When tapped, it triggers the `showPixabayPicker` state to be set to `true`,
                    // which presents the Pixabay image picker for selecting images from the photo library.
                    .cancel()
                    // A cancel button that dismisses the action sheet without taking any action.
                ]
            )
        }
    }

    // Section for adding and previewing images
    private var imagesSection: some View {
        // This computed property defines the section for displaying and adding images in the view.
        VStack(alignment: .leading, spacing: 12) {
            // A vertical stack that arranges the elements inside it with a leading alignment and 12 points of spacing between elements.
            Text("Photos")
            // A Text view to display the title "Photos".
                .font(.system(size: 16, weight: .semibold))
            // The text is styled with a system font, size 16, and a semi-bold weight.
                .foregroundColor(.primary)
            // The text color is set to the primary color of the app (usually black or dark gray).
            
            ScrollView(.horizontal, showsIndicators: false) {
                // A horizontal scroll view that allows the user to scroll through the content horizontally.
                // `showsIndicators: false` hides the scroll indicators (the little arrows) from view.

                HStack(spacing: 12) {
                    // A horizontal stack (HStack) that arranges the content inside it horizontally, with 12 points of spacing between the elements.

                    addPhotoButton
                    imagePreviews
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        // Adds horizontal padding to the entire VStack to create space from the edges of the parent container (like the edges of the screen).
    }

    // Button to add photos
    private var addPhotoButton: some View {
        // This computed property defines a button used to add photos. When tapped, it triggers the action to show image source options.
        Button(action: { showImageSourceOptions = true }) {
            // A Button view that triggers the action to show image source options when pressed.
            VStack {
                // A vertical stack (VStack) that arranges the button content vertically (image above text).
                Image(systemName: "plus.circle.fill")
                // Displays a system image (a filled plus icon, indicating adding something).
                    .font(.system(size: 24))
                // The image is styled with a system font of size 24 to ensure it's large enough and clear.
                Text("Add Photos")
                // A Text view displaying the label "Add Photos" beneath the image.
                    .font(.system(size: 12))
                // The text is styled with a system font of size 12, making it smaller than the image.
            }
            .frame(width: 100, height: 100)
            // The button has a fixed width and height of 100 points, ensuring a consistent button size.
            .background(AppTheme.lightPurple)
            // Sets the background color of the button to a light purple defined in the app theme.
            .foregroundColor(AppTheme.primaryPurple)
            // Sets the text and image color of the button to a primary purple color defined in the app theme.
            .cornerRadius(12)
            // Rounds the corners of the button by 12 points, giving it a soft, pill-shaped appearance.
        }
    }

    // Preview of selected images
    private var imagePreviews: some View {
        // This computed property generates a view to display previews of the selected images.
        ForEach(viewModel.images, id: \.self) { image in
            // Iterates over the `images` array in the `viewModel` and generates a preview for each image.
            // `id: \.self` means each image is uniquely identified by itself (using the image object as the ID).
                   
            ZStack(alignment: .topTrailing) {
                // A ZStack arranges its children views on top of each other with the alignment set to the top-right corner.
                Image(uiImage: image)
                // Creates an Image view from the selected UIImage.
                    .resizable()
                // Makes the image resizable, allowing it to fit into the desired frame.
                    .scaledToFill()
                // Ensures the image fills the available space, potentially cropping it if necessary.
                    .frame(width: 100, height: 100)
                // Sets the size of the image preview to 100x100 points.
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                // Clips the image to a rounded rectangle with a corner radius of 12 points for rounded edges.
                
                Button(action: {
                    // A button that removes the selected image when tapped
                    if let index = viewModel.images.firstIndex(of: image) {
                        viewModel.images.remove(at: index)   // Remove image from the view model's images array.
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                    // Displays a "xmark" icon (a circle with an 'X') to signify deletion.
                        .foregroundColor(.white)
                    // Sets the icon color to white to make it visible against the black background.
                        .background(Color.black.opacity(0.6))
                    // Sets the background color of the icon to black with a 60% opacity to create a semi-transparent overlay effect.
                        .clipShape(Circle())
                    // Clips the background of the button to a circular shape to match the icon's appearance.
                }
                .padding(4)
                // Adds 4 points of padding around the button, positioning it away from the edge of the image.
            }
        }
    }

    // Section for entering a description
    private var descriptionSection: some View {
        // A computed property that returns a View representing the description section of the form.
        VStack(alignment: .leading, spacing: 8) {
            // A vertical stack to arrange its children views in a column with a spacing of 8 points.
            Text("Description")
            // A label that displays the text "Description" as the title of this section.
                .font(.system(size: 16, weight: .semibold))
            // Sets the font size to 16 points with a semibold weight for emphasis.
            TextField("Share your experience...", text: $viewModel.descriptionText, axis: .vertical)
            // A TextField for the user to input a description.
            // Placeholder text is "Share your experience...".
            // The text input is bound to `viewModel.descriptionText` to allow state management.
                .textFieldStyle(.roundedBorder)
            // Applies a rounded border style to the TextField, giving it a rounded appearance.
                .frame(height: 100, alignment: .top)
            // Specifies the height of the TextField to 100 points and aligns the content to the top.
                .padding(8)
            // Adds 8 points of padding inside the TextField for spacing around the text.
                .background(AppTheme.background)
            // Sets the background color of the TextField to the `AppTheme.background` color.
                .cornerRadius(12)
            // Rounds the corners of the TextField with a radius of 12 points.
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                    // Adds a border around the TextField using a `RoundedRectangle` with a 1-point width and a light gray color.
                )
                .lineLimit(5...10)
            // Restricts the number of lines the TextField can display, between 5 and 10 lines.
                .tint(.blue)
            // Sets the tint color for the TextField, influencing the cursor and selection highlight color to blue.
        }
        .padding(.horizontal)
        // Adds horizontal padding to the whole VStack to ensure it has spacing on the left and right.
    }

    // Section for selecting location
    private var locationSection: some View {
        // A computed property that returns a View representing the location selection section of the form.
           
        VStack(alignment: .leading, spacing: 8) {
            // A vertical stack that arranges its child views vertically with a spacing of 8 points between them.
            Text("Location")
            // A label that displays the text "Location" as the title of this section.
                .font(.system(size: 16, weight: .semibold))
            // Sets the font size to 16 points with a semibold weight for emphasis.
            LocationSearchBar(selectedLocation: $viewModel.selectedLocation, latitude: $viewModel.latitude, longitude: $viewModel.longitude)
            // A custom `LocationSearchBar` component where the user can search and select a location.
            // The selected location, latitude, and longitude are bound to the `viewModel` properties for state management.
                .background(AppTheme.background)
            // Sets the background color of the search bar to `AppTheme.background`.
                .cornerRadius(12)
            // Rounds the corners of the search bar with a radius of 12 points to match the design.
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                    // Adds a border around the search bar using a `RoundedRectangle` with a 1-point width and a light gray color.
                )
        }
        .padding(.horizontal)
        // Adds horizontal padding around the whole VStack to ensure spacing on the left and right sides of the section.
    }

    // Section for rating
    private var ratingSection: some View {
        // A computed property that returns a View representing the rating section of the form.
        VStack(alignment: .leading, spacing: 8) {
            // A vertical stack that arranges its child views vertically with a spacing of 8 points between them.
            Text("Rating")
            // A label displaying the text "Rating" as the title for this section.
                .font(.system(size: 16, weight: .semibold))
            // Sets the font size to 16 points with a semibold weight for emphasis.
            HStack(spacing: 12) {
                // A horizontal stack that arranges its child views (stars) horizontally with 12 points of spacing between them.
                ForEach(1...5, id: \.self) { star in
                    // Iterates over a range of numbers from 1 to 5 to create 5 stars for the rating.
                    // Each star represents a level of the rating (1 to 5).
                    Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                    // Displays a filled star (`star.fill`) if the current `star` is less than or equal to the selected rating (`viewModel.rating`).
                    // Otherwise, it shows an empty star (`star`).
                        .font(.system(size: 24))
                    // Sets the font size of the stars to 24 points for clear visibility.
                        .foregroundColor(star <= viewModel.rating ? .yellow : Color(.systemGray4))
                    // Colors the star yellow if it is selected, otherwise it is gray.
                        .onTapGesture {
                            withAnimation(.spring()) {
                                viewModel.rating = star    // Set rating when a star is tapped.
                                // Updates the `viewModel.rating` to the selected star value (1 to 5).
                                // The animation makes the rating change appear smoothly.
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
        // Adds horizontal padding around the whole VStack to ensure spacing on the left and right sides of the section.
    }

    // Display status messages
    private var statusMessage: some View {
        // A computed property that returns a View for displaying status messages.
        Group {
            // A container that groups the following views together. It helps to conditionally display the status message only when necessary.
            if !viewModel.addPostStatusMessage.isEmpty {
                // Checks if the `addPostStatusMessage` is not empty, meaning there is a status message to display.
                           
                Text(viewModel.addPostStatusMessage)
                // Displays the actual status message text stored in the `viewModel.addPostStatusMessage`.
                    .font(.system(size: 14))
                // Sets the font size of the text to 14 points for readability.
                    .foregroundColor(viewModel.addPostStatusMessage.contains("Error") ? AppTheme.error : AppTheme.success)
                // Sets the text color:
                // - If the message contains the word "Error", it uses the `error` color from the `AppTheme`.
                // - Otherwise, it uses the `success` color from the `AppTheme`.
                    .padding(.vertical, 8)
                // Adds vertical padding around the status message text to create space above and below the message.
                                
                    .frame(maxWidth: .infinity)
                // Ensures the status message spans the entire width of its container, providing a full-width appearance.
                    .background(
                        viewModel.addPostStatusMessage.contains("Error") ? AppTheme.error.opacity(0.1) : AppTheme.success.opacity(0.1)
                    )
                // Sets the background color of the status message:
                // - If the message contains the word "Error", the background uses the `error` color with 10% opacity.
                // - Otherwise, it uses the `success` color with 10% opacity, making the background color subtle.
                    .cornerRadius(8)
                // Rounds the corners of the background view, giving the status message a smooth, pill-like appearance.
                    .padding(.horizontal)
                // Adds horizontal padding to the entire status message container for layout spacing on the left and right.
            }
        }
    }

    // Button to submit the post
    private var postButton: some View {
        // A computed property that returns a View for the 'Share Post' button.
        Button(action: viewModel.addPost) {
            // Creates a button. When pressed, the `addPost` method from the view model is called to submit the post.
            HStack {
                // A horizontal stack to arrange the progress indicator (if loading) and the "Share Post" label side by side.
                if viewModel.isLoading {
                    // Checks if the `isLoading` flag in the view model is true. If true, show the loading indicator.
                    ProgressView()
                    // Displays a progress indicator to show that something is loading.
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    // Sets the style of the progress view to a circular spinner with white color.
                        .padding(.trailing, 8)
                    // Adds padding to the right of the loading indicator to create space between the indicator and the text.
                }
                Text("Share Post")
                // Displays the text label "Share Post" on the button.
                    .font(.system(size: 16, weight: .semibold))
                // Sets the font of the button text to a system font with size 16 and a semibold weight for emphasis.
            }
            .frame(maxWidth: .infinity)
            // Makes the button expand horizontally to take up all available width within its container.
            .padding(.vertical, 16)
            // Adds vertical padding within the button to create space above and below the text and progress indicator.
            .background(viewModel.isLoading ? Color.gray : AppTheme.primaryPurple)
            // Sets the button's background color:
            // - If `isLoading` is true, the background is set to gray.
            // - Otherwise, it uses the `primaryPurple` color from `AppTheme`
            .foregroundColor(.white)
            // Sets the text color of the button to white.
            .cornerRadius(12)
            // Applies rounded corners to the button with a corner radius of 12 to give it a smooth, pill-like appearance.
        }
        .disabled(viewModel.isLoading)
        // Disables the button if `isLoading` is true, preventing multiple submissions during the loading state.
        .padding(.horizontal)
        // Adds horizontal padding to the button for spacing on the left and right.
        .padding(.top, 8)
        // Adds top padding to the button to create space between the button and any elements above it.
    }

    // Handle image selection
    private func handleSelectedImages(_ selectedImages: [PixabayImage]) {
        // A function to handle the selection of images. It takes an array of `PixabayImage` objects as input.
        let group = DispatchGroup()
        // Creates a DispatchGroup to manage the concurrent download tasks and notify when all downloads are finished.
        for selectedImage in selectedImages {
            // Loops through each selected image from the `selectedImages` array.
            if let urlString = selectedImage.largeImageURL, let url = URL(string: urlString) {
                // Checks if the `largeImageURL` property is not nil for the current `PixabayImage`,
                // and if it is a valid URL, it proceeds to download the image
                group.enter()
                // Notifies the DispatchGroup that a new asynchronous task is being started (image download).
                downloadImage(from: url) { image in
                    // Calls the `downloadImage` function to download the image from the provided URL.
                    if let image = image {
                        viewModel.images.append(image)
                        // If the image was successfully downloaded, it is appended to the `viewModel.images` array.
                    }
                    group.leave()
                    // Notifies the DispatchGroup that the current download task is finished.
                }
            }
        }
        group.notify(queue: .main) {
            // Once all tasks in the DispatchGroup are completed, it notifies on the main queue.
            print("All images downloaded and added.")
            // Prints a message to the console indicating that all images have been downloaded and added to the `viewModel.images` array.
        }
    }
    
    // Function to download the images from Pixabay
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // A function to download an image from the specified URL. It takes a URL and a completion closure
        // which will return a `UIImage?` (optional) when the download is complete.
        SDWebImageDownloader.shared.downloadImage(with: url) { image, data, error, finished in
            // Uses the `SDWebImageDownloader` to download the image from the provided URL.
            // The closure will be called with the image, data, error, and whether the download is finished.

            DispatchQueue.main.async {
                // Ensures that the UI update (calling the completion handler) happens on the main thread.
                if let image = image, finished {
                    // Checks if the image was successfully downloaded and if the download process has finished.
                    completion(image)
                    // Calls the completion handler with the downloaded image if successful.
                } else {
                    print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                    // If the download fails, prints an error message to the console with the error description.
                    completion(nil)
                    // Calls the completion handler with `nil` to indicate that the image could not be downloaded.
                }
            }
        }
    }
}


