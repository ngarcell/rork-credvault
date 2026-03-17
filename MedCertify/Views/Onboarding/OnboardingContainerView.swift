import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    @Binding var onboardingComplete: Bool
    @State private var showPaywall: Bool = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            Group {
                switch viewModel.currentPage {
                case 0: OnboardingWelcomeView(viewModel: viewModel)
                case 1: OnboardingProfessionView(viewModel: viewModel)
                case 2: OnboardingStatesView(viewModel: viewModel)
                case 3: OnboardingCredentialTypesView(viewModel: viewModel)
                case 4: OnboardingNotificationsView(viewModel: viewModel)
                case 5: OnboardingTrialReminderView(viewModel: viewModel)
                case 6:
                    PaywallView(
                        onDismiss: { completeOnboarding(isPro: false) },
                        onSubscribe: { completeOnboarding(isPro: true) }
                    )
                default: OnboardingWelcomeView(viewModel: viewModel)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
        }
    }

    private func completeOnboarding(isPro: Bool) {
        viewModel.saveProfile(modelContext: modelContext)
        withAnimation(.spring(duration: 0.5)) {
            onboardingComplete = true
        }
    }
}
