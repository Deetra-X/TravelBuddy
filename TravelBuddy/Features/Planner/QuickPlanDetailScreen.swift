import SwiftUI
import MapKit

struct QuickPlanDetailScreen: View {
    let plan: QuickPlanItem
    let onClose: () -> Void
    var onTripPlanned: (() -> Void)? = nil
    
    @State private var selectedStopIndex = 0
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isSavingTrip = false

    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var ongoingTripViewModel: OngoingTripViewModel
    
    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(Color.travelTitle)
                    }
                    
                    Spacer()
                    
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(Color.travelTitle)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.8))
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Plan Overview
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: plan.icon)
                                    .font(.title2)
                                    .foregroundStyle(Color.travelPrimary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.duration)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.travelBody)
                                    
                                    Text(plan.subtitle)
                                        .font(.headline)
                                        .foregroundStyle(Color.travelTitle)
                                }
                                
                                Spacer()
                            }
                            
                            Text(plan.description)
                                .font(.body)
                                .foregroundStyle(Color.travelBody)
                                .lineSpacing(2)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Map View
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trip Route & Stops")
                                .font(.headline)
                                .foregroundStyle(Color.travelTitle)
                                .padding(.horizontal, 16)
                            
                            Map(position: $cameraPosition) {
                                ForEach(Array(plan.itinerary.enumerated()), id: \.element.id) { index, stop in
                                    Annotation("", coordinate: stop.coordinate) {
                                        VStack(spacing: 0) {
                                            Text(String(index + 1))
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                                .frame(width: 28, height: 28)
                                                .background(Circle().fill(Color.travelPrimary))
                                            
                                            Image(systemName: "triangle.fill")
                                                .foregroundStyle(Color.travelPrimary)
                                                .font(.caption)
                                                .offset(y: -4)
                                        }
                                    }
                                }
                            }
                            .frame(height: 300)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // Itinerary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detailed Itinerary")
                                .font(.headline)
                                .foregroundStyle(Color.travelTitle)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(plan.itinerary.enumerated()), id: \.element.id) { index, stop in
                                    ItineraryStopCard(
                                        stop: stop,
                                        isSelected: selectedStopIndex == index,
                                        onTap: {
                                            withAnimation {
                                                selectedStopIndex = index
                                                cameraPosition = .region(
                                                    MKCoordinateRegion(
                                                        center: stop.coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                                    )
                                                )
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                Button {
                    Task {
                        await saveQuickPlanToOngoingTrips()
                    }
                } label: {
                    HStack {
                        if isSavingTrip {
                            ProgressView()
                                .tint(.white)
                        }

                        Text(isSavingTrip ? "Saving Trip..." : "Start Planning This Trip")
                            .font(.headline)
                        if !isSavingTrip {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundStyle(.white)
                    .background(Color.travelPrimary)
                    .cornerRadius(12)
                }
                .disabled(isSavingTrip)
                .opacity(isSavingTrip ? 0.8 : 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            if !plan.itinerary.isEmpty {
                let firstStop = plan.itinerary[0]
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: firstStop.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    )
                )
            }
        }
    }

    @MainActor
    private func saveQuickPlanToOngoingTrips() async {
        guard let session = sessionManager.currentSession else {
            onClose()
            return
        }

        guard !plan.itinerary.isEmpty else {
            onClose()
            return
        }

        isSavingTrip = true
        defer { isSavingTrip = false }

        let isoFormatter = ISO8601DateFormatter()
        let baseDate = Date()
        let stops: [PlannedTripStopDraft] = plan.itinerary.enumerated().map { index, stop in
            let dayOffset = max(0, stop.day - 1)
            let plannedDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: baseDate) ?? baseDate

            return PlannedTripStopDraft(
                dayNumber: max(1, stop.day),
                sortOrder: index,
                title: stop.title,
                subtitle: "Day \(stop.day)",
                description: stop.description,
                latitude: stop.coordinate.latitude,
                longitude: stop.coordinate.longitude,
                imageName: nil,
                imageURLString: stop.imageURLString,
                plannedDateISO: isoFormatter.string(from: plannedDate)
            )
        }

        await ongoingTripViewModel.saveTrip(
            session: session,
            sourceType: "quick_plan",
            title: plan.title,
            subtitle: "\(plan.duration) • \(plan.subtitle)",
            stops: stops
        )

        if ongoingTripViewModel.errorMessage == nil {
            onClose()
            onTripPlanned?()
        }
    }
}

// MARK: - Itinerary Stop Card
struct ItineraryStopCard: View {
    let stop: ItineraryStop
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Day badge
                VStack(spacing: 0) {
                    Text("Day")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.travelBody)
                    
                    Text("\(stop.day)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.travelPrimary)
                }
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.travelPrimary.opacity(0.1))
                )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: stop.icon)
                            .font(.body)
                            .foregroundStyle(Color.travelPrimary)
                        
                        Text(stop.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.travelTitle)
                    }
                    
                    Text(stop.description)
                        .font(.caption)
                        .foregroundStyle(Color.travelBody)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.travelPrimary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.travelBody)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.travelPrimary.opacity(0.1) : Color.white.opacity(0.6))
                    .stroke(
                        isSelected ? Color.travelPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    QuickPlanDetailScreen(
        plan: QuickPlanItem(
            title: "3 Days Mountain Adventure",
            subtitle: "Hiking, camping & exploration",
            icon: "mountain.2.fill",
            duration: "3 Days",
            description: "Experience thrilling outdoor activities in the mountains.",
            itinerary: [
                ItineraryStop(day: 1, title: "Mountain Hiking", description: "Start with a guided hike to Eagle's Peak viewpoint.", coordinate: CLLocationCoordinate2D(latitude: 7.0258, longitude: 80.6002), icon: "mountain.2.fill", imageURLString: nil),
                ItineraryStop(day: 2, title: "Mountain Camping", description: "Set up camp at a scenic mountain plateau.", coordinate: CLLocationCoordinate2D(latitude: 7.0400, longitude: 80.6150), icon: "tent.fill", imageURLString: nil)
            ],
            category: "adventure"
        ),
        onClose: {}
    )
}
