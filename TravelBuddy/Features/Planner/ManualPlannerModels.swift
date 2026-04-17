import Foundation

enum ManualPlanCategory: String, CaseIterable, Identifiable {
    case mustVisit = "Must Visit"
    case hiking = "Hiking"
    case camping = "Camping"
    case rafting = "Rafting"
    case trailTracking = "Trail Tracking"
    case food = "Food"
    case culture = "Culture"
    case history = "History"
    case bungee = "Bungee"
    case hiddenGems = "Hidden Gems"

    var id: String { rawValue }

    var dbValue: String {
        switch self {
        case .mustVisit: return "must_visit"
        case .hiking: return "hiking"
        case .camping: return "camping"
        case .rafting: return "rafting"
        case .trailTracking: return "trail_tracking"
        case .food: return "food"
        case .culture: return "culture"
        case .history: return "history"
        case .bungee: return "bungee"
        case .hiddenGems: return "hidden_gems"
        }
    }

    var icon: String {
        switch self {
        case .mustVisit: return "star.circle.fill"
        case .hiking: return "figure.hiking"
        case .camping: return "tent.fill"
        case .rafting: return "figure.rower"
        case .trailTracking: return "figure.walk"
        case .food: return "fork.knife"
        case .culture: return "theatermasks.fill"
        case .history: return "building.columns.fill"
        case .bungee: return "bolt.fill"
        case .hiddenGems: return "sparkles"
        }
    }

    var photoKeyword: String {
        switch self {
        case .mustVisit: return "sri+lanka+landmark"
        case .hiking: return "hiking+mountain+trail"
        case .camping: return "camping+forest"
        case .rafting: return "white+water+rafting"
        case .trailTracking: return "nature+trekking+trail"
        case .food: return "sri+lankan+food"
        case .culture: return "sri+lanka+culture+festival"
        case .history: return "ancient+ruins"
        case .bungee: return "adventure+extreme+sports"
        case .hiddenGems: return "hidden+beach+waterfall"
        }
    }

    var assetName: String {
        switch self {
        case .mustVisit: return "must_visit"
        case .hiking: return "hiking"
        case .camping: return "camping"
        case .rafting: return "rafting"
        case .trailTracking: return "trail_tracking"
        case .food: return "foods"
        case .culture: return "culture"
        case .history: return "history"
        case .bungee: return "bungie"
        case .hiddenGems: return "hidden_gems"
        }
    }
}

struct ManualPlanPlace: Identifiable {
    let id = UUID()
    let wishlistPlaceId: String? = nil
    let wishlistSource: WishlistPlaceSource = .manualPlannerPlaces
    let category: ManualPlanCategory
    let name: String
    let district: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let imageURL: URL?
    let description: String

    init(
        category: ManualPlanCategory,
        name: String,
        district: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        imageURLString: String,
        description: String
    ) {
        self.category = category
        self.name = name
        self.district = district
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.imageURL = URL(string: imageURLString)
        self.description = description
    }
}

enum ManualPlannerSeedData {
    static let places: [ManualPlanPlace] = [
        ManualPlanPlace(category: .mustVisit, name: "Sigiriya Rock Fortress", district: "Matale", latitude: 7.9570, longitude: 80.7603, rating: 4.9, imageURLString: "https://example.com/sigiriya.jpg", description: "Sigiriya is an ancient rock fortress rising dramatically above the plains. It features frescoes, gardens, and royal ruins. It is one of Sri Lanka’s most iconic UNESCO heritage sites."),
        ManualPlanPlace(category: .mustVisit, name: "Temple of the Tooth Relic", district: "Kandy", latitude: 7.2936, longitude: 80.6413, rating: 4.8, imageURLString: "https://example.com/kandy.jpg", description: "This sacred temple holds a relic of the Buddha’s tooth. It is a major pilgrimage site for Buddhists. The surrounding architecture and lake create a peaceful atmosphere."),
        ManualPlanPlace(category: .mustVisit, name: "Galle Fort", district: "Galle", latitude: 6.0260, longitude: 80.2170, rating: 4.7, imageURLString: "https://example.com/galle.jpg", description: "A colonial fort built by Portuguese and Dutch settlers. It features cobbled streets and historic buildings. It blends European architecture with local culture."),
        ManualPlanPlace(category: .mustVisit, name: "Ella", district: "Badulla", latitude: 6.8667, longitude: 81.0466, rating: 4.8, imageURLString: "https://example.com/ella.jpg", description: "Ella is a scenic mountain village surrounded by greenery. It is famous for Nine Arches Bridge and viewpoints. The calm vibe attracts travelers worldwide."),
        ManualPlanPlace(category: .mustVisit, name: "Yala National Park", district: "Hambantota", latitude: 6.3725, longitude: 81.5185, rating: 4.7, imageURLString: "https://example.com/yala.jpg", description: "Yala is famous for leopards and diverse wildlife. Safaris offer thrilling nature experiences. It is one of the best wildlife parks in Sri Lanka."),
        ManualPlanPlace(category: .mustVisit, name: "Nuwara Eliya", district: "Nuwara Eliya", latitude: 6.9497, longitude: 80.7891, rating: 4.6, imageURLString: "https://example.com/nuwara.jpg", description: "Known as Little England due to its climate and buildings. It has tea plantations and cool weather. A perfect escape from tropical heat."),

        ManualPlanPlace(category: .hiking, name: "Adam's Peak", district: "Ratnapura", latitude: 6.8096, longitude: 80.4994, rating: 4.9, imageURLString: "https://example.com/adamspeak.jpg", description: "A sacred mountain climbed by thousands of pilgrims. The sunrise from the summit is breathtaking. The trail combines spirituality and adventure."),
        ManualPlanPlace(category: .hiking, name: "Ella Rock", district: "Badulla", latitude: 6.8665, longitude: 81.0460, rating: 4.7, imageURLString: "https://example.com/ellarock.jpg", description: "A scenic hike through tea plantations and forests. The summit gives panoramic valley views. It is popular among tourists and locals."),
        ManualPlanPlace(category: .hiking, name: "Knuckles Range", district: "Matale", latitude: 7.4445, longitude: 80.8200, rating: 4.8, imageURLString: "https://example.com/knuckles.jpg", description: "A biodiversity hotspot with challenging trails. It offers misty mountains and waterfalls. Ideal for serious hikers."),
        ManualPlanPlace(category: .hiking, name: "Horton Plains", district: "Nuwara Eliya", latitude: 6.8000, longitude: 80.8000, rating: 4.7, imageURLString: "https://example.com/horton.jpg", description: "A plateau with grasslands and forests. World's End offers a dramatic cliff view. Perfect for early morning hikes."),
        ManualPlanPlace(category: .hiking, name: "Lakegala", district: "Kandy", latitude: 7.4010, longitude: 80.8800, rating: 4.6, imageURLString: "https://example.com/lakegala.jpg", description: "A steep and adventurous hike. It offers breathtaking views of Knuckles. Best for experienced trekkers."),
        ManualPlanPlace(category: .hiking, name: "Little Adam's Peak", district: "Badulla", latitude: 6.8720, longitude: 81.0480, rating: 4.6, imageURLString: "https://example.com/littleadams.jpg", description: "A beginner-friendly hiking trail. Surrounded by tea plantations. The summit view is stunning and relaxing."),

        ManualPlanPlace(category: .camping, name: "Meemure", district: "Kandy", latitude: 7.4330, longitude: 80.8330, rating: 4.9, imageURLString: "https://example.com/meemure.jpg", description: "A remote village with untouched nature. Perfect for camping and trekking. It offers rivers, forests, and waterfalls."),
        ManualPlanPlace(category: .camping, name: "Riverston", district: "Matale", latitude: 7.5250, longitude: 80.7500, rating: 4.6, imageURLString: "https://example.com/riverston.jpg", description: "A cool and misty mountain area. Great for camping with scenic views. Known for mini World's End."),
        ManualPlanPlace(category: .camping, name: "Belihuloya", district: "Ratnapura", latitude: 6.7167, longitude: 80.7833, rating: 4.5, imageURLString: "https://example.com/belihuloya.jpg", description: "A peaceful location with rivers and waterfalls. Ideal for nature camping. It has a relaxing environment."),
        ManualPlanPlace(category: .camping, name: "Sinharaja Forest", district: "Ratnapura", latitude: 6.4000, longitude: 80.5000, rating: 4.8, imageURLString: "https://example.com/sinharaja.jpg", description: "A UNESCO rainforest reserve. Rich in biodiversity and wildlife. Camping offers a deep jungle experience."),
        ManualPlanPlace(category: .camping, name: "Knuckles Camping", district: "Matale", latitude: 7.4440, longitude: 80.8200, rating: 4.8, imageURLString: "https://example.com/knucklescamp.jpg", description: "A natural camping experience in mountains. Cool climate and scenic beauty. Great for group adventures."),
        ManualPlanPlace(category: .camping, name: "Yala Camping", district: "Hambantota", latitude: 6.3700, longitude: 81.5200, rating: 4.7, imageURLString: "https://example.com/yalacamp.jpg", description: "Safari-style camping in the wild. Close encounters with wildlife. A thrilling overnight experience."),

        ManualPlanPlace(category: .rafting, name: "Kitulgala", district: "Kegalle", latitude: 6.9900, longitude: 80.4170, rating: 4.9, imageURLString: "https://example.com/kitulgala.jpg", description: "The best rafting destination in Sri Lanka. Rapids provide thrilling water adventure. Suitable for beginners and pros."),
        ManualPlanPlace(category: .rafting, name: "Kelani River", district: "Kegalle", latitude: 6.9950, longitude: 80.4200, rating: 4.8, imageURLString: "https://example.com/kelani.jpg", description: "A popular river for white-water rafting. It has multiple rapid levels. Surrounded by lush greenery."),
        ManualPlanPlace(category: .rafting, name: "Sitawaka River", district: "Colombo", latitude: 6.9500, longitude: 80.1000, rating: 4.5, imageURLString: "https://example.com/sitawaka.jpg", description: "A lesser-known rafting spot. Offers a calm but fun experience. Ideal for beginners."),
        ManualPlanPlace(category: .rafting, name: "Mahaweli River", district: "Kandy", latitude: 7.2900, longitude: 80.6300, rating: 4.6, imageURLString: "https://example.com/mahaweli.jpg", description: "The longest river in Sri Lanka. Offers gentle rafting experiences. Scenic surroundings enhance the journey."),
        ManualPlanPlace(category: .rafting, name: "Kalu River", district: "Ratnapura", latitude: 6.6800, longitude: 80.4000, rating: 4.5, imageURLString: "https://example.com/kalu.jpg", description: "Known for smooth rafting routes. Surrounded by rainforest landscapes. A relaxing water activity."),
        ManualPlanPlace(category: .rafting, name: "Gin River", district: "Galle", latitude: 6.1000, longitude: 80.3000, rating: 4.4, imageURLString: "https://example.com/gin.jpg", description: "A calm river ideal for beginners. Offers scenic views and wildlife. Great for a relaxed rafting trip."),

        ManualPlanPlace(category: .trailTracking, name: "Sinharaja Trail", district: "Ratnapura", latitude: 6.4000, longitude: 80.5000, rating: 4.8, imageURLString: "https://example.com/sinharajatrail.jpg", description: "A dense rainforest trekking experience. Rich in biodiversity and rare species. Ideal for eco-tourism lovers."),
        ManualPlanPlace(category: .trailTracking, name: "Knuckles Trail", district: "Matale", latitude: 7.4440, longitude: 80.8200, rating: 4.8, imageURLString: "https://example.com/knucklestrek.jpg", description: "A challenging trekking destination. Includes forests, rivers, and mountains. Perfect for adventure seekers."),
        ManualPlanPlace(category: .trailTracking, name: "Ella Forest Trail", district: "Badulla", latitude: 6.8700, longitude: 81.0500, rating: 4.6, imageURLString: "https://example.com/ellatrail.jpg", description: "A peaceful forest trail near Ella. Offers scenic beauty and wildlife. Easy to moderate difficulty."),
        ManualPlanPlace(category: .trailTracking, name: "Horton Plains Trail", district: "Nuwara Eliya", latitude: 6.8000, longitude: 80.8000, rating: 4.7, imageURLString: "https://example.com/hortontrail.jpg", description: "A loop trail through plains and forests. Includes World's End viewpoint. A popular trekking spot."),
        ManualPlanPlace(category: .trailTracking, name: "Riverston Trail", district: "Matale", latitude: 7.5250, longitude: 80.7500, rating: 4.6, imageURLString: "https://example.com/riverstontrail.jpg", description: "A misty trail with stunning views. Cool climate makes it enjoyable. Ideal for short treks."),
        ManualPlanPlace(category: .trailTracking, name: "Belihuloya Trail", district: "Ratnapura", latitude: 6.7167, longitude: 80.7833, rating: 4.5, imageURLString: "https://example.com/belihuloyatrail.jpg", description: "A scenic trekking area with rivers. Offers peaceful nature walks. Great for beginners."),

        ManualPlanPlace(category: .food, name: "Colombo Street Food", district: "Colombo", latitude: 6.9271, longitude: 79.8612, rating: 4.7, imageURLString: "https://example.com/colombofood.jpg", description: "Offers a variety of local street foods. Includes kottu, hoppers, and seafood. A must-try for food lovers."),
        ManualPlanPlace(category: .food, name: "Negombo Seafood", district: "Gampaha", latitude: 7.2083, longitude: 79.8358, rating: 4.6, imageURLString: "https://example.com/negombofood.jpg", description: "Famous for fresh seafood dishes. Coastal flavors dominate the cuisine. Perfect for seafood lovers."),
        ManualPlanPlace(category: .food, name: "Kandy Traditional Food", district: "Kandy", latitude: 7.2906, longitude: 80.6337, rating: 4.5, imageURLString: "https://example.com/kandyfood.jpg", description: "Known for authentic Sri Lankan rice and curry. Includes traditional sweets. Offers cultural dining experience."),
        ManualPlanPlace(category: .food, name: "Jaffna Cuisine", district: "Jaffna", latitude: 9.6615, longitude: 80.0255, rating: 4.8, imageURLString: "https://example.com/jaffnafood.jpg", description: "Spicy and unique Tamil cuisine. Includes crab curry and dosai. Rich in flavor and tradition."),
        ManualPlanPlace(category: .food, name: "Galle Cafes", district: "Galle", latitude: 6.0260, longitude: 80.2170, rating: 4.6, imageURLString: "https://example.com/gallefood.jpg", description: "Mix of local and international dishes. Located inside historic fort. Offers a cozy dining experience."),
        ManualPlanPlace(category: .food, name: "Ella Chill Cafes", district: "Badulla", latitude: 6.8667, longitude: 81.0466, rating: 4.7, imageURLString: "https://example.com/ellafood.jpg", description: "Relaxed cafes with scenic views. Popular among tourists. Great for casual dining."),

        ManualPlanPlace(category: .culture, name: "Kandy Esala Perahera", district: "Kandy", latitude: 7.2936, longitude: 80.6413, rating: 4.9, imageURLString: "https://example.com/perahera.jpg", description: "A grand cultural festival with elephants and dancers. Celebrates the sacred tooth relic. One of Asia's biggest festivals."),
        ManualPlanPlace(category: .culture, name: "Kataragama Temple", district: "Monaragala", latitude: 6.4130, longitude: 81.3320, rating: 4.7, imageURLString: "https://example.com/kataragama.jpg", description: "A multi-religious sacred site. Attracts pilgrims from all communities. Rich spiritual significance."),
        ManualPlanPlace(category: .culture, name: "Dambulla Cave Temple", district: "Matale", latitude: 7.8567, longitude: 80.6490, rating: 4.8, imageURLString: "https://example.com/dambulla.jpg", description: "A temple complex inside caves. Contains ancient Buddha statues and paintings. A UNESCO heritage site."),
        ManualPlanPlace(category: .culture, name: "Jaffna Cultural Center", district: "Jaffna", latitude: 9.6615, longitude: 80.0255, rating: 4.6, imageURLString: "https://example.com/jaffnaculture.jpg", description: "Promotes Tamil culture and arts. Hosts events and exhibitions. A modern cultural landmark."),
        ManualPlanPlace(category: .culture, name: "Galle Cultural Shows", district: "Galle", latitude: 6.0260, longitude: 80.2170, rating: 4.5, imageURLString: "https://example.com/galleculture.jpg", description: "Traditional dance and music performances. Showcases Sri Lankan heritage. Popular among tourists."),
        ManualPlanPlace(category: .culture, name: "Colombo Museum", district: "Colombo", latitude: 6.9271, longitude: 79.8612, rating: 4.6, imageURLString: "https://example.com/museum.jpg", description: "Displays Sri Lankan history and artifacts. Located in a colonial building. Offers educational insights."),

        ManualPlanPlace(category: .history, name: "Anuradhapura", district: "Anuradhapura", latitude: 8.3114, longitude: 80.4037, rating: 4.9, imageURLString: "https://example.com/anuradhapura.jpg", description: "Ancient capital with ruins and stupas. Rich in Buddhist heritage. A UNESCO site."),
        ManualPlanPlace(category: .history, name: "Polonnaruwa", district: "Polonnaruwa", latitude: 7.9403, longitude: 81.0188, rating: 4.8, imageURLString: "https://example.com/polonnaruwa.jpg", description: "Medieval capital with preserved ruins. Includes statues and temples. A historical treasure."),
        ManualPlanPlace(category: .history, name: "Yapahuwa", district: "Kurunegala", latitude: 7.8200, longitude: 80.3000, rating: 4.6, imageURLString: "https://example.com/yapahuwa.jpg", description: "Ancient rock fortress. Features stone stairways and ruins. Offers historical insight."),
        ManualPlanPlace(category: .history, name: "Mihintale", district: "Anuradhapura", latitude: 8.3500, longitude: 80.5000, rating: 4.7, imageURLString: "https://example.com/mihintale.jpg", description: "Birthplace of Buddhism in Sri Lanka. Sacred mountain site. Offers scenic views."),
        ManualPlanPlace(category: .history, name: "Ritigala", district: "Anuradhapura", latitude: 8.2000, longitude: 80.6500, rating: 4.6, imageURLString: "https://example.com/ritigala.jpg", description: "Ancient monastery ruins in jungle. Surrounded by mystery and nature. A unique historical site."),
        ManualPlanPlace(category: .history, name: "Fort Frederick", district: "Trincomalee", latitude: 8.5700, longitude: 81.2330, rating: 4.5, imageURLString: "https://example.com/frederick.jpg", description: "A colonial fort with ocean views. Built by Portuguese. Rich in history."),

        ManualPlanPlace(category: .bungee, name: "Kitulgala Bungee", district: "Kegalle", latitude: 6.9900, longitude: 80.4170, rating: 4.8, imageURLString: "https://example.com/bungee1.jpg", description: "Sri Lanka's top bungee jumping spot. Jump over scenic river views. A thrilling experience."),
        ManualPlanPlace(category: .bungee, name: "Ella Flying Ravana Zipline", district: "Badulla", latitude: 6.8700, longitude: 81.0500, rating: 4.7, imageURLString: "https://example.com/zipline.jpg", description: "One of Asia's longest ziplines. Offers high-speed adventure. Amazing mountain views."),
        ManualPlanPlace(category: .bungee, name: "Colombo Adventure Park", district: "Colombo", latitude: 6.9000, longitude: 79.9000, rating: 4.5, imageURLString: "https://example.com/adventure.jpg", description: "Includes climbing and rope courses. Suitable for all ages. A fun urban adventure."),
        ManualPlanPlace(category: .bungee, name: "Nuwara Eliya Adventure Park", district: "Nuwara Eliya", latitude: 6.9497, longitude: 80.7891, rating: 4.6, imageURLString: "https://example.com/adventure2.jpg", description: "Offers outdoor adventure activities. Surrounded by cool climate. Great for families."),
        ManualPlanPlace(category: .bungee, name: "Belihuloya Adventure Camp", district: "Ratnapura", latitude: 6.7167, longitude: 80.7833, rating: 4.5, imageURLString: "https://example.com/adventure3.jpg", description: "Includes climbing, rafting, and trekking. Nature-based adventure spot. Ideal for groups."),
        ManualPlanPlace(category: .bungee, name: "Riverston Adventure", district: "Matale", latitude: 7.5250, longitude: 80.7500, rating: 4.6, imageURLString: "https://example.com/adventure4.jpg", description: "Offers hiking and outdoor challenges. Scenic mountain environment. A hidden adventure hub."),

        ManualPlanPlace(category: .hiddenGems, name: "Nilaveli Beach", district: "Trincomalee", latitude: 8.7000, longitude: 81.2000, rating: 4.7, imageURLString: "https://example.com/nilaveli.jpg", description: "A quiet and clean beach. Crystal-clear water and soft sand. Less crowded than other beaches."),
        ManualPlanPlace(category: .hiddenGems, name: "Madulsima", district: "Badulla", latitude: 6.9000, longitude: 81.1000, rating: 4.8, imageURLString: "https://example.com/madulsima.jpg", description: "Famous for Pekoe Trail views. Offers stunning sunrise scenery. A peaceful escape."),
        ManualPlanPlace(category: .hiddenGems, name: "Kalpitiya", district: "Puttalam", latitude: 8.2000, longitude: 79.7000, rating: 4.6, imageURLString: "https://example.com/kalpitiya.jpg", description: "Known for dolphin watching. A hidden coastal paradise. Ideal for water sports."),
        ManualPlanPlace(category: .hiddenGems, name: "Jaffna Islands", district: "Jaffna", latitude: 9.7000, longitude: 80.0000, rating: 4.7, imageURLString: "https://example.com/islands.jpg", description: "Remote islands with unique culture. Beautiful beaches and temples. Less explored by tourists."),
        ManualPlanPlace(category: .hiddenGems, name: "Diyaluma Falls", district: "Badulla", latitude: 6.7300, longitude: 81.0200, rating: 4.9, imageURLString: "https://example.com/diyaluma.jpg", description: "Second highest waterfall in Sri Lanka. Natural infinity pools at the top. A hidden natural wonder."),
        ManualPlanPlace(category: .hiddenGems, name: "Meemure Village", district: "Kandy", latitude: 7.4330, longitude: 80.8330, rating: 4.9, imageURLString: "https://example.com/meemure2.jpg", description: "Remote village with untouched beauty. Offers authentic rural experience. Perfect hidden getaway.")
    ]
}
