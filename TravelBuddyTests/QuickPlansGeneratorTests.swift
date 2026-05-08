import XCTest
import CoreLocation

@testable import TravelBuddy

final class QuickPlansGeneratorTests: XCTestCase {
    func testGeneratePlansReturnsEmptyWhenNoPlaces() {
        let plans = QuickPlansGenerator.generatePlans(from: ActivityCategory.allCategories, categorizedPlaces: [])
        XCTAssertTrue(plans.isEmpty)
    }

    func testGeneratePlansBuildsUpToThreePlans() {
        let places: [QuickPlanDBPlace] = [
            QuickPlanDBPlace(category: "hiking", name: "A", district: "Kandy", description: "D", rating: 4.9, imageURLString: nil, coordinate: CLLocationCoordinate2D(latitude: 7.0, longitude: 80.0)),
            QuickPlanDBPlace(category: "hiking", name: "B", district: "Kandy", description: "D", rating: 4.8, imageURLString: nil, coordinate: CLLocationCoordinate2D(latitude: 7.0, longitude: 80.0)),
            QuickPlanDBPlace(category: "food", name: "C", district: "Colombo", description: "D", rating: 4.7, imageURLString: nil, coordinate: CLLocationCoordinate2D(latitude: 6.9, longitude: 79.8)),
            QuickPlanDBPlace(category: "culture", name: "E", district: "Galle", description: "D", rating: 4.6, imageURLString: nil, coordinate: CLLocationCoordinate2D(latitude: 6.0, longitude: 80.2)),
        ]

        let activities = ActivityCategory.allCategories.filter { ["hiking", "foods", "culture"].contains($0.id) }
        let plans = QuickPlansGenerator.generatePlans(from: activities, categorizedPlaces: places)

        XCTAssertGreaterThan(plans.count, 0)
        XCTAssertLessThanOrEqual(plans.count, 3)
        XCTAssertTrue(plans.allSatisfy { !$0.itinerary.isEmpty })
    }

    func testGeneratePlansPrefersSelectedActivitiesOrder() {
        let places: [QuickPlanDBPlace] = [
            QuickPlanDBPlace(category: "food", name: "Food A", district: "Colombo", description: "D", rating: 4.0, imageURLString: nil, coordinate: CLLocationCoordinate2D(latitude: 6.9, longitude: 79.8)),
            QuickPlanDBPlace(category: "hiking", name: "Hike A", district: "Kandy", description: "D", rating: 5.0, imageURLString: nil, coordinate: CLLocationCoordinate2D(latitude: 7.0, longitude: 80.0)),
        ]

        let selected = ActivityCategory.allCategories.filter { ["foods", "hiking"].contains($0.id) }
        let plans = QuickPlansGenerator.generatePlans(from: selected, categorizedPlaces: places)

        XCTAssertEqual(plans.first?.icon, "fork.knife")
        XCTAssertEqual(plans.first?.category, "food")
    }
}

