import SwiftUI
import UIKit
import CoreLocation

private struct ManualPlannerFallbackRecord: Decodable {
	let id: String
	let district: String
	let name: String
	let description: String
	let rating: Double
	let latitude: Double
	let longitude: Double
	let imageURLString: String?

	enum CodingKeys: String, CodingKey {
		case id
		case district
		case name
		case description
		case rating
		case latitude
		case longitude
		case imageURLString = "image_url"
	}

	func toPlaceCardItem() -> PlaceCardItem {
		PlaceCardItem(
			id: id,
			wishlistPlaceId: id,
			wishlistSource: .manualPlannerPlaces,
			name: name,
			description: description,
			subtitle: district,
			rating: rating,
			coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
			accentHex: "0D47A1",
			imageURL: imageURLString.flatMap(URL.init(string:))
		)
	}
}

struct OngoingTripDetailScreen: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject var sessionManager: SessionManager
	@EnvironmentObject var ongoingTripViewModel: OngoingTripViewModel

	let tripId: String
	@State private var showDeleteConfirmation = false
	@State private var fallbackPlaceImages: [PlaceCardItem] = []

	private var trip: OngoingTripRecord? {
		ongoingTripViewModel.trip(by: tripId)
	}

	var body: some View {
		NavigationStack {
			Group {
				if let trip {
					ScrollView {
						VStack(alignment: .leading, spacing: 18) {
							headerCard(trip)

							if trip.stops.isEmpty {
								ContentUnavailableView(
									"No steps added yet",
									systemImage: "list.bullet.rectangle",
									description: Text("This journey will show every stop step by step once it is saved from the planner.")
								)
								.padding(.top, 24)
							} else {
								ForEach(groupedStops, id: \.dayNumber) { dayGroup in
									VStack(alignment: .leading, spacing: 10) {
										Text(dayTitle(for: dayGroup.dayNumber))
											.font(.headline)
											.foregroundStyle(Color.travelTitle)

										VStack(spacing: 10) {
											ForEach(dayGroup.stops) { stop in
												stopRow(stop, in: trip)
											}
										}
									}
								}
							}
						}
						.padding()
					}
				} else {
					ContentUnavailableView(
						"Trip not found",
						systemImage: "map",
						description: Text("Return to Journey and refresh your trips.")
					)
				}
			}
			.navigationTitle("Current Trip")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					if trip != nil {
						Button(role: .destructive) {
							showDeleteConfirmation = true
						} label: {
							Image(systemName: "trash")
						}
					}
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }
				}
			}
			.alert("Delete Trip?", isPresented: $showDeleteConfirmation) {
				Button("Cancel", role: .cancel) { }
				Button("Delete", role: .destructive) {
					Task {
						guard let session = sessionManager.currentSession,
							  let currentTrip = trip else { return }
						await ongoingTripViewModel.deleteTrip(session: session, tripId: currentTrip.id)
						dismiss()
					}
				}
			} message: {
				Text("This will permanently remove this trip and all its saved stops.")
			}
			.safeAreaInset(edge: .bottom) {
				if let trip, trip.isActive {
					Button {
						Task {
							guard let session = sessionManager.currentSession else { return }
							await ongoingTripViewModel.completeTrip(session: session, tripId: trip.id)
							dismiss()
						}
					} label: {
						Text("Mark as Completed")
							.font(.headline)
							.foregroundStyle(.white)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 14)
							.background(
								RoundedRectangle(cornerRadius: 14, style: .continuous)
									.fill(Color.travelPrimary)
							)
					}
					.buttonStyle(.plain)
					.padding(.horizontal, 16)
					.padding(.top, 8)
					.padding(.bottom, 8)
					.background(Color.travelBackground.opacity(0.94))
				}
			}
		}
		.task {
			await loadFallbackPlaceImagesIfNeeded()
		}
	}

	private var groupedStops: [(dayNumber: Int, stops: [OngoingTripStopRecord])] {
		Dictionary(grouping: trip?.stops.sorted(by: stopSort) ?? [], by: \.dayNumber)
			.sorted { $0.key < $1.key }
			.map { (dayNumber: $0.key, stops: $0.value) }
	}

	private func headerCard(_ trip: OngoingTripRecord) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .top) {
				VStack(alignment: .leading, spacing: 4) {
					Text(trip.title)
						.font(.title2.weight(.bold))
					Text(trip.subtitle)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}

				Spacer()

				if trip.isCompleted {
					Text("Completed")
						.font(.caption.weight(.semibold))
						.foregroundStyle(.green)
						.padding(.horizontal, 10)
						.padding(.vertical, 6)
						.background(.green.opacity(0.12), in: Capsule())
				}
			}

			Text(trip.dateRangeText)
				.font(.footnote)
				.foregroundStyle(.secondary)

			Text(trip.displayProgressText)
				.font(.footnote.weight(.semibold))
				.foregroundStyle(.blue)
		}
		.padding(14)
		.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
	}

	private func dayTitle(for dayNumber: Int) -> String {
		"Day \(dayNumber)"
	}

	private func stopSort(_ lhs: OngoingTripStopRecord, _ rhs: OngoingTripStopRecord) -> Bool {
		if lhs.dayNumber != rhs.dayNumber {
			return lhs.dayNumber < rhs.dayNumber
		}
		return lhs.sortOrder < rhs.sortOrder
	}

	@ViewBuilder
	private func stopRow(_ stop: OngoingTripStopRecord, in trip: OngoingTripRecord) -> some View {
		Button {
			Task {
				guard let session = sessionManager.currentSession else { return }
				await ongoingTripViewModel.markStopVisited(
					session: session,
					tripId: trip.id,
					stopId: stop.id,
					isVisited: !stop.isVisited
				)
			}
		} label: {
			let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)
			let cardHeight: CGFloat = 160

			ZStack(alignment: .bottomLeading) {
				if let imageURL = resolvedImageURL(for: stop) {
					AsyncImage(url: imageURL) { phase in
						switch phase {
						case .empty:
							LinearGradient(
								colors: [Color.travelPrimary.opacity(0.35), Color.travelPrimary.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						case .success(let image):
							image
								.resizable()
								.scaledToFill()
						case .failure:
							LinearGradient(
								colors: [Color.travelPrimary.opacity(0.35), Color.travelPrimary.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						@unknown default:
							Color.travelPrimary.opacity(0.55)
						}
					}
				} else if let localImage = loadLocalImage(for: stop) {
					localImage
						.resizable()
						.scaledToFill()
				} else {
					LinearGradient(
						colors: [Color.travelPrimary.opacity(0.35), Color.travelPrimary.opacity(0.7)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				}

				LinearGradient(
					colors: [.clear, .black.opacity(0.2), .black.opacity(0.65)],
					startPoint: .top,
					endPoint: .bottom
				)

				VStack(alignment: .leading, spacing: 10) {
					HStack(alignment: .top) {
						Image(systemName: stop.isVisited ? "checkmark.circle.fill" : "circle")
							.font(.title3)
							.foregroundStyle(.white)

						Spacer()

						Text(stop.isVisited ? "Completed" : "Not completed")
							.font(.caption.weight(.semibold))
							.foregroundStyle(stop.isVisited ? .green.opacity(0.95) : .orange.opacity(0.95))
					}

					Text(stop.title)
						.font(.headline)
						.foregroundStyle(.white)
						.lineLimit(1)

					Text(stop.subtitle)
						.font(.subheadline)
						.foregroundStyle(.white.opacity(0.9))
						.lineLimit(1)

					HStack(spacing: 8) {
						if let plannedDate = stop.plannedDateISO {
							Text(plannedDate)
								.font(.caption2)
								.foregroundStyle(.white.opacity(0.88))
						}

						Spacer()

						Text(stop.isVisited ? "Tap to unmark" : "Tap to mark done")
							.font(.caption2.weight(.semibold))
							.foregroundStyle(.white.opacity(0.9))
					}
				}
				.padding(14)
			}
			.frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .bottomLeading)
			.clipped()
			.clipShape(cardShape)
			.overlay(alignment: .topTrailing) {
				Text(stop.isVisited ? "Visited" : "Mark visited")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.white)
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(.black.opacity(0.22), in: Capsule())
					.padding(12)
			}
			.background(Color(.secondarySystemBackground), in: cardShape)
			.overlay(
				cardShape
					.stroke(Color.white.opacity(0.12), lineWidth: 1)
			)
			.contentShape(cardShape)
		}
		.buttonStyle(.plain)
	}

	private func loadFallbackPlaceImagesIfNeeded() async {
		guard fallbackPlaceImages.isEmpty else { return }

		async let placesTask: [PlaceCardItem] = {
			(try? await NearbyPlacesService().fetchPlaces()) ?? []
		}()

		async let manualPlannerTask: [PlaceCardItem] = {
			await fetchManualPlannerFallbackPlaces()
		}()

		let merged = await placesTask + manualPlannerTask
		if merged.isEmpty {
			fallbackPlaceImages = []
			return
		}

		var uniqueByNameDistrict: [String: PlaceCardItem] = [:]
		for place in merged {
			let key = "\(normalizePlannerText(place.name))|\(normalizePlannerText(place.subtitle))"
			if uniqueByNameDistrict[key] == nil {
				uniqueByNameDistrict[key] = place
			}
		}

		fallbackPlaceImages = Array(uniqueByNameDistrict.values)
	}

	private func fetchManualPlannerFallbackPlaces() async -> [PlaceCardItem] {
		guard AuthEndpoints.isConfigured,
			  let baseURL = AuthEndpoints.baseURL else {
			return []
		}

		guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/manual_planner_places"), resolvingAgainstBaseURL: false) else {
			return []
		}

		components.queryItems = [
			URLQueryItem(name: "select", value: "id,district,name,description,rating,latitude,longitude,image_url"),
			URLQueryItem(name: "order", value: "rating.desc")
		]

		guard let url = components.url else { return [] }

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
		request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

		do {
			let (data, response) = try await URLSession.shared.data(for: request)
			guard let httpResponse = response as? HTTPURLResponse,
				  (200...299).contains(httpResponse.statusCode) else {
				return []
			}

			let decoded = try JSONDecoder().decode([ManualPlannerFallbackRecord].self, from: data)
			return decoded.map { $0.toPlaceCardItem() }
		} catch {
			return []
		}
	}

	private func resolvedImageURL(for stop: OngoingTripStopRecord) -> URL? {
		if let direct = stop.imageURL,
		   !isPlaceholderImageURL(direct) {
			return direct
		}

		let targetName = normalizePlannerText(stop.title)
		let subtitleValue = stop.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
		let targetDistrict = subtitleValue.lowercased().hasPrefix("day ") ? "" : normalizePlannerText(subtitleValue)

		let scored = fallbackPlaceImages.compactMap { place -> (URL, Double)? in
			guard let imageURL = place.imageURL,
				  !isPlaceholderImageURL(imageURL) else { return nil }

			let placeName = normalizePlannerText(place.name)
			let placeDistrict = normalizePlannerText(place.subtitle)

			let nameScore: Double
			if placeName == targetName {
				nameScore = 0.0
			} else if placeName.contains(targetName) || targetName.contains(placeName) {
				nameScore = 0.35
			} else {
				let targetTokens = Set(targetName.split(separator: " ").map(String.init))
				let placeTokens = Set(placeName.split(separator: " ").map(String.init))
				let overlap = targetTokens.intersection(placeTokens).count
				guard overlap > 0 else { return nil }
				nameScore = 0.8
			}

			let districtBonus = (targetDistrict.isEmpty || placeDistrict != targetDistrict) ? 0.0 : -0.2
			let coordinateScore = min(
				hypot(place.coordinate.latitude - stop.latitude, place.coordinate.longitude - stop.longitude),
				1.0
			)
			let finalScore = nameScore + districtBonus + coordinateScore
			guard finalScore <= 1.35 else { return nil }
			return (imageURL, finalScore)
		}

		return scored.min(by: { $0.1 < $1.1 })?.0
	}

	private func normalizePlannerText(_ value: String) -> String {
		value
			.lowercased()
			.components(separatedBy: CharacterSet.alphanumerics.inverted)
			.filter { !$0.isEmpty }
			.joined(separator: " ")
	}

	private func isPlaceholderImageURL(_ url: URL) -> Bool {
		guard let host = url.host?.lowercased() else { return false }
		return host.contains("example.com")
	}

	private func loadLocalImage(for stop: OngoingTripStopRecord) -> Image? {
		guard let imageName = stop.imageName ?? localImageName(for: stop.title) else { return nil }

		let candidates: [String] = [
			imageName,
			imageName.lowercased(),
			imageName.uppercased(),
			imageName.replacingOccurrences(of: " ", with: "_"),
			imageName.replacingOccurrences(of: "-", with: "_")
		]

		for candidate in candidates {
			if let uiImage = UIImage(named: candidate) {
				return Image(uiImage: uiImage)
			}
		}

		return nil
	}

	private func localImageName(for title: String) -> String? {
		let lower = title.lowercased()
		if lower.contains("food") || lower.contains("cuisine") || lower.contains("cafe") || lower.contains("seafood") || lower.contains("street") {
			return "foods"
		}
		if lower.contains("hiking") || lower.contains("rock") || lower.contains("peak") || lower.contains("trail") || lower.contains("plains") || lower.contains("adam") || lower.contains("ella") || lower.contains("knuckles") {
			return "hiking"
		}
		if lower.contains("camp") || lower.contains("forest") || lower.contains("meemure") || lower.contains("sinharaja") {
			return "camping"
		}
		if lower.contains("raft") || lower.contains("river") || lower.contains("kitulgala") || lower.contains("kelani") {
			return "rafting"
		}
		if lower.contains("culture") || lower.contains("temple") || lower.contains("kandy") {
			return "culture"
		}
		if lower.contains("history") || lower.contains("fort") || lower.contains("ruin") || lower.contains("anuradhapura") || lower.contains("polonnaruwa") {
			return "history"
		}
		return nil
	}
}
