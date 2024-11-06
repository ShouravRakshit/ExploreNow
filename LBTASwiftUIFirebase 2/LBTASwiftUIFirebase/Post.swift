//
//  Post.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-11-06.
//

import Firebase
import FirebaseFirestore

struct Post: Identifiable {
    let id: String
    let description: String
    let rating: Int
    let locationRef: DocumentReference
    let locationAddress: String
    let imageUrls: [String]
    let timestamp: Date
    let uid: String
    let username: String
    let userProfileImageUrl: String
}
