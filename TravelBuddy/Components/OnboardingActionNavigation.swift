import SwiftUI

struct OnboardingActionNavigation: View {
    let leadingTitle: String
    let trailingTitle: String
    var leadingAction: () -> Void
    var trailingAction: () -> Void
    var showsTrailingChevron: Bool = true

    var body: some View {
        HStack {
            Button(action: leadingAction) {
                Text(leadingTitle)
                    .font(.headline)
                    .foregroundStyle(Color.travelPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: trailingAction) {
                HStack(spacing: 6) {
                    Text(trailingTitle)
                    if showsTrailingChevron {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .font(.headline)
                .foregroundStyle(Color.travelPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 10)
    }
}
