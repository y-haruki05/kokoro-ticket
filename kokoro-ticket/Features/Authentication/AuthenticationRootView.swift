import SwiftUI

// スプラッシュ、セッション復元、プロフィール有無を判定して起動画面を切り替えるView
@MainActor
struct AuthenticationRootView: View {
    private let ticketRepository: any TicketRepository
    private let friendRepository: any FriendRepository
    private let notificationRepository: any NotificationRepository
    private let realtimeService: any RealtimeService
    private let tutorialCompletionStore: any TutorialCompletionStoring
    @State private var sessionStore: SessionStore
    @State private var profileStore: ProfileStore
    @State private var didRestoreSession = false
    @State private var didReachSplashMinimumDuration = false
    @State private var didFinishInitialSplash = false
    /// セッション切替時に前ユーザーのプロフィールを表示しないための読込済みID
    @State private var loadedProfileUserID: UUID?
    @State private var isCompletingProfileSetup = false
    @State private var hasCompletedTutorial: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        authRepository: any AuthRepository,
        profileRepository: any ProfileRepository,
        friendRepository: any FriendRepository,
        notificationRepository: (any NotificationRepository)? = nil,
        ticketRepository: any TicketRepository,
        realtimeService: (any RealtimeService)? = nil,
        tutorialCompletionStore: (any TutorialCompletionStoring)? = nil
    ) {
        self.ticketRepository = ticketRepository
        self.friendRepository = friendRepository
        self.notificationRepository = notificationRepository ?? InMemoryNotificationRepository()
        self.realtimeService = realtimeService ?? InMemoryRealtimeService()
        let tutorialStore = tutorialCompletionStore ?? UserDefaultsTutorialCompletionStore()
        #if DEBUG
        if CommandLine.arguments.contains("-reset-tutorial") {
            tutorialStore.hasCompletedTutorial = false
        }
        #endif
        self.tutorialCompletionStore = tutorialStore
        _hasCompletedTutorial = State(
            initialValue: tutorialStore.hasCompletedTutorial
        )
        _sessionStore = State(
            initialValue: SessionStore(repository: authRepository)
        )
        _profileStore = State(
            initialValue: ProfileStore(repository: profileRepository)
        )
    }

    var body: some View {
        ZStack {
            destination

            if shouldShowInitialTutorial {
                TutorialView(
                    mode: .firstLaunch,
                    onDismiss: completeInitialTutorial
                )
                .transition(.opacity)
                .zIndex(1)
            }

            if shouldShowSplash {
                AppSplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(
            reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.3),
            value: shouldShowSplash
        )
        .onChange(of: shouldShowSplash) { wasShowing, isShowing in
            if wasShowing && !isShowing {
                didFinishInitialSplash = true
            }
        }
        .task {
            guard !didReachSplashMinimumDuration else { return }
            do {
                try await Task.sleep(for: .milliseconds(900))
            } catch {
                return
            }
            didReachSplashMinimumDuration = true
        }
        .task {
            guard !didRestoreSession else { return }
            await sessionStore.restoreSession()
            didRestoreSession = true
        }
        .task(id: sessionStore.currentUser?.id) {
            guard let userID = sessionStore.currentUser?.id else {
                loadedProfileUserID = nil
                isCompletingProfileSetup = false
                profileStore.reset()
                return
            }

            loadedProfileUserID = nil
            await profileStore.loadProfile(hasAuthenticatedUser: true)
            loadedProfileUserID = userID
        }
    }

    @ViewBuilder
    private var destination: some View {
        if !didRestoreSession {
            Color.white.ignoresSafeArea()
        } else if !sessionStore.isAuthenticated {
            LoginView(store: sessionStore)
        } else if loadedProfileUserID != sessionStore.currentUser?.id {
            authenticatedLoadingView
        } else if !profileStore.isProfileCompleted || isCompletingProfileSetup {
            ProfileSetupView(
                store: profileStore,
                onCompletionStateChange: { isCompletingProfileSetup = $0 }
            )
        } else {
            MainTabView(
                repository: ticketRepository,
                friendRepository: friendRepository,
                notificationRepository: notificationRepository,
                profileStore: profileStore,
                currentUserID: sessionStore.currentUser?.id,
                currentUserEmail: sessionStore.currentUser?.email,
                isAuthLoading: sessionStore.isLoading,
                realtimeService: realtimeService,
                onLogout: {
                    Task {
                        await sessionStore.signOut()
                    }
                }
            )
        }
    }

    /// 最低表示時間と初期データ準備の両方が完了するまでスプラッシュを維持する
    private var shouldShowSplash: Bool {
        guard !didFinishInitialSplash else { return false }

        guard didReachSplashMinimumDuration, didRestoreSession else {
            return true
        }

        if sessionStore.isAuthenticated {
            return loadedProfileUserID != sessionStore.currentUser?.id
        }

        return false
    }

    private var shouldShowInitialTutorial: Bool {
        !hasCompletedTutorial && isInitialPreparationComplete
    }

    private var isInitialPreparationComplete: Bool {
        guard didReachSplashMinimumDuration, didRestoreSession else {
            return false
        }

        if sessionStore.isAuthenticated {
            return loadedProfileUserID == sessionStore.currentUser?.id
        }

        return true
    }

    private func completeInitialTutorial() {
        tutorialCompletionStore.hasCompletedTutorial = true
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            hasCompletedTutorial = true
        }
    }

    private var authenticatedLoadingView: some View {
        VStack(spacing: 14) {
            Image("cat_default")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 76)

            ProgressView()
                .tint(AppColors.primary)

            Text("準備しています")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}

#Preview("未ログイン") {
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
        ticketRepository: InMemoryTicketRepository(),
        tutorialCompletionStore: InMemoryTutorialCompletionStore(
            hasCompletedTutorial: true
        )
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
        ticketRepository: InMemoryTicketRepository(),
        tutorialCompletionStore: InMemoryTutorialCompletionStore(
            hasCompletedTutorial: true
        )
    )
}
