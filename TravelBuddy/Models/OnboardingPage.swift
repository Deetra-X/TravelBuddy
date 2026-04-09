import Foundation

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case introOne
    case introTwo
    case introThree

    var id: Int { rawValue }
}
