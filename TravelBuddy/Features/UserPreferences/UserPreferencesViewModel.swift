import Foundation
import Combine

@MainActor
final class UserPreferencesViewModel: ObservableObject {
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaultsHelper = UserDefaultsHelper()
    
    init() {
        loadUserPreferences()
    }
    
    func loadUserPreferences() {
        if let savedPrefs = userDefaultsHelper.getUserPreferences() {
            self.userPreferences = savedPrefs
        }
    }
    
    func toggleActivitySelection(_ activity: ActivityCategory) {
        userPreferences.toggleActivity(activity)
    }
    
    func isActivitySelected(_ activityId: String) -> Bool {
        userPreferences.selectedActivityIds.contains(activityId)
    }
    
    func getSelectedCount() -> Int {
        userPreferences.selectedActivityIds.count
    }
    
    func savePreferences() async throws {
        isLoading = true
        defer { isLoading = false }
        
        userPreferences.completedPreferencesSetup = true
        userPreferences.lastUpdatedAt = Date()
        
        // Save to UserDefaults
        userDefaultsHelper.saveUserPreferences(userPreferences)
        
        // TODO: You can also save to Supabase if needed
        // try await savePreferencesToSupabase(userPreferences)
    }
    
    func skipPreferenceSetup() async throws {
        isLoading = true
        defer { isLoading = false }
        
        userPreferences.completedPreferencesSetup = true
        userPreferences.lastUpdatedAt = Date()
        
        // Save to UserDefaults even if user skips
        userDefaultsHelper.saveUserPreferences(userPreferences)
    }
    
    func resetPreferences() {
        userPreferences.resetActivities()
    }
}
