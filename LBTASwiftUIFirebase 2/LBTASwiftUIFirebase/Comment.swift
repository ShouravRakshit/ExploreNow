//
//  Comment.swift
//  LBTASwiftUIFirebase
//
//  Created by Manvi Juneja on 2024-11-10.
//

import Firebase
import FirebaseFirestore

struct Comment: Identifiable, Decodable {
    var id: String
    let postID: String
    let userID: String
    let text: String
    let timestamp: Date
}

extension Comment {
    // Custom initializer to decode data from Firestore
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        guard let id = document.documentID as String?,
              let postID = data["pid"] as? String,
              let userID = data["uid"] as? String,
              let text = data["comment"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else { return nil }
        
        self.id = id
        self.postID = postID
        self.userID = userID
        self.text = text
        self.timestamp = timestamp.dateValue() // Convert Timestamp to Date
    }
}

