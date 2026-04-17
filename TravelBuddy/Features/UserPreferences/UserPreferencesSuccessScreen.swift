import SwiftUI

struct UserPreferencesSuccessScreen: View {
    @ObservedObject var viewModel: UserPreferencesViewModel
    let onComplete: () -> Void
    
    var selectedActivities: [ActivityCategory] {
        viewModel.userPreferences.selectedActivities
    }
    
    var body: some View {
        ZStack {
            Color.travelBackground.ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Success Icon
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.travelPrimary, lineWidth: 4)
                            .frame(width: 124, height: 124)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundStyle(Color.travelPrimary)
                    }
                    
                    Text("All Set!")
                        .font(.title.bold())
                        .foregroundStyle(Color.travelTitle)
                }
                
                // Success Message
                VStack(spacing: 12) {
                    Text("Your Adventure Preferences")
                        .font(.headline)
                        .foregroundStyle(Color.travelTitle)
                    
                    Text("We'll use these preferences to create personalized 3-day activity plans just for you.")
                        .font(.body)
                        .foregroundStyle(Color.travelBody)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Selected Activities Preview
                VStack(spacing: 12) {
                    ForEach(selectedActivities) { activity in
                        HStack(spacing: 12) {
                            Text(activity.emoji)
                                .font(.system(size: 24))
                            
                            Text(activity.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.travelTitle)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.travelPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.travelPrimary.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Done Button
                Button(action: onComplete) {
                    HStack {
                        Text("Go to Home")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundStyle(.white)
                    .background(Color.travelPrimary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    let viewModel = UserPreferencesViewModel()
    UserPreferencesSuccessScreen(
        viewModel: viewModel,
        onComplete: {}
    )
}
