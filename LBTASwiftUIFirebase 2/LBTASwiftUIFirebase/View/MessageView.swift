//
//  MessageView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import SwiftUI
import Firebase

struct MessageView: View {
    let message: ChatMessage
    let onDelete: (String) -> Void // Closure to handle deletion

    var body: some View {
        HStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(message.text)
                                .foregroundColor(.white)
                                .font(.body)

                            // Timestamp inside the bubble
                            Text(formatTimestamp(message.timestamp.dateValue()))
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption2)
                        }

                        // Delete button for the message
                        Button(action: {
                            onDelete(message.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.text)
                            .foregroundColor(.black)
                            .font(.body)

                        // Timestamp inside the bubble
                        Text(formatTimestamp(message.timestamp.dateValue()))
                            .foregroundColor(.gray)
                            .font(.caption2)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                Spacer()
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

