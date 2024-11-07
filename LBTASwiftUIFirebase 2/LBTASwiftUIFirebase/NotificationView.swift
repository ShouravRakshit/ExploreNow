//
//  NotificationView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-11-06.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack{
            //----- TOP ROW --------------------------------------
            HStack {
                Image(systemName: "chevron.left")
                    .resizable() // Make the image resizable
                    .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
                    .frame(width: 30, height: 30) // Set size
                    .padding()
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                    .onTapGesture {
                        // Go back to profile page
                        self.userManager.hasUnreadNotifications = false
                        presentationMode.wrappedValue.dismiss()
                    }
                Spacer() // Pushes the text to the center
                Text("Notifications")
                    .font(.custom("Sansation-Regular", size: 30))
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
                    .offset(x: -30)
                Spacer() // Pushes the text to the center
            }
            //------------------------------------------------
            Spacer()
            
            // Unwrap notifications to avoid optional array being passed to ForEach
            if let notifications = userManager.currentUser?.notifications, !notifications.isEmpty {
                List(notifications, id: \.timestamp) { notification in
                    VStack(alignment: .leading) {
                        Text(notification.message)  // Show notification message
                            .font(.body)
                            .padding(.bottom, 5)

                        HStack {
                            Text("From: \(notification.senderId)")  // Show sender's ID
                                .font(.footnote)
                                .foregroundColor(.gray)

                            Spacer()

                            Text(notification.timestamp.dateValue(), style: .time)  // Show timestamp
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        Divider() // Divider for each notification
                    }
                    .padding(.vertical, 5)
                }
            } else {
                Text("No notifications available.")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            
            Spacer() // Pushes content to the top
  
        }
        .onAppear{
            markNotificationsAsRead()
            userManager.fetchNotifications()// Re-fetch notifications to ensure the read status is reflected
        }
    }
 
    // Function to mark all notifications as read
    private func markNotificationsAsRead() {
        print ("Marking notifications as read")
        // Check if the currentUser exists and if there are notifications
        guard let currentUser = userManager.currentUser else { return }
        
        // Get the notifications from currentUser
        var notifications = currentUser.notifications // Make sure you work with a mutable array

        // Loop through each notification and update its isRead property
        for i in 0..<notifications.count {
            var notification = notifications[i] // Create a mutable copy of the notification
            // Check if notification is unread
            if !notification.isRead {
                // Set isRead to true
                notification.isRead = true
                self.userManager.hasUnreadNotifications = false
                // Update Firestore
                updateNotificationStatus(notification)
                
                // Update the notification in the array
                notifications[i] = notification
            }
        }
    }
    
    // Helper function to update the notification in Firestore
    private func updateNotificationStatus(_ notification: Notification) {
        guard let currentUser = userManager.currentUser else { return }
        
        let db = FirebaseManager.shared.firestore
        let notificationsRef = db.collection("notifications")
        
        // Find the notification by its timestamp and receiverId
        notificationsRef
            .whereField("timestamp", isEqualTo: notification.timestamp)
            .whereField("receiverId", isEqualTo: currentUser.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to update notification status: \(error.localizedDescription)")
                    return
                }
                
                // If the notification exists, update the isRead field
                if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "isRead": true
                    ]) { error in
                        if let error = error {
                            print("Error updating notification: \(error.localizedDescription)")
                        } else {
                            print("Notification marked as read")
                        }
                    }
                }
            }
    }
    
}

struct NotificationView_Preview: PreviewProvider
    {
    static var previews: some View
        {
        NotificationView()
        }
    }
