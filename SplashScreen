import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool
    
    @State private var airplaneOffset = -UIScreen.main.bounds.width
    @State private var cloudOffset = UIScreen.main.bounds.width
    @State private var cloudOffset2 = UIScreen.main.bounds.width + 100
    @State private var textOpacity = 0.0
    @State private var textOffset = 400.0
    @State private var airplaneScale: CGFloat = 1.2
    @State private var flareOffset: CGFloat = 200
    @State private var cloudScale: CGFloat = 0.9
    
    @State private var destination1: CGPoint = CGPoint(x: 150, y: 400)
    @State private var destination2: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 150, y: 400)
    
    var body: some View {
        ZStack {
            // Dynamic Gradient Sky with subtle animation for day-to-night effect
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.orange, Color.pink, Color.purple]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
                .animation(.linear(duration: 15).repeatForever(autoreverses: false), value: textOpacity)
            
            // Glowing Sun with subtle animation
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 120, height: 120)
                .position(x: flareOffset, y: 200)
                .shadow(color: .yellow, radius: 15, x: 0, y: 0)
                .scaleEffect(1.2)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 12).delay(1)) {
                        flareOffset = UIScreen.main.bounds.width * 0.5
                    }
                }

            // Clouds with varying speeds and more movement
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 180))
                    .foregroundColor(Color.white.opacity(0.6))
                    .offset(x: cloudOffset, y: -150)
                    .scaleEffect(cloudScale)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 20.0).repeatForever(autoreverses: false)) {
                            self.cloudOffset = -UIScreen.main.bounds.width
                        }
                    }
                Spacer()
            }

            HStack {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 140))
                    .foregroundColor(Color.white.opacity(0.5))
                    .offset(x: cloudOffset2, y: -130)
                    .scaleEffect(cloudScale)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 22.0).repeatForever(autoreverses: false)) {
                            self.cloudOffset2 = -UIScreen.main.bounds.width
                        }
                    }
                Spacer()
            }
            
            // Flight Path with enhanced dashed line and glowing effect
            Path { path in
                path.move(to: destination1)
                path.addLine(to: destination2)
            }
            .stroke(style: StrokeStyle(lineWidth: 3, dash: [5, 10]))
            .foregroundColor(.white.opacity(0.6))
            .blur(radius: 2)
            
            // Airplane flying with more intricate flight path
            Image(systemName: "airplane")
                .font(.system(size: 120))
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.6), radius: 10, x: 0, y: 0)
                .offset(x: airplaneOffset, y: -120)
                .scaleEffect(airplaneScale)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: false)) {
                        self.airplaneOffset = destination2.x + 100
                    }
                    withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        self.airplaneScale = 1.5
                    }
                }
            
            // Destination Markers with cool glowing effect
            VStack {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.yellow)
                        .opacity(0.8)
                        .position(x: destination1.x, y: destination1.y)
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.yellow)
                        .opacity(0.8)
                        .position(x: destination2.x, y: destination2.y)
                }
            }

            // Text with smooth fade-in effect and some bounce for added coolness
            VStack {
                Spacer()
                Text("ExploreNow")
                    .font(.system(size: 45)) // Smaller font size
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                    .offset(y: CGFloat(textOffset))
                    .scaleEffect(1.5)
                    .animation(Animation.easeOut(duration: 1.5).delay(0.5), value: textOpacity)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1).delay(0.5)) {
                            self.textOpacity = 1.0
                            self.textOffset = 50.0
                        }
                    }
                Spacer()
            }

        }
        .onAppear {
            // Switch to next view after splash screen animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                self.isActive = false
            }
        }
    }
}
