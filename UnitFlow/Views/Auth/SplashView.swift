import SwiftUI
import Combine

struct SplashView: View {
    
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var circleScale: CGFloat = 0
    @State private var circleOpacity: Double = 0.8
    @State private var glowOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    @StateObject private var container = UnitFlowContainer()
    @State private var timeoutTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E"), Color(hex: "#0F3460")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image( "loading_screen")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .opacity(0.75)
                        .blur(radius: 4)
                }
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
                        
                        Text("Control your building in one place")
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
                
                NavigationLink(
                    destination: UnitWebView()
                        .preferredColorScheme(.dark)
                        .navigationBarBackButtonHidden(),
                    isActive: $container.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(),
                    isActive: $container.navigateToMain
                ) { EmptyView() }
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
                
                    startApplication()
            }
            .fullScreenCover(isPresented: $container.showPermissionPrompt) {
                UnitNotificationView(useCase: container.application)
            }
            .fullScreenCover(isPresented: $container.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func startApplication() {
        container.application.initialize()
        
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await MainActor.run {
                container.application.handleTimeout()
            }
        }
    }
}

@MainActor
final class UnitFlowContainer: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    let application: UnitFlowApplication
    let eventPublisher: UIEventPublisher
    let networkMonitor: NetworkMonitorAdapter
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = DiskStorageAdapter()
        let validation = FirebaseValidationAdapter()
        let network = HTTPNetworkAdapter()
        let notification = SystemNotificationAdapter()
        let events = UIEventPublisher()
        
        self.eventPublisher = events
        
        self.application = UnitFlowApplication(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification,
            events: events
        )
        
        // 3. Create network monitor
        self.networkMonitor = NetworkMonitorAdapter(useCase: application)
        
        events.$showPermissionPrompt
            .sink { [weak self] value in
                self?.showPermissionPrompt = value
            }
            .store(in: &cancellables)
        
        events.$showOfflineView
            .sink { [weak self] value in
                self?.showOfflineView = value
            }
            .store(in: &cancellables)
        
        events.$navigateToMain
            .sink { [weak self] value in
                self?.navigateToMain = value
            }
            .store(in: &cancellables)
        
        events.$navigateToWeb
            .sink { [weak self] value in
                self?.navigateToWeb = value
            }
            .store(in: &cancellables)
        
        // 5. Setup external event streams
        setupStreams()
        
        // 6. Start network monitoring
        networkMonitor.start()
    }
    
    private func setupStreams() {
        // AppsFlyer tracking data
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.application.handleTracking(data)
            }
            .store(in: &cancellables)
        
        // Deeplink navigation data
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.application.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
}

struct UnitNotificationView: View {
    let useCase: ApplicationUseCase
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "notif_screen_bg_land" : "notif_screen_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("BowlbyOne-Regular", size: 21))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("BowlbyOne-Regular", size: 14))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                useCase.requestPermission()
            } label: {
                Image("notif_screen_accept")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                useCase.deferPermission()
            } label: {
                Image("notif_screen_skip")
                    .resizable()
                    .frame(width: 280, height: 40)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(geometry.size.width > geometry.size.height ? "wifi_screen_land" : "wifi_screen")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                
                Image("wifi_screen_content")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}
