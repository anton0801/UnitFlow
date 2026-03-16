import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field { case email, password }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(UFColors.gradientOrange)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: UFColors.primary.opacity(0.4), radius: 16, x: 0, y: 8)
                                Image(systemName: "building.2.crop.circle.fill")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 60)
                            
                            VStack(spacing: 6) {
                                HStack(spacing: 2) {
                                    Text("Unit").font(UFFont.display(30)).foregroundColor(.white)
                                    Text("Flow").font(UFFont.display(30)).foregroundColor(UFColors.primary)
                                }
                                Text("Sign in to your account")
                                    .font(UFFont.body(15))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                        .padding(.bottom, 48)
                        
                        // Form
                        VStack(spacing: 16) {
                            UFTextField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboardType: .emailAddress)
                                .focused($focusedField, equals: .email)
                            
                            UFSecureField(icon: "lock.fill", placeholder: "Password", text: $password, showPassword: $showPassword)
                                .focused($focusedField, equals: .password)
                        }
                        .padding(.horizontal, 24)
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(UFFont.caption(14))
                            .foregroundColor(UFColors.primary)
                            .padding(.top, 12)
                            .padding(.trailing, 24)
                        }
                        
                        VStack(spacing: 14) {
                            // Sign In Button
                            Button {
                                focusedField = nil
                                authVM.signIn(email: email, password: password)
                            } label: {
                                ZStack {
                                    if authVM.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .font(UFFont.headline(17))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(UFColors.gradientOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: UFColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(authVM.isLoading)
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Divider
//                            HStack {
//                                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
//                                Text("or").font(UFFont.caption(13)).foregroundColor(.white.opacity(0.4)).padding(.horizontal, 12)
//                                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
//                            }
                            
                            // Sign in with Apple
//                            Button {
//                                // Apple Sign In would use AuthenticationServices in production
//                                authVM.signIn(email: "apple@unitflow.com", password: "apple_user")
//                            } label: {
//                                HStack(spacing: 10) {
//                                    Image(systemName: "applelogo")
//                                        .font(.system(size: 18, weight: .semibold))
//                                    Text("Sign in with Apple")
//                                        .font(UFFont.headline(16))
//                                }
//                                .foregroundColor(.black)
//                                .frame(maxWidth: .infinity)
//                                .frame(height: 54)
//                                .background(Color.white)
//                                .clipShape(RoundedRectangle(cornerRadius: 16))
//                            }
//                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Create Account
                        HStack(spacing: 6) {
                            Text("Don't have an account?")
                                .font(UFFont.body(15))
                                .foregroundColor(.white.opacity(0.55))
                            Button("Create Account") {
                                showSignUp = true
                            }
                            .font(UFFont.headline(15))
                            .foregroundColor(UFColors.primary)
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                        
                        // Demo hint
                        Text("Demo: demo@unitflow.com / demo123")
                            .font(UFFont.caption(12))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .alert("Error", isPresented: $authVM.showError) {
            Button("OK") { authVM.showError = false }
        } message: {
            Text(authVM.errorMessage ?? "An error occurred")
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fullName = ""
    @State private var companyName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var role: User.UserRole = .foreman
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A1A2E").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(UFFont.display(28))
                                .foregroundColor(.white)
                            Text("Join UnitFlow to manage your sites")
                                .font(UFFont.body(15))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        
                        VStack(spacing: 14) {
                            UFTextField(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                            UFTextField(icon: "building.2.fill", placeholder: "Company Name", text: $companyName)
                            UFTextField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboardType: .emailAddress)
                            UFSecureField(icon: "lock.fill", placeholder: "Password", text: $password, showPassword: $showPassword)
                            UFSecureField(icon: "lock.shield.fill", placeholder: "Confirm Password", text: $confirmPassword, showPassword: $showConfirmPassword)
                            
                            // Role Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Role")
                                    .font(UFFont.caption(13))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(User.UserRole.allCases, id: \.self) { r in
                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    role = r
                                                }
                                            } label: {
                                                Text(r.rawValue)
                                                    .font(UFFont.caption(14))
                                                    .foregroundColor(role == r ? .white : .white.opacity(0.6))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(role == r ? UFColors.primary : Color.white.opacity(0.1))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Button {
                            authVM.signUp(fullName: fullName, companyName: companyName, email: email, password: password, confirmPassword: confirmPassword, role: role)
                        } label: {
                            ZStack {
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                        .font(UFFont.headline(17))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(UFColors.gradientOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: UFColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(authVM.isLoading)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(UFColors.primary)
                }
            }
        }
        .alert("Error", isPresented: $authVM.showError) {
            Button("OK") { authVM.showError = false }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
        .onChange(of: authVM.isAuthenticated) { isAuth in
            if isAuth { presentationMode.wrappedValue.dismiss() }
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var sent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A1A2E").ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(UFColors.gradientOrange)
                        .padding(.top, 40)
                    
                    VStack(spacing: 10) {
                        Text("Reset Password")
                            .font(UFFont.display(26))
                            .foregroundColor(.white)
                        Text("Enter your email to receive a reset link")
                            .font(UFFont.body(15))
                            .foregroundColor(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    
                    if sent {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(UFColors.success)
                                .font(.system(size: 22))
                            Text("Reset link sent to \(email)")
                                .font(UFFont.caption(15))
                                .foregroundColor(UFColors.success)
                        }
                        .padding(16)
                        .background(UFColors.success.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                    } else {
                        UFTextField(icon: "envelope.fill", placeholder: "Email address", text: $email, keyboardType: .emailAddress)
                            .padding(.horizontal, 24)
                        
                        Button {
                            guard email.contains("@") else { return }
                            withAnimation { sent = true }
                        } label: {
                            Text("Send Reset Link")
                                .font(UFFont.headline(17))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(UFColors.gradientOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(UFColors.primary)
                }
            }
        }
    }
}
