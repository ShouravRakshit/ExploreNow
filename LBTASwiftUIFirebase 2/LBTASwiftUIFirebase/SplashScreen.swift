import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool
    
    @State private var airplaneOffset = -UIScreen.main.bounds.width
    @State private var cloudOffset = UIScreen.main.bounds.width
    @State private var cloudOffset2 = UIScreen.main.bounds.width + 100
    @State private var textOpacity = 0.0
    @State private var textOffset = 100.0
    @State private var airplaneTrailOpacity = 0.0
    @State private var flareOffset: CGFloat = 200
    @State private var cloudScale: CGFloat = 0.9
    @State private var airplaneScale: CGFloat = 1.2
    
    var body: some View {
        ZStack {
            // Gradient sky with dynamic sunrise effect
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue, Color.orange, Color.pink]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    withAnimation(Animation.linear(duration: 10.0)) {
                        flareOffset = UIScreen.main.bounds.width
                    }
                }
            
            // Sun (represented as a glowing orb)
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 120, height: 120)
                .position(x: flareOffset, y: 150)
                .shadow(color: .yellow, radius: 15, x: 0, y: 0)
            
            // Clouds moving with parallax effect (at different speeds)
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 140))
                    .foregroundColor(Color.white.opacity(0.8))
                    .offset(x: cloudOffset, y: -100)
                    .scaleEffect(cloudScale)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                            self.cloudOffset = -UIScreen.main.bounds.width
                        }
                    }
                Spacer()
            }

            HStack {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 100))
                    .foregroundColor(Color.white.opacity(0.6))
                    .offset(x: cloudOffset2, y: -150)
                    .scaleEffect(cloudScale)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 12.0).repeatForever(autoreverses: false)) {
                            self.cloudOffset2 = -UIScreen.main.bounds.width
                        }
                    }
                Spacer()
            }

            // Airplane flying beneath clouds, glowing effect with a trail
            HStack {
                Image(systemName: "airplane")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.6), radius: 10, x: 0, y: 0)
                    .offset(x: airplaneOffset, y: -120)
                    .scaleEffect(airplaneScale)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                            self.airplaneOffset = UIScreen.main.bounds.width + 100
                        }
                        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            self.airplaneScale = 1.3
                        }
                    }
                Spacer()
            }

           
            VStack {
                Spacer()
                Text("ExploreNow")
                    .font(.system(size: 45))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                    .offset(y: CGFloat(textOffset))
                    .scaleEffect(1.5)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).delay(0.5)) {
                            self.textOpacity = 1.0
                            self.textOffset = 0.0
                        }
                    }
                Spacer()
            }
        }
        .onAppear {
            // Delay to switch the view after splash animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                self.isActive = false
            }
        }
    }
}
