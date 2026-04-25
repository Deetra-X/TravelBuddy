import Foundation
import Combine

@MainActor
final class OngoingTripViewModel: ObservableObject {
	@Published private(set) var trips: [OngoingTripRecord] = []
	@Published var isLoading = false
	@Published var errorMessage: String?

	private let service: OngoingTripServiceProtocol
	private let cacheKeyPrefix = "com.travelbuddy.ongoingTrips.cache"
	private var activeUserId: String?

	init(service: OngoingTripServiceProtocol = OngoingTripService()) {
		self.service = service
	}

	var latestTrip: OngoingTripRecord? {
		activeTrips.first ?? completedTrips.first
	}

	var activeTrips: [OngoingTripRecord] {
		trips
			.filter { $0.isActive }
			.sorted(by: Self.sortTrips)
	}

	var completedTrips: [OngoingTripRecord] {
		trips
			.filter { $0.isCompleted }
			.sorted(by: Self.sortTrips)
	}

	func loadTrips(session: AuthSession, force: Bool = false) async {
		if isLoading { return }

		if activeUserId != session.userId {
			activeUserId = session.userId
			trips = []
			errorMessage = nil
			loadCache(for: session.userId)
		}

		if !force, !trips.isEmpty { return }

		isLoading = true
		defer { isLoading = false }

		do {
			let fetchedTrips = try await service.fetchTrips(session: session)
			trips = fetchedTrips
			errorMessage = nil
			saveCache(for: session.userId)
		} catch {
			errorMessage = error.localizedDescription
			loadCache(for: session.userId)
		}
	}

	func saveTrip(
		session: AuthSession,
		sourceType: String,
		title: String,
		subtitle: String,
		stops: [PlannedTripStopDraft]
	) async -> Bool {
		do {
			try await service.saveTrip(
				session: session,
				sourceType: sourceType,
				title: title,
				subtitle: subtitle,
				stops: stops
			)
			await loadTrips(session: session, force: true)
			return true
		} catch {
			errorMessage = error.localizedDescription
			return false
		}
	}

	func markStopVisited(session: AuthSession, tripId: String, stopId: String, isVisited: Bool) async {
		do {
			try await service.markStopVisited(session: session, tripId: tripId, stopId: stopId, isVisited: isVisited)
			await loadTrips(session: session, force: true)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func completeTrip(session: AuthSession, tripId: String) async {
		do {
			try await service.markTripCompleted(session: session, tripId: tripId)
			await loadTrips(session: session, force: true)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func deleteTrip(session: AuthSession, tripId: String) async {
		do {
			try await service.deleteTrip(session: session, tripId: tripId)
			await loadTrips(session: session, force: true)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func trip(by id: String) -> OngoingTripRecord? {
		trips.first(where: { $0.id == id })
	}

	func clearAllTrips(session: AuthSession) async -> Bool {
		let tripIds = trips.map(\.id)

		for tripId in tripIds {
			do {
				try await service.deleteTrip(session: session, tripId: tripId)
			} catch {
				errorMessage = error.localizedDescription
				return false
			}
		}

		trips = []
		errorMessage = nil
		clearLocalCache(for: session.userId)
		return true
	}

	func clearLocalCache(for userId: String) {
		UserDefaults.standard.removeObject(forKey: cacheKey(for: userId))
		if activeUserId == userId {
			trips = []
		}
	}

	private func saveCache(for userId: String) {
		guard let data = try? JSONEncoder().encode(trips) else { return }
		UserDefaults.standard.set(data, forKey: cacheKey(for: userId))
	}

	private func loadCache(for userId: String) {
		guard let data = UserDefaults.standard.data(forKey: cacheKey(for: userId)),
			  let decoded = try? JSONDecoder().decode([OngoingTripRecord].self, from: data) else {
			return
		}
		trips = decoded
	}

	private func cacheKey(for userId: String) -> String {
		"\(cacheKeyPrefix).\(userId)"
	}

	private static func sortTrips(lhs: OngoingTripRecord, rhs: OngoingTripRecord) -> Bool {
		let lhsDate = lhs.updatedAt ?? lhs.createdAt ?? ""
		let rhsDate = rhs.updatedAt ?? rhs.createdAt ?? ""
		return lhsDate > rhsDate
	}
}
