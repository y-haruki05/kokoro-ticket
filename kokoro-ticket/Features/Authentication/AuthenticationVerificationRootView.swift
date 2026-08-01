#if DEBUG
import SwiftUI

struct AuthenticationVerificationRootView: View {
    var body: some View {
        if CommandLine.arguments.contains("-auth-splash") {
            AppSplashView()
        } else if CommandLine.arguments.contains("-auth-register") {
            NavigationStack {
                RegisterView(store: previewSessionStore)
            }
        } else if CommandLine.arguments.contains("-auth-confirmation") {
            EmailConfirmationPendingView(
                email: "kokoro@example.com",
                onReturnToLogin: {}
            )
        } else if CommandLine.arguments.contains("-auth-profile") {
            ProfileSetupView(store: previewProfileStore)
        } else if CommandLine.arguments.contains("-auth-profile-success") {
            ProfileSetupView(
                store: previewProfileStore,
                initiallyShowsCompletion: true
            )
        } else {
            AuthenticationRootView(
                authRepository: InMemoryAuthRepository(),
                profileRepository: InMemoryProfileRepository(),
                friendRepository: InMemoryFriendRepository(),
                ticketRepository: InMemoryTicketRepository(),
                tutorialCompletionStore: InMemoryTutorialCompletionStore(
                    hasCompletedTutorial: true
                )
            )
        }
    }

    private var previewSessionStore: SessionStore {
        SessionStore(
            repository: InMemoryAuthRepository(
                signUpRequiresEmailConfirmation: true
            ),
            isLoading: false
        )
    }

    private var previewProfileStore: ProfileStore {
        ProfileStore(
            repository: InMemoryProfileRepository(),
            isLoading: false
        )
    }
}
#endif
