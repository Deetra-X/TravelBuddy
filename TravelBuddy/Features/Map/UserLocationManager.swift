import Foundation
import CoreLocation
import MapKit
import Combine

final class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var accuracyAuthorization: CLAccuracyAuthorization = .reducedAccuracy
    @Published var horizontalAccuracy: CLLocationAccuracy?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    private let sriLankaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
        span: MKCoordinateSpan(latitudeDelta: 3.2, longitudeDelta: 3.2)
    )

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .otherNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
        accuracyAuthorization = locationManager.accuracyAuthorization
    }

    func requestAndStart() {
        authorizationStatus = locationManager.authorizationStatus

        if location == nil {
            region = sriLankaRegion
        }

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
        @unknown default:
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let validLocations = locations.filter { item in
            item.horizontalAccuracy > 0 && abs(item.timestamp.timeIntervalSinceNow) < 12
        }

        guard let bestLocation = validLocations.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy }) else {
            return
        }

        guard isWithinSriLanka(bestLocation.coordinate) else {
            region = sriLankaRegion
            return
        }

        location = bestLocation
        horizontalAccuracy = bestLocation.horizontalAccuracy

        let isGoodAccuracy = bestLocation.horizontalAccuracy <= 120
        let spanDelta: CLLocationDegrees = isGoodAccuracy ? 0.0075 : 0.02

        region = MKCoordinateRegion(
            center: bestLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
        )
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        accuracyAuthorization = manager.accuracyAuthorization

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            locationManager.stopUpdatingLocation()
            region = sriLankaRegion
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        if location == nil {
            region = sriLankaRegion
        }
    }

    private func isWithinSriLanka(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latitudeRange = 5.7...10.1
        let longitudeRange = 79.5...82.1
        return latitudeRange.contains(coordinate.latitude) && longitudeRange.contains(coordinate.longitude)
    }
}
