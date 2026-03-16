import SwiftUI

// MARK: - Custom Text Field
struct UFTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(UFColors.primary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(UFFont.body(15))
                .foregroundColor(.primary)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .disableAutocorrection(keyboardType == .emailAddress)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Secure Field
struct UFSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(UFColors.primary)
                .frame(width: 20)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .font(UFFont.body(15))
                    .foregroundColor(.primary)
            } else {
                SecureField(placeholder, text: $text)
                    .font(UFFont.body(15))
                    .foregroundColor(.primary)
            }
            
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Card
struct UFCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    var padding: CGFloat = 16
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(colorScheme == .dark ? Color(hex: "#2A2A3E") : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let color: Color
    var small: Bool = false
    
    var body: some View {
        Text(text)
            .font(UFFont.caption(small ? 10 : 11))
            .foregroundColor(color)
            .padding(.horizontal, small ? 8 : 10)
            .padding(.vertical, small ? 3 : 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Section Header
struct UFSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(UFFont.headline(17))
                .foregroundColor(.primary)
            Spacer()
            if let action = action {
                Button(actionTitle, action: action)
                    .font(UFFont.caption(14))
                    .foregroundColor(UFColors.primary)
            }
        }
    }
}

// MARK: - Progress Bar
struct UFProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var color: Color = UFColors.primary
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * min(progress / 100, 1.0), height: height)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Empty State View
struct UFEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(UFColors.primary.opacity(0.5))
            
            VStack(spacing: 6) {
                Text(title)
                    .font(UFFont.headline(17))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(UFFont.body(14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(UFFont.headline(15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(UFColors.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Dismissible Sheet Header
struct SheetHeader: View {
    let title: String
    var onDismiss: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        HStack {
            Text(title)
                .font(UFFont.headline(18))
                .foregroundColor(.primary)
            Spacer()
            Button {
                if let dismiss = onDismiss { dismiss() }
                else { presentationMode.wrappedValue.dismiss() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Toast / Confirmation View
struct ConfirmationToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(UFColors.success)
                .font(.system(size: 18))
            Text(message)
                .font(UFFont.caption(14))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Date Formatter
extension DateFormatter {
    static let ufDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    static let ufTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
    
    static let ufShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
    
    static let ufFull: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}

// MARK: - View Extensions
extension View {
    func ufNavigationStyle() -> some View {
        self
    }
}

// MARK: - Gradient Background
struct AppBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if colorScheme == .dark {
                Color(hex: "#0F0F1A").ignoresSafeArea()
            } else {
                Color(hex: "#F5F4F1").ignoresSafeArea()
            }
        }
    }
}
