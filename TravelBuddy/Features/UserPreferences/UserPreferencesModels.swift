import Foundation

// MARK: - Activity Category Model
struct ActivityCategory: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let icon: String
    let emoji: String
    
    static let allCategories: [ActivityCategory] = [
        ActivityCategory(id: "must-visit", name: "Must visit", icon: "flag.fill", emoji: "🚩"),
        ActivityCategory(id: "hiking", name: "Hiking", icon: "figure.hiking", emoji: "🥾"),
        ActivityCategory(id: "camping", name: "Camping", icon: "tent.fill", emoji: "⛺"),
        ActivityCategory(id: "rafting", name: "Rafting", icon: "water.waves", emoji: "🚣"),
        ActivityCategory(id: "trail-tracking", name: "Trail tracking", icon: "location.circle.fill", emoji: "🗺️"),
        ActivityCategory(id: "foods", name: "Foods", icon: "fork.knife", emoji: "🍽️"),
        ActivityCategory(id: "culture", name: "Culture", icon: "book.fill", emoji: "📚"),
        ActivityCategory(id: "history", name: "History", icon: "hourglass", emoji: "⏳"),
        ActivityCategory(id: "bungie", name: "Bungie", icon: "figure.fall", emoji: "🎢"),
        ActivityCategory(id: "hidden-gems", name: "Hide gems", icon: "star.fill", emoji: "✨")
    ]
}

// MARK: - User Preferences Model
struct UserPreferences: Codable {
    var selectedActivityIds: [String] = []
    var completedPreferencesSetup: Bool = false
    var lastUpdatedAt: Date = Date()
    
    var selectedActivities: [ActivityCategory] {
        ActivityCategory.allCategories.filter { selectedActivityIds.contains($0.id) }
    }
    
    var isValid: Bool {
        selectedActivityIds.count == 4
    }
    
    mutating func toggleActivity(_ activity: ActivityCategory) {
        if selectedActivityIds.contains(activity.id) {
            selectedActivityIds.removeAll { $0 == activity.id }
        } else {
            if selectedActivityIds.count < 4 {
                selectedActivityIds.append(activity.id)
            }
        }
    }
    
    mutating func resetActivities() {
        selectedActivityIds = []
    }
}
