import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: ApplicationMainState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Your Job Site,\nUnder Control",
            subtitle: "Manage all your construction projects from one powerful mobile command center.",
            icon: "building.2.crop.circle.fill",
            accentIcon: "map.fill",
            color: UFColors.primary,
            gradient: [Color(hex: "#FF6B35"), Color(hex: "#FF8C42")]
        ),
        OnboardingPage(
            title: "Track Every\nStage & Zone",
            subtitle: "Break your project into stages and zones. Update progress in seconds, right from the field.",
            icon: "chart.bar.fill",
            accentIcon: "checkmark.seal.fill",
            color: Color(hex: "#06D6A0"),
            gradient: [Color(hex: "#06D6A0"), Color(hex: "#04B87A")]
        ),
        OnboardingPage(
            title: "Issues &\nTeam Visibility",
            subtitle: "Log problems with photos, assign workers, and get real-time alerts before things escalate.",
            icon: "person.3.fill",
            accentIcon: "exclamationmark.triangle.fill",
            color: Color(hex: "#118AB2"),
            gradient: [Color(hex: "#118AB2"), Color(hex: "#0A6E8A")]
        ),
        OnboardingPage(
            title: "Daily Reports\nin 60 Seconds",
            subtitle: "Document progress, weather, workers and materials. Share client summaries with one tap.",
            icon: "doc.text.fill",
            accentIcon: "camera.fill",
            color: Color(hex: "#FFD166"),
            gradient: [Color(hex: "#FFD166"), Color(hex: "#FFC233")]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(UFFont.caption(15))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 50)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? pages[currentPage].color : Color.white.opacity(0.3))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // CTA Button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            appState.hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(UFFont.headline(17))
                            .foregroundColor(.white)
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(colors: pages[currentPage].gradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: pages[currentPage].color.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .scaleEffect(1.0)
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accentIcon: String
    let color: Color
    let gradient: [Color]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -15
    @State private var contentOffset: CGFloat = 30
    @State private var contentOpacity: Double = 0
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 220, height: 220)
                
                Circle()
                    .fill(page.color.opacity(0.08))
                    .frame(width: 160, height: 160)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                    .offset(y: floatOffset)
                
                // Accent icon
                Image(systemName: page.accentIcon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
                    .shadow(color: page.color.opacity(0.5), radius: 8, x: 0, y: 4)
                    .offset(x: 70, y: -60)
                    .scaleEffect(iconScale)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(UFFont.display(32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text(page.subtitle)
                    .font(UFFont.body(16))
                    .foregroundColor(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
            }
            .offset(y: contentOffset)
            .opacity(contentOpacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconRotation = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentOffset = 0
                contentOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.8)) {
                floatOffset = -12
            }
        }
    }
}
