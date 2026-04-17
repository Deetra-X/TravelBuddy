import Foundation

extension ExperienceTileRule {
    static let defaultRules: [ExperienceTileRule] = [
        ExperienceTileRule(
            id: "beach-escapes",
            tileKey: "beach-escapes",
            title: "Beach escapes",
            subtitle: "Sunny coast",
            icon: "sun.max.fill",
            accentHex: "006064",
            imageName: "ocean",
            nameKeywords: ["beach", "bay", "coast", "ocean", "surf"],
            descriptionKeywords: ["beach", "ocean", "sea", "coast", "surf"],
            districtKeywords: ["galle", "matara", "gampaha", "kalutara", "trincomalee", "jaffna", "ampara", "hambantota"],
            sortOrder: 1
        ),
        ExperienceTileRule(
            id: "hiking-adventures",
            tileKey: "hiking-adventures",
            title: "Hiking Adventures",
            subtitle: "Mountain trails",
            icon: "figure.hiking",
            accentHex: "1B5E20",
            imageName: "hikin_home",
            nameKeywords: ["hike", "hiking", "mountain", "rock", "peak", "falls", "trail"],
            descriptionKeywords: ["hike", "trail", "mountain", "waterfall", "scenic", "forest"],
            districtKeywords: ["badulla", "kandy", "matale", "ratnapura", "kegalle", "nuwara eliya", "monaragala"],
            sortOrder: 2
        ),
        ExperienceTileRule(
            id: "scenic-rides",
            tileKey: "scenic-rides",
            title: "Scenic Rides",
            subtitle: "Train journeys",
            icon: "train.side.front.car",
            accentHex: "4E342E",
            imageName: "train",
            nameKeywords: ["bridge", "train", "canal", "fort", "dam", "lake"],
            descriptionKeywords: ["train", "bridge", "ride", "view", "scenic", "railway"],
            districtKeywords: ["badulla", "galle", "matara", "kandy", "colombo", "nuwara eliya"],
            sortOrder: 3
        ),
        ExperienceTileRule(
            id: "culture-journeys",
            tileKey: "culture-journeys",
            title: "Culture Journeys",
            subtitle: "Temples & history",
            icon: "building.columns.fill",
            accentHex: "6A1B9A",
            imageName: "culture_home",
            nameKeywords: ["temple", "vihara", "fort", "historic", "heritage", "relic", "statue"],
            descriptionKeywords: ["temple", "culture", "history", "heritage", "monument", "ancient"],
            districtKeywords: ["colombo", "kandy", "anuradhapura", "polonnaruwa", "jaffna", "matara", "galle", "kurunegala"],
            sortOrder: 4
        )
    ]
}
