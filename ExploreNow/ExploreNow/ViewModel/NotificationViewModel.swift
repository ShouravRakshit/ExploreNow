//
//  NotificationViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI

// ViewModel to manage notification users
class NotificationViewModel: ObservableObject {
    // Published properties to allow updates in the view
    @Published var notificationUsers      : [NotificationUser] = [] // List of all notification users
    @Published var unreadNotificationUsers: [NotificationUser] = [] // List of unread notification users
    @Published var restNotificationUsers  : [NotificationUser] = [] // List of rest notification users (purpose unclear)
    private var userManager: UserManager  // Store userManager to manage user-related data
    
    // Custom initializer to inject userManager dependency
    init(userManager: UserManager) {
        self.userManager = userManager  // Assign the passed userManager to the property
    }
    
    // Function to reset the list of notification users
    func resetNotificationUsers() {
        self.notificationUsers = [] // Clear the list of notification users
    }
    
    // Function to populate the notification users list by fetching notifications
    func populateNotificationUsers2() {
        resetNotificationUsers() // Reset the list of notification users before populating it
        //print("After resetting notification users count:  \(notificationUsers.count)")
        // Check if currentUser has notifications
        if let notifications = userManager.currentUser?.notifications {
            // Call the shared NotificationManager to process notifications and populate the list
            NotificationManager.shared.populateNotificationUsers(notifications: notifications) { result in
                // Process the result of the notifications population
                switch result {
                case .success(let notificationUsers):
                    // Loop through the notification users and append them to the list
                    for notificationUser in notificationUsers {
                        self.notificationUsers.append(notificationUser)
                        // Debugging output to check each notification message being processed
                        print("populateNotificationUsers: \(notificationUser.notification.message)")
                    }
                    // Replace the notificationUsers array with the fetched list
                    self.notificationUsers = notificationUsers
                    // Sort the notification users by timestamp in descending order (newest first)
                    self.notificationUsers.sort { $0.notification.timestamp.dateValue() > $1.notification.timestamp.dateValue() }
                    
                    // Split the notificationUsers array into unread and rest notifications
                    
                    self.unreadNotificationUsers = notificationUsers.filter { !$0.notification.isRead }
                    self.restNotificationUsers = notificationUsers.filter { $0.notification.isRead }
                    
                    // Debugging output after sorting and categorizing
                    print("Notification view After sorting final:")
                    
                    
                    // Loop through each notification user and print their full_message
                    for user in notificationUsers
                        {
                        print("User Full Message: \(user.full_message ?? "No message") timestamp: \(user.notification.timestamp.dateValue())")
                        }
                case .failure(let error):
                    // Failed to fetch notification users
                    print("Failed to fetch notification users: \(error.localizedDescription)")
                }
            }
        }
        
    }
    
    // Function to populate the notificationUsers array based on provided notifications
    func populateNotificationUsers(notifications: [Notification]) {
        resetNotificationUsers() // Reset the notification users list before populating it
        
        // Call NotificationManager's method to process the notifications and return the result
        NotificationManager.shared.populateNotificationUsers(notifications: notifications) { result in
            switch result {
            case .success(let notificationUsers):
                // Loop through each notificationUser and append to the notificationUsers array
                for notificationUser in notificationUsers {
                    self.notificationUsers.append(notificationUser)
                    // Debugging: Output each notification's message to check the data being processed
                    print("populateNotificationUsers: \(notificationUser.notification.message)")
                }
                
                // Overwrite the notificationUsers array with the successfully fetched users
                self.notificationUsers = notificationUsers
                // Sort the notificationUsers array by the notification timestamp, latest first
                self.notificationUsers.sort { $0.notification.timestamp.dateValue() > $1.notification.timestamp.dateValue() }
               
                // Split the notificationUsers into two arrays: unread and read notifications
                self.unreadNotificationUsers = notificationUsers.filter { !$0.notification.isRead }
                self.restNotificationUsers = notificationUsers.filter { $0.notification.isRead }
                
                // Debugging: Output final state after sorting the notifications

                print("Notification view After sorting final:")
                
                
                // Loop through each notification user and print their full_message
                for user in notificationUsers
                    {
                    print("User Full Message: \(user.full_message ?? "No message") timestamp: \(user.notification.timestamp.dateValue())")
                    }
            case .failure(let error):
                // If fetching the notification users fails, print an error message
                print("Failed to fetch notification users: \(error.localizedDescription)")
            }
        }
        
    }
    

}
