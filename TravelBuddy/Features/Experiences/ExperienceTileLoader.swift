import Foundation
import Combine

@MainActor
final class ExperienceTileLoader: ObservableObject {
    @Published private(set) var rules: [ExperienceTileRule] = ExperienceTileRule.defaultRules

    private let service: ExperienceTileServiceProtocol

    init(service: ExperienceTileServiceProtocol = ExperienceTileService()) {
        self.service = service
    }

    func loadRules() async {
        do {
            let fetchedRules = try await service.fetchTileRules()
            rules = fetchedRules.isEmpty ? ExperienceTileRule.defaultRules : fetchedRules
        } catch {
            rules = ExperienceTileRule.defaultRules
        }
    }
}
