import SwiftUI

struct TicketListView: View {
    let store: TicketStore
    let friendStore: FriendStore
    let onCreateTicket: () -> Void
    var onDetailVisibilityChange: (Bool) -> Void = { _ in }

    @State private var selectedStatus: TicketStatus

    init(
        store: TicketStore,
        friendStore: FriendStore,
        onCreateTicket: @escaping () -> Void,
        onDetailVisibilityChange: @escaping (Bool) -> Void = { _ in },
        initialStatus: TicketStatus = .draft
    ) {
        self.store = store
        self.friendStore = friendStore
        self.onCreateTicket = onCreateTicket
        self.onDetailVisibilityChange = onDetailVisibilityChange
        _selectedStatus = State(initialValue: initialStatus)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("チケット一覧")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 22)

            TicketListSegmentedControl(selection: $selectedStatus)

            ScrollView {
                if filteredTickets.isEmpty {
                    TicketListEmptyView(onCreateTicket: onCreateTicket)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredTickets) { ticket in
                            NavigationLink(value: ticket.id) {
                                TicketListCardView(ticket: ticket)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 112)
                }
            }
            .contentMargins(.top, 1, for: .scrollContent)
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
                }
            )
                .onAppear {
                    onDetailVisibilityChange(true)
                }
                .onDisappear {
                    onDetailVisibilityChange(false)
                }
        }
        .refreshable {
            store.reload()
            await store.reloadRemoteTickets()
        }
        .task {
            await store.reloadRemoteTickets()
        }
        .overlay(alignment: .bottom) {
            if let message = store.requestMessage ?? store.sendMessage {
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
            store: TicketStore(tickets: MockTicketListItems.items),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {}
        )
    }
}

#Preview("送った") {
    NavigationStack {
        TicketListView(
            store: TicketStore(tickets: MockTicketListItems.items),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .sent
        )
    }
}

#Preview("受け取った") {
    NavigationStack {
        TicketListView(
            store: TicketStore(tickets: MockTicketListItems.items),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .received
        )
    }
}

#Preview("リクエスト中・対応待ち") {
    NavigationStack {
        TicketListView(
            store: TicketStore(tickets: MockTicketListItems.items),
            friendStore: FriendStore(repository: InMemoryFriendRepository()),
            onCreateTicket: {},
            initialStatus: .requested
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
            initialStatus: .received
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
            initialStatus: .received
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
            onCreateTicket: {}
        )
    }
}
