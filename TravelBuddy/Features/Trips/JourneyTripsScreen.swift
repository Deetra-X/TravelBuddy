import SwiftUI

struct JourneyTripsScreen: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var ongoingTripViewModel: OngoingTripViewModel

    var onStartPlanning: () -> Void

    @State private var selectedTripId: String?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            Group {
                if ongoingTripViewModel.isLoading && ongoingTripViewModel.trips.isEmpty {
                    ProgressView("Loading your trips...")
                        .tint(Color.travelPrimary)
                } else if ongoingTripViewModel.trips.isEmpty {
                    ContentUnavailableView(
                        "No ongoing trips yet",
                        systemImage: "map.circle",
                        description: Text("Create a trip from My Trip and it will appear here.")
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            if !ongoingTripViewModel.activeTrips.isEmpty {
                                sectionTitle("Active Journeys")

                                VStack(spacing: 12) {
                                    ForEach(ongoingTripViewModel.activeTrips) { trip in
                                        journeyCard(for: trip)
                                    }
                                }
                            }

                            if !ongoingTripViewModel.completedTrips.isEmpty {
                                sectionTitle("Completed Journeys")

                                VStack(spacing: 12) {
                                    ForEach(ongoingTripViewModel.completedTrips) { trip in
                                        journeyCard(for: trip)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Journey")
            .safeAreaInset(edge: .bottom) {
                if ongoingTripViewModel.trips.isEmpty {
                    Button {
                        onStartPlanning()
                    } label: {
                        Text("Plan a Trip")
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
        .sheet(isPresented: $showDetail) {
            if let tripId = selectedTripId {
                OngoingTripDetailScreen(tripId: tripId)
                    .environmentObject(sessionManager)
                    .environmentObject(ongoingTripViewModel)
            }
        }
        .task(id: sessionManager.currentSession?.userId) {
            guard let session = sessionManager.currentSession else { return }
            await ongoingTripViewModel.loadTrips(session: session, force: true)
        }
    }

    @ViewBuilder
    private func journeyCard(for trip: OngoingTripRecord) -> some View {
        OngoingTripCard(
            item: OngoingTripItem(
                title: trip.title,
                progressText: trip.isCompleted ? "Completed journey" : trip.displayProgressText,
                progress: trip.resolvedProgress
            ),
            onTap: {
                selectedTripId = trip.id
                showDetail = true
            }
        )
        .overlay(alignment: .topTrailing) {
            if trip.isCompleted {
                Text("Completed")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.12), in: Capsule())
                    .padding(10)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.travelTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
