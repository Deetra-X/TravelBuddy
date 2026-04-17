import SwiftUI
import Foundation
import Combine

struct PlaceDetail: Identifiable, Hashable {
    let id: String
    let name: String
    let district: String
    let description: String
    let rating: Double
    let latitude: Double
    let longitude: Double
    let imageURL: URL?

    init(
        id: String,
        name: String,
        district: String,
        description: String,
        rating: Double,
        latitude: Double,
        longitude: Double,
        imageURL: URL?
    ) {
        self.id = id
        self.name = name
        self.district = district
        self.description = description
        self.rating = rating
        self.latitude = latitude
        self.longitude = longitude
        self.imageURL = imageURL
    }
}

struct PlaceReview: Identifiable, Hashable {
    let id: String
    let placeId: String
    let userId: String
    let reviewerName: String
    let rating: Double
    let comment: String
    let createdAt: Date
}

protocol PlaceDetailsServiceProtocol {
    func fetchManualPlannerPlace(name: String, district: String) async throws -> PlaceDetail?
    func fetchReviews(placeId: String) async throws -> [PlaceReview]
    func submitReview(placeId: String, userId: String, reviewerName: String, rating: Double, comment: String, accessToken: String) async throws
    func isWishlisted(userId: String, placeId: String, accessToken: String) async throws -> Bool
    func addToWishlist(userId: String, placeId: String, accessToken: String) async throws
    func removeFromWishlist(userId: String, placeId: String, accessToken: String) async throws
    func fetchWishlist(userId: String, accessToken: String) async throws -> [WishlistPlaceItem]
}

final class PlaceDetailsService: PlaceDetailsServiceProtocol {
    enum PlaceDetailsError: LocalizedError {
        case missingConfiguration
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Supabase is not configured."
            case .invalidResponse:
                return "Failed to process server response."
            }
        }
    }

    func fetchManualPlannerPlace(name: String, district: String) async throws -> PlaceDetail? {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw PlaceDetailsError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/manual_planner_places"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "id,name,district,description,rating,latitude,longitude,image_url"),
            URLQueryItem(name: "name", value: "eq.\(name)"),
            URLQueryItem(name: "district", value: "eq.\(district)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let records: [ManualPlannerPlaceRecord] = try await executeRequest(url: url)
        return records.first?.toPlaceDetail()
    }

    func fetchReviews(placeId: String) async throws -> [PlaceReview] {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw PlaceDetailsError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/place_reviews"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "id,place_id,user_id,reviewer_name,rating,comment,created_at"),
            URLQueryItem(name: "place_id", value: "eq.\(placeId)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let records: [PlaceReviewRecord] = try await executeRequest(url: url)
        return records.map { $0.toPlaceReview() }
    }

    func submitReview(placeId: String, userId: String, reviewerName: String, rating: Double, comment: String, accessToken: String) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw PlaceDetailsError.missingConfiguration
        }

        let url = baseURL.appending(path: "/rest/v1/place_reviews")
        let payload = [PlaceReviewInsertPayload(placeId: placeId, userId: userId, reviewerName: reviewerName, rating: rating, comment: comment)]
        try await executeWriteRequest(url: url, method: "POST", accessToken: accessToken, body: payload)
    }

    func isWishlisted(userId: String, placeId: String, accessToken: String) async throws -> Bool {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw PlaceDetailsError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/user_wishlist"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "place_id", value: "eq.\(placeId)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let records: [WishlistRowRecord] = try await executeRequest(url: url, accessToken: accessToken)
        return !records.isEmpty
    }

    func addToWishlist(userId: String, placeId: String, accessToken: String) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw PlaceDetailsError.missingConfiguration
        }

        let url = baseURL.appending(path: "/rest/v1/user_wishlist")
        let payload = [WishlistInsertPayload(userId: userId, placeId: placeId)]
        try await executeWriteRequest(url: url, method: "POST", accessToken: accessToken, body: payload)
    }

    func removeFromWishlist(userId: String, placeId: String, accessToken: String) async throws {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw PlaceDetailsError.missingConfiguration
        }

        guard var components = URLComponents(url: baseURL.appending(path: "/rest/v1/user_wishlist"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "place_id", value: "eq.\(placeId)")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        try await executeWriteRequest(url: url, method: "DELETE", accessToken: accessToken, body: Optional<Int>.none)
    }

    func fetchWishlist(userId: String, accessToken: String) async throws -> [WishlistPlaceItem] {
        guard AuthEndpoints.isConfigured, let baseURL = AuthEndpoints.baseURL else {
            throw PlaceDetailsError.missingConfiguration
        }

        guard var wishlistComponents = URLComponents(url: baseURL.appending(path: "/rest/v1/user_wishlist"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        wishlistComponents.queryItems = [
            URLQueryItem(name: "select", value: "place_id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]

        guard let wishlistURL = wishlistComponents.url else {
            throw URLError(.badURL)
        }

        let wishlistRows: [WishlistPlaceOnlyRecord] = try await executeRequest(url: wishlistURL, accessToken: accessToken)
        let placeIds = wishlistRows.map(\.placeId)

        guard !placeIds.isEmpty else {
            return []
        }

        let joinedIDs = placeIds.joined(separator: ",")
        guard var placesComponents = URLComponents(url: baseURL.appending(path: "/rest/v1/manual_planner_places"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        placesComponents.queryItems = [
            URLQueryItem(name: "select", value: "id,name,district,image_url"),
            URLQueryItem(name: "id", value: "in.(\(joinedIDs))")
        ]

        guard let placesURL = placesComponents.url else {
            throw URLError(.badURL)
        }

        let placeRecords: [WishlistPlaceRecord] = try await executeRequest(url: placesURL, accessToken: accessToken)
        let byId = Dictionary(uniqueKeysWithValues: placeRecords.map { ($0.id, $0) })

        return placeIds.compactMap { placeId in
            guard let place = byId[placeId] else { return nil }
            return WishlistPlaceItem(
                id: placeId,
                placeId: placeId,
                title: place.name,
                subtitle: place.district,
                accentHex: "0D47A1",
                imageURL: place.imageURLString.flatMap(URL.init(string:))
            )
        }
    }

    private func executeRequest<T: Decodable>(url: URL, accessToken: String? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken ?? SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PlaceDetailsError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = formatter.date(from: value) {
                return date
            }

            let fallback = ISO8601DateFormatter()
            if let date = fallback.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }

        return try decoder.decode(T.self, from: data)
    }

    private func executeWriteRequest<T: Encodable>(url: URL, method: String, accessToken: String, body: T?) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PlaceDetailsError.invalidResponse
        }
    }
}

@MainActor
final class PlaceDetailsViewModel: ObservableObject {
    @Published private(set) var place: PlaceDetail
    @Published private(set) var reviews: [PlaceReview] = []
    @Published private(set) var isWishlisted: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSubmittingReview: Bool = false
    @Published private(set) var destinationWeather: WeatherSnapshot?
    @Published private(set) var isDestinationWeatherLoading: Bool = false
    @Published var reviewText: String = ""
    @Published var reviewRating: Double = 5
    @Published var toastMessage: String?

    private let service: PlaceDetailsServiceProtocol
    private let weatherService: WeatherServiceProtocol
    private let seedName: String
    private let seedDistrict: String
    private let fallbackLatitude: Double
    private let fallbackLongitude: Double

    init(
        placeName: String,
        district: String,
        fallbackDescription: String,
        fallbackImageURL: URL?,
        fallbackRating: Double,
        fallbackLatitude: Double,
        fallbackLongitude: Double,
        service: PlaceDetailsServiceProtocol? = nil,
        weatherService: WeatherServiceProtocol? = nil
    ) {
        self.seedName = placeName
        self.seedDistrict = district
        self.service = service ?? PlaceDetailsService()
        self.weatherService = weatherService ?? WeatherService()
        self.fallbackLatitude = fallbackLatitude
        self.fallbackLongitude = fallbackLongitude
        self.place = PlaceDetail(
            id: "",
            name: placeName,
            district: district,
            description: fallbackDescription,
            rating: fallbackRating,
            latitude: fallbackLatitude,
            longitude: fallbackLongitude,
            imageURL: fallbackImageURL
        )
    }

    func load(session: AuthSession?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let fetched = try await service.fetchManualPlannerPlace(name: seedName, district: seedDistrict) {
                place = fetched
                reviews = try await service.fetchReviews(placeId: fetched.id)

                if let session {
                    isWishlisted = try await service.isWishlisted(userId: session.userId, placeId: fetched.id, accessToken: session.accessToken)
                } else {
                    isWishlisted = false
                }
            }
        } catch {
            toastMessage = "Could not load live place data."
        }

        await refreshDestinationWeather()
    }

    func toggleWishlist(session: AuthSession?) async {
        guard let session else {
            toastMessage = "Please sign in to use wishlist."
            return
        }

        guard !place.id.isEmpty else {
            toastMessage = "Place is not linked to database yet."
            return
        }

        do {
            if isWishlisted {
                try await service.removeFromWishlist(userId: session.userId, placeId: place.id, accessToken: session.accessToken)
                isWishlisted = false
                toastMessage = "Removed from wishlist."
            } else {
                try await service.addToWishlist(userId: session.userId, placeId: place.id, accessToken: session.accessToken)
                isWishlisted = true
                toastMessage = "Added to wishlist."
            }
        } catch {
            toastMessage = "Could not update wishlist."
        }
    }

    func submitReview(session: AuthSession?) async {
        guard let session else {
            toastMessage = "Please sign in to add a review."
            return
        }

        guard !place.id.isEmpty else {
            toastMessage = "Place is not linked to database yet."
            return
        }

        let trimmed = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            toastMessage = "Write a short review first."
            return
        }

        isSubmittingReview = true
        defer { isSubmittingReview = false }

        do {
            try await service.submitReview(
                placeId: place.id,
                userId: session.userId,
                reviewerName: session.userName,
                rating: reviewRating,
                comment: trimmed,
                accessToken: session.accessToken
            )

            reviewText = ""
            reviews = try await service.fetchReviews(placeId: place.id)
            toastMessage = "Review added."
        } catch {
            toastMessage = "Could not submit review."
        }
    }

    var computedRating: Double {
        guard !reviews.isEmpty else {
            return place.rating
        }

        let total = reviews.reduce(0) { $0 + $1.rating }
        return total / Double(reviews.count)
    }

    func refreshDestinationWeather() async {
        guard place.latitude != 0 || place.longitude != 0 || fallbackLatitude != 0 || fallbackLongitude != 0 else {
            return
        }

        let latitude = place.latitude == 0 ? fallbackLatitude : place.latitude
        let longitude = place.longitude == 0 ? fallbackLongitude : place.longitude

        isDestinationWeatherLoading = true
        defer { isDestinationWeatherLoading = false }

        do {
            destinationWeather = try await weatherService.fetchCurrentWeather(latitude: latitude, longitude: longitude)
        } catch {
            destinationWeather = nil
        }
    }
}

struct PlaceDetailsScreen: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel: PlaceDetailsViewModel

    init(
        placeName: String,
        district: String,
        fallbackDescription: String,
        fallbackImageURL: URL?,
        fallbackRating: Double,
        fallbackLatitude: Double,
        fallbackLongitude: Double
    ) {
        _viewModel = StateObject(
            wrappedValue: PlaceDetailsViewModel(
                placeName: placeName,
                district: district,
                fallbackDescription: fallbackDescription,
                fallbackImageURL: fallbackImageURL,
                fallbackRating: fallbackRating,
                fallbackLatitude: fallbackLatitude,
                fallbackLongitude: fallbackLongitude
            )
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                topImage

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.place.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.travelTitle)

                        Text(viewModel.place.district)
                            .font(.subheadline)
                            .foregroundStyle(Color.travelPrimary)
                    }

                    Spacer()

                    Button {
                        Task {
                            await viewModel.toggleWishlist(session: sessionManager.currentSession)
                        }
                    } label: {
                        Image(systemName: viewModel.isWishlisted ? "heart.fill" : "heart")
                            .font(.headline)
                            .foregroundStyle(viewModel.isWishlisted ? Color.red : Color.travelBody)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white.opacity(0.9)))
                    }
                    .buttonStyle(.plain)
                }

                Text("Description")
                    .font(.headline)
                    .foregroundStyle(Color.travelTitle)

                Text(viewModel.place.description)
                    .font(.body)
                    .foregroundStyle(Color.travelBody)
                    .fixedSize(horizontal: false, vertical: true)

                destinationWeatherSection

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Review Summary")
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)

                    HStack(spacing: 8) {
                        Text(String(format: "%.1f", viewModel.computedRating))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.travelTitle)

                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)

                        Text("(\(viewModel.reviews.count) reviews)")
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Review")
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)

                    Stepper(value: $viewModel.reviewRating, in: 1...5, step: 1) {
                        Text("Rating: \(Int(viewModel.reviewRating))/5")
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)
                    }

                    TextField("Write your review", text: $viewModel.reviewText, axis: .vertical)
                        .lineLimit(3...5)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                        )

                    Button {
                        Task {
                            await viewModel.submitReview(session: sessionManager.currentSession)
                        }
                    } label: {
                        Text(viewModel.isSubmittingReview ? "Submitting..." : "Add Review")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.travelPrimary)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSubmittingReview)
                    .opacity(viewModel.isSubmittingReview ? 0.65 : 1)
                }

                if viewModel.reviews.isEmpty {
                    Text("No reviews yet.")
                        .font(.subheadline)
                        .foregroundStyle(Color.travelBody)
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.reviews) { review in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(review.reviewerName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.travelTitle)

                                    Spacer()

                                    Text(String(format: "%.1f ★", review.rating))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.travelPrimary)
                                }

                                Text(review.comment)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.travelBody)

                                Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(Color.travelBody.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.9))
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.travelBackground.ignoresSafeArea())
        .navigationTitle("Place")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(session: sessionManager.currentSession)
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toastMessage {
                Text(toast)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.75), in: Capsule())
                    .padding(.bottom, 14)
            }
        }
    }

    private var topImage: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.travelPrimary.opacity(0.9), Color.green.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let imageURL = viewModel.place.imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.clear
                    }
                }
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var destinationWeatherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Destination Weather")
                    .font(.headline)
                    .foregroundStyle(Color.travelTitle)

                Spacer()

                if viewModel.isDestinationWeatherLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task {
                            await viewModel.refreshDestinationWeather()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.travelPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let weather = viewModel.destinationWeather {
                HStack(spacing: 12) {
                    Image(systemName: weather.isRainy ? "cloud.rain.fill" : "sun.max.fill")
                        .font(.title2)
                        .foregroundStyle(weather.isRainy ? Color.blue : Color.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(weather.cityName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.travelTitle)

                        Text("\(weather.temperatureCelsius)°C • \(weather.title)")
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)

                        Text(weather.description)
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                )
            } else {
                Text("Weather for this destination is currently unavailable.")
                    .font(.caption)
                    .foregroundStyle(Color.travelBody)
                    .padding(.vertical, 2)
            }
        }
    }
}

private struct ManualPlannerPlaceRecord: Decodable {
    let id: String
    let name: String
    let district: String
    let description: String
    let rating: Double
    let latitude: Double
    let longitude: Double
    let imageURLString: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case district
        case description
        case rating
        case latitude
        case longitude
        case imageURLString = "image_url"
    }

    func toPlaceDetail() -> PlaceDetail {
        PlaceDetail(
            id: id,
            name: name,
            district: district,
            description: description,
            rating: rating,
            latitude: latitude,
            longitude: longitude,
            imageURL: imageURLString.flatMap(URL.init(string:))
        )
    }
}

private struct PlaceReviewRecord: Decodable {
    let id: String
    let placeId: String
    let userId: String
    let reviewerName: String
    let rating: Double
    let comment: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case placeId = "place_id"
        case userId = "user_id"
        case reviewerName = "reviewer_name"
        case rating
        case comment
        case createdAt = "created_at"
    }

    func toPlaceReview() -> PlaceReview {
        PlaceReview(
            id: id,
            placeId: placeId,
            userId: userId,
            reviewerName: reviewerName,
            rating: rating,
            comment: comment,
            createdAt: createdAt
        )
    }
}

private struct PlaceReviewInsertPayload: Encodable {
    let placeId: String
    let userId: String
    let reviewerName: String
    let rating: Double
    let comment: String

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case userId = "user_id"
        case reviewerName = "reviewer_name"
        case rating
        case comment
    }
}

private struct WishlistRowRecord: Decodable {
    let id: String
}

private struct WishlistPlaceOnlyRecord: Decodable {
    let placeId: String

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
    }
}

private struct WishlistInsertPayload: Encodable {
    let userId: String
    let placeId: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case placeId = "place_id"
    }
}

private struct WishlistPlaceRecord: Decodable {
    let id: String
    let name: String
    let district: String
    let imageURLString: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case district
        case imageURLString = "image_url"
    }
}