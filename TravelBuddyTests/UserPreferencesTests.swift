import XCTest

@testable import TravelBuddy

final class UserPreferencesTests: XCTestCase {
    func testToggleActivityAddsAndRemoves() {
        var prefs = UserPreferences()
        let activity = ActivityCategory.allCategories[0]

        XCTAssertFalse(prefs.selectedActivityIds.contains(activity.id))
        prefs.toggleActivity(activity)
        XCTAssertTrue(prefs.selectedActivityIds.contains(activity.id))

        prefs.toggleActivity(activity)
        XCTAssertFalse(prefs.selectedActivityIds.contains(activity.id))
    }

    func testToggleActivityDoesNotExceedFourSelections() {
        var prefs = UserPreferences()
        let activities = ActivityCategory.allCategories

        for activity in activities.prefix(6) {
            prefs.toggleActivity(activity)
        }

        XCTAssertEqual(prefs.selectedActivityIds.count, 4)
    }

    func testIsValidOnlyWhenExactlyFourSelected() {
        var prefs = UserPreferences()
        XCTAssertFalse(prefs.isValid)

        for activity in ActivityCategory.allCategories.prefix(4) {
            prefs.toggleActivity(activity)
        }
        XCTAssertTrue(prefs.isValid)

        // Remove one
        prefs.toggleActivity(ActivityCategory.allCategories[0])
        XCTAssertFalse(prefs.isValid)
    }

    func testSelectedActivitiesMatchesIds() {
        var prefs = UserPreferences()
        let chosen = Array(ActivityCategory.allCategories.prefix(2))
        chosen.forEach { prefs.toggleActivity($0) }

        let selected = prefs.selectedActivities
        XCTAssertEqual(Set(selected.map(\.id)), Set(chosen.map(\.id)))
    }
}

