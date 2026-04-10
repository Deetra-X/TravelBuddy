import SwiftUI

struct AdvancedSettingsScreen: View {
    var onClose: () -> Void

    @State private var showClearHistoryAlert = false
    @State private var showClearTripAlert = false
    @State private var showDeleteAccountAlert = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Manage your advanced account data and actions.")
                    .font(.subheadline)
                    .foregroundStyle(Color.travelBody)

                advancedRow(
                    icon: "clock.arrow.circlepath",
                    title: "Clear History",
                    subtitle: "Remove search and activity history",
                    tint: Color.travelTitle
                ) {
                    showClearHistoryAlert = true
                }

                advancedRow(
                    icon: "suitcase.rolling",
                    title: "Clear Trip",
                    subtitle: "Remove saved trip plans and local trip data",
                    tint: Color.travelTitle
                ) {
                    showClearTripAlert = true
                }

                advancedRow(
                    icon: "trash",
                    title: "Delete Account",
                    subtitle: "Permanently remove your account and data",
                    tint: .red
                ) {
                    showDeleteAccountAlert = true
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .background(Color.travelBackground.ignoresSafeArea())
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onClose()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color.travelTitle)
                    }
                }
            }
            .alert("Clear History", isPresented: $showClearHistoryAlert) {
                Button("Clear", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear your history.")
            }
            .alert("Clear Trip", isPresented: $showClearTripAlert) {
                Button("Clear", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear your trip data.")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    @ViewBuilder
    private func advancedRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(tint)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.travelBody)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.travelBody)
                    .padding(.top, 3)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
