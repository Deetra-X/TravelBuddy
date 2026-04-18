import SwiftUI
import UIKit

struct OngoingTripDetailScreen: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject var sessionManager: SessionManager
	@EnvironmentObject var ongoingTripViewModel: OngoingTripViewModel

	let tripId: String
	@State private var showDeleteConfirmation = false

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
			ZStack(alignment: .bottomLeading) {
				if let localImage = loadLocalImage(for: stop) {
					localImage
						.resizable()
						.scaledToFill()
				} else if let imageURL = stop.imageURL {
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
			.frame(maxWidth: .infinity, minHeight: 170, alignment: .bottomLeading)
			.clipped()
			.overlay(alignment: .topTrailing) {
				Text(stop.isVisited ? "Visited" : "Mark visited")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.white)
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(.black.opacity(0.22), in: Capsule())
					.padding(12)
			}
			.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.stroke(Color.white.opacity(0.12), lineWidth: 1)
			)
		}
		.buttonStyle(.plain)
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
