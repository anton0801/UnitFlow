import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    @AppStorage("savedEmail") private var savedEmail: String = ""
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    private let usersKey = "unitflow_users"
    private let currentUserKey = "unitflow_current_user"
    
    init() {
        loadCurrentUser()
    }
    
    private func loadCurrentUser() {
        if isLoggedIn, let data = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            showError(message: "Please fill in all fields")
            return
        }
        guard email.contains("@") else {
            showError(message: "Please enter a valid email address")
            return
        }
        guard password.count >= 6 else {
            showError(message: "Password must be at least 6 characters")
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            
            // Check stored users
            let users = self.getStoredUsers()
            if let user = users.first(where: { $0.email.lowercased() == email.lowercased() }) {
                self.setCurrentUser(user)
            } else if email.lowercased() == "demo@unitflow.com" && password == "demo123" {
                // Demo account
                let demoUser = User(fullName: "Alex Johnson", companyName: "BuildRight Co.", email: email, role: .foreman)
                self.saveUser(demoUser)
                self.setCurrentUser(demoUser)
            } else {
                self.showError(message: "Invalid credentials. Try demo@unitflow.com / demo123")
            }
        }
    }
    
    func signUp(fullName: String, companyName: String, email: String, password: String, confirmPassword: String, role: User.UserRole) {
        guard !fullName.isEmpty, !companyName.isEmpty, !email.isEmpty, !password.isEmpty else {
            showError(message: "Please fill in all fields")
            return
        }
        guard email.contains("@") else {
            showError(message: "Please enter a valid email address")
            return
        }
        guard password.count >= 6 else {
            showError(message: "Password must be at least 6 characters")
            return
        }
        guard password == confirmPassword else {
            showError(message: "Passwords do not match")
            return
        }
        
        let users = getStoredUsers()
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            showError(message: "An account with this email already exists")
            return
        }
        
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            let newUser = User(fullName: fullName, companyName: companyName, email: email, role: role)
            self.saveUser(newUser)
            self.setCurrentUser(newUser)
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }

    func deleteAccount() {
        guard let user = currentUser else { return }
        var users = getStoredUsers()
        users.removeAll { $0.id == user.id }
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
        signOut()
    }
    
    func updateProfile(fullName: String, companyName: String, role: User.UserRole) {
        guard var user = currentUser else { return }
        user.fullName = fullName
        user.companyName = companyName
        user.role = role
        setCurrentUser(user)
        saveUser(user)
    }
    
    private func setCurrentUser(_ user: User) {
        currentUser = user
        isAuthenticated = true
        isLoggedIn = true
        savedEmail = user.email
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: currentUserKey)
        }
    }
    
    private func saveUser(_ user: User) {
        var users = getStoredUsers()
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx] = user
        } else {
            users.append(user)
        }
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    private func getStoredUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else { return [] }
        return users
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
