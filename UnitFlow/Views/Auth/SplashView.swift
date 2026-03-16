import SwiftUI

struct SplashView: View {
    @Binding var isShowing: Bool
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var circleScale: CGFloat = 0
    @State private var circleOpacity: Double = 0.8
    @State private var glowOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E"), Color(hex: "#0F3460")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Background decorative circles
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(UFColors.primary.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                    .frame(width: CGFloat(200 + i * 100), height: CGFloat(200 + i * 100))
                    .scaleEffect(circleScale)
                    .opacity(circleOpacity)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double(i) * 0.15), value: circleScale)
            }
            
            // Glow
            Circle()
                .fill(UFColors.primary.opacity(0.3))
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .opacity(glowOpacity)
            
            VStack(spacing: 20) {
                Spacer()
                
                // Logo Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(UFColors.gradientOrange)
                        .frame(width: 100, height: 100)
                        .shadow(color: UFColors.primary.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App Name
                VStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Text("Unit")
                            .font(UFFont.display(36))
                            .foregroundColor(.white)
                        Text("Flow")
                            .font(UFFont.display(36))
                            .foregroundColor(UFColors.primary)
                    }
                    
                    Text("Control your job site in one place")
                        .font(UFFont.caption(15))
                        .foregroundColor(Color.white.opacity(0.6))
                        .opacity(taglineOpacity)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
                
                Spacer()
                
                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(UFColors.primary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(textOpacity > 0.5 ? 1 : 0.5)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: textOpacity)
                    }
                }
                .opacity(textOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
                circleScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                glowOpacity = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                textOpacity = 1.0
                textOffset = 0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
                taglineOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isShowing = false
                }
            }
        }
    }
}
