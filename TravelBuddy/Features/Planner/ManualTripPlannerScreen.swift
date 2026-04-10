import SwiftUI

struct ManualTripPlannerScreen: View {
    private enum PlannerStep {
        case category
        case destinations
    }

    @State private var step: PlannerStep = .category
    @State private var selectedCategories: Set<ManualPlanCategory> = []
    @State private var selectedDestinationKeys: Set<String> = []

    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if step == .category {
                        Text("What's your adventure category?")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.travelTitle)

                        Text("Select up to 3 categories")
                            .font(.subheadline)
                            .foregroundStyle(Color.travelBody)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(ManualPlanCategory.allCases) { category in
                                ManualPlanCategoryCard(
                                    category: category,
                                    isSelected: selectedCategories.contains(category),
                                    isDisabled: isCategoryDisabled(category),
                                    imageName: category.assetName
                                ) {
                                    toggleCategory(category)
                                }
                            }
                        }
                        .padding(.top, 4)

                        Text("Selected: \(selectedCategories.count)/3")
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)
                    } else {
                        HStack {
                            Text("Select destinations")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.travelTitle)

                            Spacer()

                            Button {
                                step = .category
                            } label: {
                                Text("Edit categories")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.travelPrimary)
                            }
                            .buttonStyle(.plain)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedCategoriesSorted, id: \.id) { category in
                                    CategoryNameIndicator(category: category, isHighlighted: true)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        Text("\(selectedDestinationKeys.count) destinations selected")
                            .font(.caption)
                            .foregroundStyle(Color.travelBody)

                        ForEach(selectedCategoriesSorted, id: \.id) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(Color.travelTitle)

                                ForEach(filteredPlaces(for: category)) { place in
                                    ManualPlanPlaceCard(
                                        place: place,
                                        isSelected: selectedDestinationKeys.contains(placeSelectionKey(place)),
                                        onToggleSelection: {
                                            toggleDestination(place)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if step == .category {
                Button {
                    pruneSelectedDestinations()
                    step = .destinations
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.travelPrimary)
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedCategories.isEmpty)
                .opacity(selectedCategories.isEmpty ? 0.55 : 1)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color.travelBackground.opacity(0.94))
            }
        }
    }

    private var selectedCategoriesSorted: [ManualPlanCategory] {
        ManualPlanCategory.allCases.filter { selectedCategories.contains($0) }
    }

    private func filteredPlaces(for category: ManualPlanCategory) -> [ManualPlanPlace] {
        ManualPlannerSeedData.places.filter { $0.category == category }
    }

    private func toggleCategory(_ category: ManualPlanCategory) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else if selectedCategories.count < 3 {
                selectedCategories.insert(category)
            }
        }
    }

    private func isCategoryDisabled(_ category: ManualPlanCategory) -> Bool {
        selectedCategories.count >= 3 && !selectedCategories.contains(category)
    }

    private func placeSelectionKey(_ place: ManualPlanPlace) -> String {
        "\(place.category.dbValue)-\(place.name)-\(place.district)"
    }

    private func toggleDestination(_ place: ManualPlanPlace) {
        let key = placeSelectionKey(place)
        if selectedDestinationKeys.contains(key) {
            selectedDestinationKeys.remove(key)
        } else {
            selectedDestinationKeys.insert(key)
        }
    }

    private func pruneSelectedDestinations() {
        let allowedKeys = Set(
            ManualPlannerSeedData.places
                .filter { selectedCategories.contains($0.category) }
                .map(placeSelectionKey)
        )

        selectedDestinationKeys = selectedDestinationKeys.intersection(allowedKeys)
    }
}

private struct ManualPlanCategoryCard: View {
    let category: ManualPlanCategory
    let isSelected: Bool
    let isDisabled: Bool
    let imageName: String
    var onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.travelPrimary.opacity(0.28), Color.teal.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let uiImage = loadLocalImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.96)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                CategoryNameIndicator(category: category)
                    .padding(10)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.travelPrimary : .white.opacity(0.35), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isDisabled ? 0.42 : 1)
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.22), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func loadLocalImage(named name: String) -> UIImage? {
        let candidates = [
            name,
            "\(name).JPG",
            "\(name).jpg",
            "Images/\(name).JPG",
            "Images/\(name).jpg",
            "Assets/Images/\(name).JPG",
            "Assets/Images/\(name).jpg"
        ]

        for candidate in candidates {
            if let image = UIImage(named: candidate) {
                return image
            }
        }

        let searchDirectories: [String?] = [nil, "Images", "Assets", "Assets/Images"]
        let extensions = ["JPG", "jpg", "JPEG", "jpeg"]

        for directory in searchDirectories {
            for fileExtension in extensions {
                if let path = Bundle.main.path(forResource: name, ofType: fileExtension, inDirectory: directory),
                   let image = UIImage(contentsOfFile: path) {
                    return image
                }
            }
        }

        return nil
    }
}

private struct CategoryNameIndicator: View {
    let category: ManualPlanCategory
    var isHighlighted: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: category.icon)
                .font(.caption2.weight(.semibold))

            Text(category.rawValue)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(isHighlighted ? Color.travelPrimary.opacity(0.9) : .black.opacity(0.52))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(.white.opacity(isHighlighted ? 0.4 : 0.65), lineWidth: 1)
                )
        )
    }
}

private struct ManualPlanPlaceCard: View {
    let place: ManualPlanPlace
    let isSelected: Bool
    var onToggleSelection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.travelPrimary.opacity(0.9), Color.green.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let imageURL = place.imageURL {
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

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text(String(format: "%.1f", place.rating))
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.3), in: Capsule())
                .padding(8)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(place.name)
                .font(.headline)
                .foregroundStyle(Color.travelTitle)

            HStack(spacing: 10) {
                Label(place.district, systemImage: "mappin.and.ellipse")
                Label("\(String(format: "%.4f", place.latitude)), \(String(format: "%.4f", place.longitude))", systemImage: "location")
            }
            .font(.caption)
            .foregroundStyle(Color.travelBody)

            Text(place.description)
                .font(.subheadline)
                .foregroundStyle(Color.travelBody)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onToggleSelection()
            } label: {
                Text(isSelected ? "Selected" : "Select Destination")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.travelPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? Color.travelPrimary : Color.travelPrimary.opacity(0.14))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
    }
}

#Preview {
    ManualTripPlannerScreen()
}
