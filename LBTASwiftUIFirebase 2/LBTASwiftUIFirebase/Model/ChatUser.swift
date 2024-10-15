//
//  ChatUser.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 07/10/2024.
//

import Foundation

struct ChatUser: Identifiable {
    var id: String { uid }

    let uid: String
    let email: String
    let profileImageUrl: String
    var blockedUsers: [String]

    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.blockedUsers = data["blockedUsers"] as? [String] ?? []
    }
}
