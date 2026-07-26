import SwiftUI

@MainActor
struct MainTabView: View {
    @State private var selection: AppTab = .home
    @State private var ticketStore: TicketStore
    @State private var friendStore: FriendStore
    @State private var realtimeCoordinator: RealtimeSyncCoordinator
    @State private var isShowingTicketDetail = false
    private let profileStore: ProfileStore
    private let currentUserID: UUID?
    private let currentUserEmail: String?
    private let isAuthLoading: Bool
    private let onLogout: () -> Void
    @Environment(\.scenePhase) private var scenePhase

    init(
        repository: any TicketRepository,
        friendRepository: any FriendRepository,
        profileStore: ProfileStore,
        currentUserID: UUID? = nil,
        currentUserEmail: String? = nil,
        isAuthLoading: Bool = false,
        realtimeService: (any RealtimeService)? = nil,
        onLogout: @escaping () -> Void = {}
    ) {
        let ticketStore = TicketStore(repository: repository)
        let friendStore = FriendStore(repository: friendRepository)
        _ticketStore = State(
            initialValue: ticketStore
        )
        _friendStore = State(
            initialValue: friendStore
        )
        _realtimeCoordinator = State(
            initialValue: RealtimeSyncCoordinator(
                service: realtimeService ?? InMemoryRealtimeService(),
                friendStore: friendStore,
                ticketStore: ticketStore
            )
        )
        self.profileStore = profileStore
        self.currentUserID = currentUserID
        self.currentUserEmail = currentUserEmail
        self.isAuthLoading = isAuthLoading
        self.onLogout = onLogout
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                NavigationStack {
                    HomeView()
                }
                .tag(AppTab.home)

                NavigationStack {
                    TicketListView(
                        store: ticketStore,
                        friendStore: friendStore,
                        onCreateTicket: {
                            selection = .create
                        },
                        onDetailVisibilityChange: { isShowing in
                            isShowingTicketDetail = isShowing
                        },
                        onTicketCompleted: {
                            isShowingTicketDetail = false
                            selection = .memories
                        }
                    )
                }
                    .tag(AppTab.tickets)

                TicketCreationFlowView(
                    onSave: { ticket in
                        _ = ticketStore.add(savedTicket: ticket)
                    },
                    onClose: {
                        selection = .home
                    }
                )
                    .tag(AppTab.create)

                NavigationStack {
                    MemoriesView(
                        store: ticketStore,
                        onCreateTicket: {
                            selection = .create
                        },
                        onDetailVisibilityChange: { isShowing in
                            isShowingTicketDetail = isShowing
                        }
                    )
                }
                    .tag(AppTab.memories)

                ProfileView(
                    store: profileStore,
                    friendStore: friendStore,
                    email: currentUserEmail,
                    isAuthLoading: isAuthLoading,
                    clipboard: SystemClipboardService(),
                    onLogout: onLogout
                )
                    .tag(AppTab.profile)
            }
            .toolbar(.hidden, for: .tabBar)

            if selection != .create && !isShowingTicketDetail {
                AppTabBar(selection: $selection)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            await ticketStore.reloadRemoteTickets()
        }
        .task(id: currentUserID) {
            guard let currentUserID else { return }
            await realtimeCoordinator.start(userID: currentUserID)
        }
        .onChange(of: scenePhase) { _, phase in
            guard let currentUserID else { return }
            Task {
                switch phase {
                case .active:
                    await realtimeCoordinator.resume(userID: currentUserID)
                case .background:
                    await realtimeCoordinator.stop()
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
        .onDisappear {
            Task {
                await realtimeCoordinator.stop()
            }
        }
        .overlay(alignment: .top) {
            if let error = realtimeCoordinator.connectionError {
                Button {
                    Task {
                        await realtimeCoordinator.retry()
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.clockwise")
                        Text(error.localizedDescription)
                            .lineLimit(1)
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(AppColors.cardBackground)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule().stroke(AppColors.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

}

private enum AppTab: String, CaseIterable {
    case home = "ホーム"
    case tickets = "チケット"
    case create = "作る"
    case memories = "思い出"
    case profile = "マイページ"

    var iconName: String {
        switch self {
        case .home: "house.fill"
        case .tickets: "ticket"
        case .create: "plus"
        case .memories: "photo"
        case .profile: "person"
        }
    }
}

private struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    if tab == .create {
                        createTab(tab)
                    } else {
                        standardTab(tab)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.border.opacity(0.55))
                .frame(height: 1)
        }
    }

    private func standardTab(_ tab: AppTab) -> some View {
        VStack(spacing: 5) {
            Image(systemName: tab.iconName)
                .font(.system(size: 21, weight: .semibold))

            Text(tab.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(selection == tab ? AppColors.primary : AppColors.textSecondary)
        .frame(height: 50)
    }

    private func createTab(_ tab: AppTab) -> some View {
        VStack(spacing: 4) {
            Image(systemName: tab.iconName)
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(AppColors.primary)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.25), radius: 8, y: 4)

            Text(tab.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(
                    selection == tab ? AppColors.primary : AppColors.textSecondary
                )
        }
        .offset(y: -13)
    }
}

#Preview {
    let profile = Profile.preview

    MainTabView(
        repository: InMemoryTicketRepository(
            tickets: MockTicketListItems.items.map(Ticket.init(item:))
        ),
        friendRepository: InMemoryFriendRepository(),
        profileStore: ProfileStore(
            repository: InMemoryProfileRepository(profile: profile),
            profile: profile,
            isLoading: false
        )
    )
}

#Preview("Realtime再接続中") {
    let profile = Profile.preview

    MainTabView(
        repository: InMemoryTicketRepository(),
        friendRepository: InMemoryFriendRepository(),
        profileStore: ProfileStore(
            repository: InMemoryProfileRepository(profile: profile),
            profile: profile,
            isLoading: false
        ),
        currentUserID: profile.id,
        realtimeService: InMemoryRealtimeService(
            startError: .realtimeConnectionFailed
        )
    )
}

#Preview("Realtime重複・順序逆転イベント") {
    let profile = Profile.preview
    let realtime = InMemoryRealtimeService()

    MainTabView(
        repository: InMemoryTicketRepository(
            tickets: MockTicketListItems.items.map(Ticket.init(item:))
        ),
        friendRepository: InMemoryFriendRepository(),
        profileStore: ProfileStore(
            repository: InMemoryProfileRepository(profile: profile),
            profile: profile,
            isLoading: false
        ),
        currentUserID: profile.id,
        realtimeService: realtime
    )
    .task {
        realtime.emit(RealtimeEvent(area: .tickets, table: "ticket_usage_requests"))
        realtime.emit(RealtimeEvent(area: .tickets, table: "ticket_transfers"))
        realtime.emit(RealtimeEvent(area: .tickets, table: "ticket_usage_requests"))
        realtime.emit(RealtimeEvent(area: .friends, table: "friend_requests"))
        realtime.emit(RealtimeEvent(area: .friends, table: "friendships"))
    }
}
