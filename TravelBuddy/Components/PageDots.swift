import SwiftUI

struct PageDots: View {
    let activeIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == activeIndex ? Color.travelPrimary : Color.gray.opacity(0.25))
                    .frame(width: index == activeIndex ? 18 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
            }
        }
        .accessibilityLabel("Page \(activeIndex + 1) of \(count)")
    }
}
