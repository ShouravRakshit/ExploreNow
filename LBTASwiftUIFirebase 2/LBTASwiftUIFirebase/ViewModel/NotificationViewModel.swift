//
//  NotificationViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-12-08.
//
import SwiftUI

// ViewModel to manage notification users
class NotificationViewModel: ObservableObject {
    @Published var notificationUsers      : [NotificationUser] = []
    @Published var unreadNotificationUsers: [NotificationUser] = []
    @Published var restNotificationUsers  : [NotificationUser] = []
    private var userManager: UserManager  // Store userManager
    
    // Custom initializer to inject userManager
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func resetNotificationUsers() {
        self.notificationUsers = [] // Reset the list
    }
    
    func populateNotificationUsers2() {
        resetNotificationUsers()
        //print("After resetting notification users count:  \(notificationUsers.count)")
        if let notifications = userManager.currentUser?.notifications {
            NotificationManager.shared.populateNotificationUsers(notifications: notifications) { result in
                switch result {
                case .success(let notificationUsers):
                    
                    for notificationUser in notificationUsers {
                        self.notificationUsers.append(notificationUser)
                        print("populateNotificationUsers: \(notificationUser.notification.message)")
                    }
                    
                    self.notificationUsers = notificationUsers
                    self.notificationUsers.sort { $0.notification.timestamp.dateValue() > $1.notification.timestamp.dateValue() }
                    // Split the notificationUsers array into unread and rest notifications
                    self.unreadNotificationUsers = notificationUsers.filter { !$0.notification.isRead }
                    self.restNotificationUsers = notificationUsers.filter { $0.notification.isRead }
                    
                    
                    print("Notification view After sorting final:")
                    
                    
                    // Loop through each notification user and print their full_message
                    for user in notificationUsers
                        {
                        print("User Full Message: \(user.full_message ?? "No message") timestamp: \(user.notification.timestamp.dateValue())")
                        }
                case .failure(let error):
                    print("Failed to fetch notification users: \(error.localizedDescription)")
                }
            }
        }
        
    }
    
    func populateNotificationUsers(notifications: [Notification]) {
        resetNotificationUsers()
        //print("After resetting notification users count:  \(notificationUsers.count)")
        NotificationManager.shared.populateNotificationUsers(notifications: notifications) { result in
            switch result {
            case .success(let notificationUsers):
                
                for notificationUser in notificationUsers {
                    self.notificationUsers.append(notificationUser)
                    print("populateNotificationUsers: \(notificationUser.notification.message)")
                }
                
                self.notificationUsers = notificationUsers
                self.notificationUsers.sort { $0.notification.timestamp.dateValue() > $1.notification.timestamp.dateValue() }
                // Split the notificationUsers array into unread and rest notifications
                self.unreadNotificationUsers = notificationUsers.filter { !$0.notification.isRead }
                self.restNotificationUsers = notificationUsers.filter { $0.notification.isRead }
                
                
                print("Notification view After sorting final:")
                
                
                // Loop through each notification user and print their full_message
                for user in notificationUsers
                    {
                    print("User Full Message: \(user.full_message ?? "No message") timestamp: \(user.notification.timestamp.dateValue())")
                    }
            case .failure(let error):
                print("Failed to fetch notification users: \(error.localizedDescription)")
            }
        }
        
    }
    

}
