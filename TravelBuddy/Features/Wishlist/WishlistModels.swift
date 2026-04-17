import Foundation

struct WishlistPlaceItem: Identifiable, Hashable {
    let id: String
    let placeId: String
    let source: WishlistPlaceSource
    let title: String
    let subtitle: String
    let accentHex: String
    let imageURL: URL?
}
