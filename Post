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
    var commentCount: Int = 0  // Default value, can be updated later
    var likesCount: Int = 0  // Default value
    var likedByUserIds: [String] = []  // Default to an empty array
    var liked: Bool = false // initialized to false
}

