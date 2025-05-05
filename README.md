# **ExploreNow**

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Features](#features)
- [Setup](#setup)
- [Cloning the Repository](#cloning-the-repository)
- [Contributors](#contributors)

# **Introduction**
**ExploreNow** is a travel app designed to help you explore new places with your friends. Today’s travelers aren’t just looking for static reviews and generic recommendations—they want to connect with fellow explorers, share their experiences, and receive up-to-date, personalized insights. Explore Now addresses this gap by offering a social media platform designed specifically for travelers, enabling them to engage with a vibrant community of like-minded adventurers in real-time.
At its core, Explore Now simplifies the travel experience by empowering users to easily share their journeys through photos and tips. It also helps them discover travel destinations, relying on community-generated content to provide recommendations that are authentic and current. With features like friend requests, real-time messaging, and an Explore page, the app makes it easy to find inspiration, ask questions, and interact with other travelers as they plan their next adventure.

---
# **Prerequisites**
- macOS: The application requires macOS for development and testing.
- Xcode 15: Install the latest version of Xcode from the Mac App Store or [Apple Developer](https://developer.apple.com/xcode/)
- Swift: Ensure you are familiar with Swift programming language.
- Git: Version control system to manage your codebase.

# **Features**
- Sign-Up and Login
  - Sign Up: Enter your name, username, email, password, and select a profile picture to start your travel exploration journey.
  - Log In: Enter your username and password to jump back into your adventure with ease.
    
- Create and Share Your Travel Posts
  - Tap the “+” button on to add photos.
  - Upload your photos, add a short description, tag your location, and rate it.
  - Your posts will appear on:
    - Your Profile
    - Friends' Feeds
      
- Connect with Fellow Travelers
  - Send friend requests to connect with others.
  - View their posts on your Home Page.
  - Get alerts for friend requests, likes, and comments.
  - Block users to ensure privacy and safety.
    
- Chat and Stay Connected
  - Use the Chat Feature to message friends.
  - On the Chat Page, the Search Feature helps you find conversations with your friends.
    
- Stay Inspired on the Home Page
  - Scroll through your friends' posts to stay updated.
  - Easily search for and connect with new travelers.
  

- Top 10 Trending Locations to Visit 
    - Be Inspired by Stunning Photos 
    - Dive into breathtaking images of the world’s most exciting destinations. From majestic mountains to bustling cityscapes, each photo is crafted to fuel your wanderlust and spark your next adventure. 

- Stay Ready with Live Weather Updates 
    - Never be caught off guard! With real-time weather information for every trending location, you’ll be prepared for anything—whether you’re planning for sunny days or glittering snow. Stay informed and travel with confidence!

# **Setup**

## Cloning the Repository

1. Open a terminal and clone the repository using Git:

```
git clone https://github.com/ShouravRakshit/ExploreNow.git
```

2. Navigate to the cloned repository:

```
cd ExploreNow
```

### **3. Get API Keys**
Sign up for a free account on [Pixabay](https://pixabay.com/) and [OpenWeather](https://openweathermap.org/). Once registered, navigate to the [Pixabay API Documentation](https://pixabay.com/api/docs/) and [Weather API Documentation](https://openweathermap.org/api) to generate your API key. This key will be required for accessing Pixabay's API features and OpenWeather API features.

### **4. Add API Keys**
Copy the Template: Duplicate the Secrets.template.plist file to create a new Secrets.plist file. Update API Keys: Open Secrets.plist and replace Your_API_Key_Here with your actual API keys.

### **5. Configure Secrets.plist in Xcode**
To properly configure the Secrets.plist file within your Xcode project, follow these detailed steps:

### **6. Open the Project in Xcode**
Start by opening your project in Xcode.

Navigate to the location of your project and double-click on the .xcodeproj or .xcworkspace file to open it.

### **7. Locate Secrets.plist File**
In the Project Navigator on the left side of Xcode, find the Secrets.plist file. This file is located in the main project directory.

### **8. View the File Inspector**
With the Secrets.plist file selected in the Project Navigator, click on the View menu at the top of Xcode. From the dropdown menu, select Inspectors and then Show File Inspector.

### **9. Configure Target Membership**
In the File Inspector pane, locate the section labeled Target Membership. You will see a list of project targets with checkboxes next to them. Ensure that the checkbox for your target project folder is checked under Any Supported Platform and specifically for iOS. This ensures that the Secrets.plist file is included in the build when you compile the app for any iOS device.

### **10. Save Changes**
After checking the appropriate boxes in the Target Membership, save your changes in Xcode by pressing Cmd + S. Use the ⌘ + R shortcut or click the "Run" button in Xcode.


# **Contributors**
- Shourav Rakshit Ivan, Email: shouravrakshit.ivan@ucalgary.ca  (UCID: 30131085)
- Alisha Lalani, Email: alisha.lalani@ucalgary.ca               (UCID: 30123098)
- Alina Mansuri , Email: alina.mansuri@ucalgary.ca	            (UCID: ********)
- Saadman Rahman, Email: saadman.rahman1@ucalgary.ca	          (UCID: 30153482)
- Vidhi Soni, Email: vidhi.soni1@ucalgary.ca                    (UCID: 30117504)
- Manvi Juneja, Email: manvi.juneja@ucalgary.ca	                (UCID: 30153525)
- Shree Patel, Email: shree.patel@ucalgary.ca	                  (UCID: 30185055)
- Zaid Nissar, Email: zaid.nissar@ucalgary.ca	                  (UCID: 30198174)
- Qusai Dahodwalla, Email: qusai.dahodwalla@ucalgary.ca         (UCID: 30193962)

University of Calgary
