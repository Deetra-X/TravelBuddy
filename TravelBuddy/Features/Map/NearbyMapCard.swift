import SwiftUI
import MapKit

struct NearbyMapCard: View {
    @Binding var region: MKCoordinateRegion
    let places: [PlaceCardItem]

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: places) { place in
            MapAnnotation(coordinate: place.coordinate) {
                Circle()
                    .fill(Color.travelPrimary)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
