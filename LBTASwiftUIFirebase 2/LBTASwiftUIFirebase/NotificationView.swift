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
            Text ("No New Notifications")
            
            Spacer() // Pushes content to the top
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
