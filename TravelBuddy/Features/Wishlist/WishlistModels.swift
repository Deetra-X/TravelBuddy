import Foundation

struct WishlistPlaceItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let accentHex: String
}

enum WishlistMockData {
    static let sampleItems: [WishlistPlaceItem] = [
        WishlistPlaceItem(title: "Upper Diyaluma", subtitle: "Badulla, Central province", accentHex: "8D6E63"),
        WishlistPlaceItem(title: "Horton Place", subtitle: "Badulla, Central province", accentHex: "78909C"),
        WishlistPlaceItem(title: "Nuwaragala", subtitle: "Badulla, Central province", accentHex: "00695C"),
        WishlistPlaceItem(title: "Nelum Pokuna", subtitle: "Badulla, Central province", accentHex: "7E57C2")
    ]
}
