import Foundation

class UserDefaultsHelper {
    private let userIdKey = "com.travelbuddy.user.id"
    private let userEmailKey = "com.travelbuddy.user.email"
    private let userNameKey = "com.travelbuddy.user.name"
    private let userPreferencesKey = "com.travelbuddy.user.preferences"
    
    func saveUserInfo(id: String, email: String, name: String) {
        UserDefaults.standard.set(id, forKey: userIdKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
        UserDefaults.standard.set(name, forKey: userNameKey)
    }
    
    func getUserInfo() -> (id: String, email: String, name: String)? {
        guard let id = UserDefaults.standard.string(forKey: userIdKey),
              let email = UserDefaults.standard.string(forKey: userEmailKey),
              let name = UserDefaults.standard.string(forKey: userNameKey) else {
            return nil
        }
        return (id, email, name)
    }
    
    func clearUserInfo() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
    }
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        if let encodedData = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encodedData, forKey: userPreferencesKey)
        }
    }
    
    func getUserPreferences() -> UserPreferences? {
        guard let data = UserDefaults.standard.data(forKey: userPreferencesKey) else {
            return nil
        }
        return try? JSONDecoder().decode(UserPreferences.self, from: data)
    }
    
    func clearUserPreferences() {
        UserDefaults.standard.removeObject(forKey: userPreferencesKey)
    }
}
