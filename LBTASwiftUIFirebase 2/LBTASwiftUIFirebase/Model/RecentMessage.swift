//
//  RecentMessage.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore

struct RecentMessage: Identifiable {
    var id: String { documentId }

    let documentId: String
    let text: String
    let fromId: String
    let toId: String
    let timestamp: Timestamp
    let email: String
    var profileImageUrl: String
    var name: String?

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.text = data[FirebaseConstants.text] as? String ?? ""
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
        self.email = data[FirebaseConstants.email] as? String ?? ""
        self.profileImageUrl = data[FirebaseConstants.profileImageUrl] as? String ?? ""
    }
}
