import SwiftUI

struct AuthenticationRootView: View {
    private let ticketRepository: any TicketRepository
    @State private var sessionStore: SessionStore
    @State private var didRestoreSession = false

    init(
        authRepository: any AuthRepository,
        ticketRepository: any TicketRepository
    ) {
        self.ticketRepository = ticketRepository
        _sessionStore = State(
            initialValue: SessionStore(repository: authRepository)
        )
    }

    var body: some View {
        Group {
            if !didRestoreSession {
                launchView
            } else if sessionStore.isAuthenticated {
                MainTabView(
                    repository: ticketRepository,
                    currentUserEmail: sessionStore.currentUser?.email,
                    isAuthLoading: sessionStore.isLoading,
                    onLogout: {
                        Task {
                            await sessionStore.signOut()
                        }
                    }
                )
            } else {
                LoginView(store: sessionStore)
            }
        }
        .authErrorAlert(store: sessionStore)
        .task {
            guard !didRestoreSession else { return }
            await sessionStore.restoreSession()
            didRestoreSession = true
        }
    }

    private var launchView: some View {
        VStack(spacing: 18) {
            Text("こころチケット")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)

            ProgressView()
                .tint(AppColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview("未ログイン") {
    AuthenticationRootView(
        authRepository: InMemoryAuthRepository(),
        ticketRepository: InMemoryTicketRepository()
    )
}

#Preview("ログイン済み") {
    AuthenticationRootView(
        authRepository: InMemoryAuthRepository(
            session: AuthSession(
                user: AuthUser(id: UUID(), email: "preview@example.com"),
                expiresAt: .now.addingTimeInterval(3_600)
            )
        ),
        ticketRepository: InMemoryTicketRepository()
    )
}
