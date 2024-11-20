//
//  SplashScreen.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-09.
//
//


import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool

    @State private var airplaneOffset = -UIScreen.main.bounds.width
    @State private var cloudOffset = UIScreen.main.bounds.width

    var body: some View {
        ZStack {
//            LinearGradient(gradient: Gradient(colors: [Color.customPurple, Color(UIColor(hex: "#483D8B") ?? .purple)]), startPoint: .bottom, endPoint: .top)
//                            .edgesIgnoringSafeArea(.all)


            RadialGradient(gradient: Gradient(colors: [Color.customPurple, Color(UIColor(hex: "#4B0082")?.withAlphaComponent(0.8) ?? .purple)]), center: .center, startRadius: 50, endRadius: UIScreen.main.bounds.height)
                            .edgesIgnoringSafeArea(.all)

            
            Image(systemName: "airplane")
                .font(.system(size: 100))
                .foregroundColor(.white)
                .offset(x: airplaneOffset, y: -100)
                .onAppear {
                    withAnimation(Animation.linear(duration: 5.0)) {
                        self.airplaneOffset = UIScreen.main.bounds.width
                    }
                }

            Image(systemName: "cloud.fill")
                .font(.system(size: 100))
                .foregroundColor(.white)
                .offset(x: cloudOffset, y: 50)
                .onAppear {
                    withAnimation(Animation.linear(duration: 5.0)) {
                        self.cloudOffset = -UIScreen.main.bounds.width
                    }
                }

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 150))
                .foregroundColor(.yellow)
                .offset(x: 100, y: -UIScreen.main.bounds.height / 3)

            VStack {
                Spacer()
                Text("ExploreNow")
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 100)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.isActive = false
            }
        }
    }
}
