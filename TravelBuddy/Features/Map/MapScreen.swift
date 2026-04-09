import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct MapScreen: View {
    @ObservedObject var locationManager: UserLocationManager
    let onBackToHome: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showPermissionAlert = false
    @State private var showPreciseLocationAlert = false
    @State private var searchText = ""
    @State private var searchedDestination: SearchedDestination?
    @State private var showSearchErrorAlert = false
    @State private var followUserLocation = true

    private var defaultRegion: MKCoordinateRegion {
        locationManager.region
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: .all) {
                UserAnnotation()

                if let searchedDestination {
                    Annotation(searchedDestination.title, coordinate: searchedDestination.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()
            }
        }
        .onAppear {
            syncLocation()
            locationManager.requestAndStart()
            updatePermissionAlert()
        }
        .onChange(of: locationManager.location) {
            if followUserLocation {
                syncLocation()
            }
        }
        .onChange(of: locationManager.authorizationStatus) {
            updatePermissionAlert()
            updatePreciseLocationAlert()
        }
        .onChange(of: locationManager.accuracyAuthorization) {
            updatePreciseLocationAlert()
        }
        .alert("Location Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable location access in Settings to view your real-time position on the map.")
        }
        .alert("Enable Precise Location", isPresented: $showPreciseLocationAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }

            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Your device is using approximate location. Enable Precise Location in Settings for better accuracy.")
        }
        .alert("Destination Not Found", isPresented: $showSearchErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Try searching with another destination name.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: onBackToHome) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.travelTitle)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.95)))
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.travelBody)

                TextField("Search destinations", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        searchDestination()
                    }
                    .foregroundStyle(Color.travelTitle)

                Spacer()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchedDestination = nil
                        followUserLocation = true
                        syncLocation()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.travelBody)
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.95))
            )
        }
    }

    private func syncLocation() {
        if let location = locationManager.location {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        } else {
            cameraPosition = .region(defaultRegion)
        }
    }

    private func updatePermissionAlert() {
        showPermissionAlert = locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted
    }

    private func updatePreciseLocationAlert() {
        let isAuthorized = locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
        showPreciseLocationAlert = isAuthorized && locationManager.accuracyAuthorization == .reducedAccuracy
    }

    private func searchDestination() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let location = locationManager.location {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
            )
        }

        Task {
            do {
                let response = try await MKLocalSearch(request: request).start()
                guard let mapItem = response.mapItems.first else {
                    await MainActor.run {
                        showSearchErrorAlert = true
                    }
                    return
                }

                let coordinate = mapItem.location.coordinate
                let title = mapItem.name ?? query

                await MainActor.run {
                    searchedDestination = SearchedDestination(title: title, coordinate: coordinate)
                    followUserLocation = false
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                        )
                    )
                }
            } catch {
                await MainActor.run {
                    showSearchErrorAlert = true
                }
            }
        }
    }
}

private struct SearchedDestination: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
}
