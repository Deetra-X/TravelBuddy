import Foundation
import CoreLocation

class QuickPlansGenerator {
    static func generatePlans(from selectedActivities: [ActivityCategory]) -> [QuickPlanItem] {
        let activityIds = selectedActivities.map { $0.id }
        
        var plans: [QuickPlanItem] = []
        
        // Plan 1: Adventure focused
        plans.append(generateAdventurePlan(activityIds: activityIds))
        
        // Plan 2: Cultural & Experience focused
        plans.append(generateCulturalPlan(activityIds: activityIds))
        
        // Plan 3: Nature & Relaxation focused
        plans.append(generateNaturePlan(activityIds: activityIds))
        
        return plans
    }
    
    private static func generateAdventurePlan(activityIds: [String]) -> QuickPlanItem {
        let hasAdventure = activityIds.contains { ["hiking", "camping", "rafting", "trail-tracking", "bungie"].contains($0) }
        
        if hasAdventure {
            return QuickPlanItem(
                title: "3 Days Mountain Adventure",
                subtitle: "Hiking, camping & exploration",
                icon: "mountain.2.fill",
                duration: "3 Days",
                description: "Experience thrilling outdoor activities in the mountains. Day 1: Hike to scenic viewpoints. Day 2: Camping under the stars. Day 3: Explore hidden trails and waterfalls.",
                itinerary: [
                    ItineraryStop(day: 1, title: "Mountain Hiking", description: "Start with a guided hike to Eagle's Peak viewpoint. Experience panoramic views and fresh mountain air.", coordinate: CLLocationCoordinate2D(latitude: 7.0258, longitude: 80.6002), icon: "mountain.2.fill"),
                    ItineraryStop(day: 1, title: "Lunch at Peak", description: "Packed lunch with a view overlooking three valleys.", coordinate: CLLocationCoordinate2D(latitude: 7.0350, longitude: 80.6100), icon: "fork.knife"),
                    ItineraryStop(day: 2, title: "Mountain Camping", description: "Set up camp at a scenic mountain plateau. Evening bonfire and stargazing.", coordinate: CLLocationCoordinate2D(latitude: 7.0400, longitude: 80.6150), icon: "tent.fill"),
                    ItineraryStop(day: 3, title: "Waterfall Trail", description: "Trek to hidden waterfalls and natural pools. Perfect spot for swimming and photos.", coordinate: CLLocationCoordinate2D(latitude: 6.8756, longitude: 81.0607), icon: "water.waves")
                ],
                category: "adventure"
            )
        } else {
            return QuickPlanItem(
                title: "3 Days Exploration Tour",
                subtitle: "Discover new places & experiences",
                icon: "location.viewfinder",
                duration: "3 Days",
                description: "Explore local gems and hidden attractions. Experience authentic culture, local cuisine, and breathtaking landscapes.",
                itinerary: [
                    ItineraryStop(day: 1, title: "Local Market Visit", description: "Explore traditional markets and street food. Learn about local culture from vendors.", coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8528), icon: "cart.fill"),
                    ItineraryStop(day: 2, title: "Heritage Sites", description: "Visit temples and historical monuments. Guided tour explaining local history.", coordinate: CLLocationCoordinate2D(latitude: 6.9442, longitude: 80.7744), icon: "building.columns.fill"),
                    ItineraryStop(day: 3, title: "Nature Reserve", description: "Explore botanical gardens and nature trails.", coordinate: CLLocationCoordinate2D(latitude: 6.8756, longitude: 81.0607), icon: "leaf.fill")
                ],
                category: "exploration"
            )
        }
    }
    
    private static func generateCulturalPlan(activityIds: [String]) -> QuickPlanItem {
        let hasCulture = activityIds.contains { ["culture", "history", "foods"].contains($0) }
        
        if hasCulture {
            return QuickPlanItem(
                title: "3 Days Cultural Immersion",
                subtitle: "Temples, cuisine & traditions",
                icon: "building.columns.fill",
                duration: "3 Days",
                description: "Dive deep into local culture. Visit ancient temples, taste authentic cuisines, and interact with local communities.",
                itinerary: [
                    ItineraryStop(day: 1, title: "Ancient Temple Visit", description: "Explore ornate temples with centuries of history. Learn about local spirituality and traditions.", coordinate: CLLocationCoordinate2D(latitude: 6.9442, longitude: 80.7744), icon: "building.columns.fill"),
                    ItineraryStop(day: 1, title: "Cooking Class", description: "Learn to cook traditional Sri Lankan dishes with a local chef.", coordinate: CLLocationCoordinate2D(latitude: 6.9500, longitude: 80.7800), icon: "fork.knife"),
                    ItineraryStop(day: 2, title: "Cultural Workshop", description: "Participate in traditional crafts and art workshops.", coordinate: CLLocationCoordinate2D(latitude: 6.9400, longitude: 80.7700), icon: "paintbrush.fill"),
                    ItineraryStop(day: 3, title: "Food Festival", description: "Experience street food and local delicacies at a bustling market.", coordinate: CLLocationCoordinate2D(latitude: 6.9350, longitude: 79.8600), icon: "fork.knife")
                ],
                category: "cultural"
            )
        } else {
            return QuickPlanItem(
                title: "3 Days Food & Flavors",
                subtitle: "Culinary journey & local flavors",
                icon: "fork.knife",
                duration: "3 Days",
                description: "Embark on a culinary adventure. Visit food markets, try local restaurants, and learn local cooking techniques.",
                itinerary: [
                    ItineraryStop(day: 1, title: "Street Food Adventure", description: "Sample authentic street food from various vendors.", coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8528), icon: "fork.knife"),
                    ItineraryStop(day: 2, title: "Fine Dining Experience", description: "Enjoy contemporary cuisine at upscale restaurants.", coordinate: CLLocationCoordinate2D(latitude: 6.9400, longitude: 79.8600), icon: "fork.knife"),
                    ItineraryStop(day: 3, title: "Local Spice Market", description: "Visit spice farms and markets to learn about local flavors.", coordinate: CLLocationCoordinate2D(latitude: 6.9500, longitude: 80.7800), icon: "lariats.circle.fill")
                ],
                category: "food"
            )
        }
    }
    
    private static func generateNaturePlan(activityIds: [String]) -> QuickPlanItem {
        let hasNature = activityIds.contains { ["must-visit", "hidden-gems"].contains($0) }
        
        if hasNature {
            return QuickPlanItem(
                title: "3 Days Hidden Gems Tour",
                subtitle: "Discover secret spots & scenic beauty",
                icon: "star.fill",
                duration: "3 Days",
                description: "Venture off the beaten path. Find hidden beaches, secret viewpoints, and undiscovered natural wonders.",
                itinerary: [
                    ItineraryStop(day: 1, title: "Hidden Beach", description: "Discover a pristine, lesser-known beach. Perfect for relaxation and swimming.", coordinate: CLLocationCoordinate2D(latitude: 5.9497, longitude: 80.7891), icon: "beach.umbrella.fill"),
                    ItineraryStop(day: 2, title: "Secret Waterfall", description: "Trek to a secluded waterfall hidden in the jungle.", coordinate: CLLocationCoordinate2D(latitude: 6.8756, longitude: 81.0607), icon: "water.waves"),
                    ItineraryStop(day: 3, title: "Scenic Viewpoint", description: "Reach a stunning viewpoint for sunrise and panoramic photos.", coordinate: CLLocationCoordinate2D(latitude: 7.0350, longitude: 80.6100), icon: "binoculars.fill")
                ],
                category: "nature"
            )
        } else {
            return QuickPlanItem(
                title: "3 Days Nature Escape",
                subtitle: "Relax in natural beauty",
                icon: "leaf.fill",
                duration: "3 Days",
                description: "Reconnect with nature. Visit botanical gardens, nature reserves, and scenic natural attractions.",
                itinerary: [
                    ItineraryStop(day: 1, title: "Botanical Gardens", description: "Explore extensive botanical gardens with diverse plant species.", coordinate: CLLocationCoordinate2D(latitude: 6.9442, longitude: 80.7744), icon: "leaf.fill"),
                    ItineraryStop(day: 2, title: "Wildlife Reserve", description: "Safari-style tour to spot local wildlife and birds.", coordinate: CLLocationCoordinate2D(latitude: 7.0258, longitude: 80.6002), icon: "hare.fill"),
                    ItineraryStop(day: 3, title: "Tea Plantations", description: "Visit scenic tea estates and learn about tea production.", coordinate: CLLocationCoordinate2D(latitude: 6.9500, longitude: 80.7800), icon: "leaf.circle.fill")
                ],
                category: "nature"
            )
        }
    }
}
