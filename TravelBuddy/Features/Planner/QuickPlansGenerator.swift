import Foundation
import CoreLocation

struct QuickPlanDBPlace {
    let category: String
    let name: String
    let district: String
    let description: String
    let rating: Double
    let imageURLString: String?
    let coordinate: CLLocationCoordinate2D
}

class QuickPlansGenerator {
    static func generatePlans(from selectedActivities: [ActivityCategory], categorizedPlaces: [QuickPlanDBPlace]) -> [QuickPlanItem] {
        guard !categorizedPlaces.isEmpty else { return [] }

        let selectedCategoryIds = selectedActivities.map(\.id)
        let preferredCategories = selectedCategoryIds.compactMap { dbCategoryValue(for: $0) }
        let availableCategories = Array(Set(categorizedPlaces.map(\.category))).sorted()

        let orderedCategories = (preferredCategories + availableCategories)
            .reduce(into: [String]()) { result, category in
                if !result.contains(category) {
                    result.append(category)
                }
            }

        var plans: [QuickPlanItem] = []
        for category in orderedCategories.prefix(3) {
            let places = categorizedPlaces
                .filter { $0.category == category }
                .sorted { $0.rating > $1.rating }

            guard !places.isEmpty else { continue }
            plans.append(buildPlan(for: category, from: places))
        }

        return plans
    }

    private static func buildPlan(for category: String, from places: [QuickPlanDBPlace]) -> QuickPlanItem {
        let selectedStops = Array(places.prefix(3))
        let metadata = metadataForCategory(category)

        let itinerary = selectedStops.enumerated().map { index, place in
            ItineraryStop(
                day: index + 1,
                title: place.name,
                description: place.description,
                coordinate: place.coordinate,
                icon: metadata.icon,
                imageURLString: place.imageURLString
            )
        }

        let districts = Array(Set(selectedStops.map(\.district))).sorted()
        let districtText = districts.isEmpty ? "your selected area" : districts.joined(separator: ", ")

        return QuickPlanItem(
            title: metadata.title,
            subtitle: "Built from your manual planner places",
            icon: metadata.icon,
            duration: "\(max(1, itinerary.count)) Days",
            description: "This itinerary is generated only from your database locations in \(districtText).",
            itinerary: itinerary,
            category: metadata.categoryLabel
        )
    }

    private static func dbCategoryValue(for activityId: String) -> String? {
        switch activityId {
        case "must-visit": return "must_visit"
        case "hiking": return "hiking"
        case "camping": return "camping"
        case "rafting": return "rafting"
        case "trail-tracking": return "trail_tracking"
        case "foods": return "food"
        case "culture": return "culture"
        case "history": return "history"
        case "bungie": return "bungee"
        case "hidden-gems": return "hidden_gems"
        default: return nil
        }
    }

    private static func metadataForCategory(_ category: String) -> (title: String, icon: String, categoryLabel: String) {
        switch category {
        case "must_visit": return ("3 Days Must Visit Highlights", "flag.fill", "must_visit")
        case "hiking": return ("3 Days Hiking Adventure", "figure.hiking", "hiking")
        case "camping": return ("3 Days Camping Escape", "tent.fill", "camping")
        case "rafting": return ("3 Days River Adventure", "water.waves", "rafting")
        case "trail_tracking": return ("3 Days Trail Discovery", "location.viewfinder", "trail_tracking")
        case "food": return ("3 Days Food Journey", "fork.knife", "food")
        case "culture": return ("3 Days Cultural Journey", "building.columns.fill", "culture")
        case "history": return ("3 Days Historic Journey", "hourglass", "history")
        case "bungee": return ("3 Days Adrenaline Rush", "figure.fall", "bungee")
        case "hidden_gems": return ("3 Days Hidden Gems", "star.fill", "hidden_gems")
        default: return ("3 Days Discovery", "map", category)
        }
    }
}
