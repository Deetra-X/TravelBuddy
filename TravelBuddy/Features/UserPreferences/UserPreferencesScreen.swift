import SwiftUI

struct UserPreferencesScreen: View {
    @ObservedObject var viewModel: UserPreferencesViewModel
    let onPreferencesSelected: () -> Void
    let onSkip: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("What are we do?")
                        .font(.title2.bold())
                        .foregroundStyle(Color.travelTitle)
                    
                    Text("Tell us your travel preferences and we'll create personalized activity plans for you. Don't worry, you can always change it later in the settings.")
                        .font(.body)
                        .foregroundStyle(Color.travelBody)
                        .lineLimit(nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                
                // Activities Grid
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ActivityCategory.allCategories) { activity in
                                ActivityCategoryButton(
                                    activity: activity,
                                    isSelected: viewModel.isActivitySelected(activity.id),
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.toggleActivitySelection(activity)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Selection Counter
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("\(viewModel.getSelectedCount())/4")
                                    .font(.headline.bold())
                                    .foregroundStyle(Color.travelPrimary)
                                
                                Text("Selected")
                                    .font(.caption)
                                    .foregroundStyle(Color.travelBody)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                    }
                    .padding(.vertical, 16)
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            try? await viewModel.savePreferences()
                            onPreferencesSelected()
                        }
                    }) {
                        HStack {
                            Text("Continue")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(.white)
                        .background(
                            viewModel.getSelectedCount() == 4 ?
                            Color.travelPrimary :
                            Color.travelPrimary.opacity(0.5)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.getSelectedCount() != 4)
                    
                    Button(action: {
                        Task {
                            try? await viewModel.skipPreferenceSetup()
                            onSkip()
                        }
                    }) {
                        Text("Skip for now")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(Color.travelPrimary)
                            .background(Color.travelPrimary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Activity Category Button
struct ActivityCategoryButton: View {
    let activity: ActivityCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(activity.emoji)
                    .font(.system(size: 32))
                
                Text(activity.name)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.travelTitle)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.travelPrimary.opacity(0.15) : Color.white)
            .border(
                isSelected ? Color.travelPrimary : Color.travelPrimary.opacity(0.2),
                width: 2
            )
            .cornerRadius(12)
            .overlay(
                isSelected ?
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.travelPrimary)
                            .font(.system(size: 20))
                    }
                    Spacer()
                }
                .padding(8)
                : nil
            )
        }
    }
}

#Preview {
    UserPreferencesScreen(
        viewModel: UserPreferencesViewModel(),
        onPreferencesSelected: {},
        onSkip: {}
    )
}
