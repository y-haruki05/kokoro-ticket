import SwiftUI

struct AuthenticationRootView: View {
    private let ticketRepository: any TicketRepository
    private let friendRepository: any FriendRepository
    @State private var sessionStore: SessionStore
    @State private var profileStore: ProfileStore
    @State private var didRestoreSession = false
    @State private var loadedProfileUserID: UUID?

    init(
        authRepository: any AuthRepository,
        profileRepository: any ProfileRepository,
        friendRepository: any FriendRepository,
        ticketRepository: any TicketRepository
    ) {
        self.ticketRepository = ticketRepository
        self.friendRepository = friendRepository
        _sessionStore = State(
            initialValue: SessionStore(repository: authRepository)
        )
        _profileStore = State(
            initialValue: ProfileStore(repository: profileRepository)
        )
    }

    var body: some View {
        Group {
            if !didRestoreSession {
                launchView
            } else if !sessionStore.isAuthenticated {
                LoginView(store: sessionStore)
            } else if loadedProfileUserID != sessionStore.currentUser?.id
                        || profileStore.isLoading {
                launchView
            } else if !profileStore.isProfileCompleted {
                ProfileSetupView(store: profileStore)
            } else {
                MainTabView(
                    repository: ticketRepository,
                    friendRepository: friendRepository,
                    profileStore: profileStore,
                    currentUserEmail: sessionStore.currentUser?.email,
                    isAuthLoading: sessionStore.isLoading,
                    onLogout: {
                        Task {
                            await sessionStore.signOut()
                        }
                    }
                )
            }
        }
        .authErrorAlert(store: sessionStore)
        .task {
            guard !didRestoreSession else { return }
            await sessionStore.restoreSession()
            didRestoreSession = true
        }
        .task(id: sessionStore.currentUser?.id) {
            guard let userID = sessionStore.currentUser?.id else {
                loadedProfileUserID = nil
                profileStore.reset()
                return
            }

            loadedProfileUserID = nil
            await profileStore.loadProfile(hasAuthenticatedUser: true)
            loadedProfileUserID = userID
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
        profileRepository: InMemoryProfileRepository(),
        friendRepository: InMemoryFriendRepository(),
        ticketRepository: InMemoryTicketRepository()
    )
}

#Preview("ログイン済み") {
    let userID = UUID()
    let profile = Profile(
        id: userID,
        displayName: "こころ",
        friendCode: "KRTK7M2P",
        avatarKey: nil,
        createdAt: .now,
        updatedAt: .now
    )

    AuthenticationRootView(
        authRepository: InMemoryAuthRepository(
            session: AuthSession(
                user: AuthUser(id: userID, email: "preview@example.com"),
                expiresAt: .now.addingTimeInterval(3_600)
            )
        ),
        profileRepository: InMemoryProfileRepository(
            currentUserID: userID,
            profile: profile
        ),
        friendRepository: InMemoryFriendRepository(currentUserID: userID),
        ticketRepository: InMemoryTicketRepository()
    )
}

#Preview("プロフィール未設定") {
    let userID = UUID()

    AuthenticationRootView(
        authRepository: InMemoryAuthRepository(
            session: AuthSession(
                user: AuthUser(id: userID, email: "preview@example.com"),
                expiresAt: .now.addingTimeInterval(3_600)
            )
        ),
        profileRepository: InMemoryProfileRepository(currentUserID: userID),
        friendRepository: InMemoryFriendRepository(currentUserID: userID),
        ticketRepository: InMemoryTicketRepository()
    )
}
