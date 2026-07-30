import SwiftUI

struct TicketListView: View {
    let store: TicketStore
    let friendStore: FriendStore
    let onCreateTicket: () -> Void
    var onDetailVisibilityChange: (Bool) -> Void = { _ in }
    var onTicketCompleted: () -> Void = {}
    private let loadsRemoteData: Bool

    @State private var selectedStatus: TicketStatus

    init(
        store: TicketStore,
        friendStore: FriendStore,
        onCreateTicket: @escaping () -> Void,
        onDetailVisibilityChange: @escaping (Bool) -> Void = { _ in },
        onTicketCompleted: @escaping () -> Void = {},
        initialStatus: TicketStatus = .draft,
        loadsRemoteData: Bool = true
    ) {
        self.store = store
        self.friendStore = friendStore
        self.onCreateTicket = onCreateTicket
        self.onDetailVisibilityChange = onDetailVisibilityChange
        self.onTicketCompleted = onTicketCompleted
        self.loadsRemoteData = loadsRemoteData
        _selectedStatus = State(initialValue: initialStatus)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("チケットBOX")
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.primary)

                Text("大切なチケットをひらいてみよう")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
            .padding(.bottom, 18)

            TicketListSegmentedControl(selection: $selectedStatus)

            ScrollView {
                if store.isReloadingRemote && filteredTickets.isEmpty {
                    TicketListLoadingView()
                } else if store.lastErrorMessage != nil && filteredTickets.isEmpty {
                    TicketListLoadErrorView {
                        Task {
                            store.reload()
                            await store.reloadRemoteTickets()
                        }
                    }
                } else if filteredTickets.isEmpty {
                    TicketListEmptyView(
                        status: selectedStatus,
                        onCreateTicket: onCreateTicket
                    )
                } else {
                    LazyVStack(spacing: AppLayout.cardSpacing) {
                        ForEach(filteredTickets) { ticket in
                            NavigationLink(value: ticket.id) {
                                TicketListCardView(ticket: ticket)
                            }
                            .buttonStyle(.plain)
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.98))
                            )
                        }
                    }
                    .padding(.horizontal, AppLayout.screenHorizontalPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 112)
                    .animation(
                        .easeInOut(duration: 0.22),
                        value: filteredTickets.map(\.id)
                    )
                }
            }
            .contentMargins(.top, 1, for: .scrollContent)
            .refreshable {
                store.reload()
                if loadsRemoteData {
                    await store.reloadRemoteTickets()
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: TicketListItem.ID.self) { ticketID in
            TicketDetailView(
                ticketID: ticketID,
                store: store,
                friendStore: friendStore,
                onTicketSent: {
                    selectedStatus = .sent
                },
                onTicketCompleted: onTicketCompleted
            )
                .onAppear {
                    onDetailVisibilityChange(true)
                }
                .onDisappear {
                    onDetailVisibilityChange(false)
                }
        }
        .task {
            if loadsRemoteData {
                await store.reloadRemoteTickets()
            }
        }
        .overlay(alignment: .bottom) {
            if let message = store.completionMessage
                ?? store.requestMessage
                ?? store.sendMessage {
                Text(message)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(AppColors.primaryDark)
                    .clipShape(Capsule())
                    .padding(.bottom, 92)
                    .transition(.opacity)
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(2))
                        store.clearSendMessage()
                        store.clearRequestMessage()
                        store.clearCompletionMessage()
                    }
            }
        }
        .alert(
            "チケットを送信できませんでした",
            isPresented: Binding(
                get: { store.sendError != nil },
                set: { if !$0 { store.clearSendError() } }
            ),
            presenting: store.sendError
        ) { _ in
            Button("OK") { store.clearSendError() }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            "チケットを完了できませんでした",
            isPresented: Binding(
                get: { store.completionError != nil },
                set: { if !$0 { store.clearCompletionError() } }
            ),
            presenting: store.completionError
        ) { _ in
            Button("OK") { store.clearCompletionError() }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            "チケットを更新できませんでした",
            isPresented: Binding(
                get: { store.requestError != nil },
                set: { if !$0 { store.clearRequestError() } }
            ),
            presenting: store.requestError
        ) { _ in
            Button("OK") { store.clearRequestError() }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private var filteredTickets: [TicketListItem] {
        store.tickets(for: selectedStatus)
    }
}

#Preview {
    NavigationStack {
        TicketListView(
            store: TicketStore(previewTickets: MockTicketListItems.allPerspectives),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            loadsRemoteData: false
        )
    }
}

#Preview("送った") {
    NavigationStack {
        TicketListView(
            store: TicketStore(previewTickets: MockTicketListItems.senderItems),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .sent,
            loadsRemoteData: false
        )
    }
}

#Preview("受け取った") {
    NavigationStack {
        TicketListView(
            store: TicketStore(previewTickets: MockTicketListItems.receiverItems),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .received,
            loadsRemoteData: false
        )
    }
}

#Preview("リクエスト中・対応待ち") {
    NavigationStack {
        TicketListView(
            store: TicketStore(previewTickets: MockTicketListItems.allPerspectives),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .requested,
            loadsRemoteData: false
        )
    }
}

#Preview("リクエスト処理中") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                repository: InMemoryTicketRepository(
                    tickets: MockTicketListItems.items.map(Ticket.init(item:))
                ),
                isRequesting: true
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .received,
            loadsRemoteData: false
        )
    }
}

#Preview("対応待ち・送り主") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                previewTickets: MockTicketListItems.senderItems
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .requested,
            loadsRemoteData: false
        )
    }
}

#Preview("対応待ち・受取人") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                previewTickets: MockTicketListItems.receiverItems
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .requested,
            loadsRemoteData: false
        )
    }
}

#Preview("完了したチケット") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                previewTickets: MockTicketListItems.allPerspectives
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .completed,
            loadsRemoteData: false
        )
    }
}

#Preview("0件") {
    NavigationStack {
        TicketListView(
            store: TicketStore(previewTickets: []),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            loadsRemoteData: false
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                previewTickets: [],
                isReloadingRemote: true
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            loadsRemoteData: false
        )
    }
}

#Preview("読み込みエラー") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                previewTickets: [],
                lastErrorMessage: "チケットの読み込みに失敗しました"
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            loadsRemoteData: false
        )
    }
}

#Preview("Dark Mode", traits: .fixedLayout(width: 393, height: 852)) {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                previewTickets: MockTicketListItems.allPerspectives
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .received,
            loadsRemoteData: false
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("iPhone SE", traits: .fixedLayout(width: 375, height: 667)) {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                previewTickets: MockTicketListItems.allPerspectives
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            loadsRemoteData: false
        )
    }
}

#Preview("リクエストエラー") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                repository: InMemoryTicketRepository(
                    tickets: MockTicketListItems.items.map(Ticket.init(item:))
                ),
                requestError: .ticketTransfer(
                    description: "使用リクエストを送信できませんでした"
                )
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .received,
            loadsRemoteData: false
        )
    }
}

#Preview("送信エラー") {
    NavigationStack {
        TicketListView(
            store: TicketStore(
                repository: InMemoryTicketRepository(
                    tickets: MockTicketListItems.items.map(Ticket.init(item:))
                ),
                sendError: .ticketReceiverNotFriend
            ),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            loadsRemoteData: false
        )
    }
}
