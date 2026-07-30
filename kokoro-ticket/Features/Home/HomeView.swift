import SwiftUI

@MainActor
struct HomeView: View {
    let ticketStore: TicketStore
    let notificationStore: NotificationStore
    let displayName: String
    var presentation: HomePreviewPresentation = .automatic
    var isResolvingDeepLink = false
    var onOpenNotification: (AppNotification) async -> Void = { _ in }
    var onOpenTickets: (TicketStatus) -> Void = { _ in }
    var onCreateTicket: () -> Void = {}
    var onDetailVisibilityChange: (Bool) -> Void = { _ in }

    @State private var showsNotifications = false
    @State private var hasAppeared = false
    @State private var isInitialLoad = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeLayout.sectionSpacing) {
                HomeHeaderView(
                    unreadCount: notificationStore.unreadCount,
                    onNotificationTap: { showsNotifications = true }
                )

                HomeGreetingView(displayName: displayName)

                if isLoading {
                    HomeLoadingView()
                } else {
                    if hasLoadError {
                        HomeErrorCard { await refresh() }
                    }

                    mainTicketSection
                    receivedTicketsSection
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .padding(.horizontal, HomeLayout.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 112)
        }
        .refreshable {
            await refresh()
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showsNotifications) {
            NotificationListView(
                store: notificationStore,
                isResolvingDeepLink: isResolvingDeepLink,
                onOpen: onOpenNotification
            )
        }
        .navigationDestination(for: HomeDestination.self) { destination in
            if case let .ticket(id) = destination {
                TicketDetailView(ticketID: id, store: ticketStore)
                    .onAppear { onDetailVisibilityChange(true) }
                    .onDisappear { onDetailVisibilityChange(false) }
            }
        }
        .task {
            guard presentation == .automatic else { return }
            await refresh()
            isInitialLoad = false
            revealOnce()
        }
        .onAppear {
            guard presentation != .automatic else { return }
            revealOnce()
        }
    }

    private var mainTicketSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            AppSectionHeader(title: "今日のこころチケット")

            if let ticket = featuredTicket {
                NavigationLink(value: HomeDestination.ticket(ticket.id)) {
                    HomeFeaturedTicketView(ticket: ticket)
                }
                .buttonStyle(.plain)
            } else {
                HomeFeaturedEmptyView(onCreate: onCreateTicket)
            }
        }
    }

    private var receivedTicketsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            AppSectionHeader(
                title: "受け取ったチケット",
                actionTitle: "すべて見る"
            ) {
                    onOpenTickets(.received)
            }

            if receivedTickets.isEmpty {
                HomeReceivedTicketsEmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(receivedTickets) { ticket in
                            NavigationLink(value: HomeDestination.ticket(ticket.id)) {
                                HomeCompactTicketView(ticket: ticket)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .contentMargins(.horizontal, 1, for: .scrollContent)
            }
        }
    }

    private var featuredTicket: TicketListItem? {
        let received = ticketStore.receivedTickets
        let priorities: [TicketStatus] = [.received, .sent, .requested]

        for status in priorities {
            if let ticket = received
                .filter({ $0.status == status })
                .max(by: { ($0.updatedAt) < ($1.updatedAt) }) {
                return ticket
            }
        }

        return ticketStore.completedTickets.max {
            ($0.completedAt ?? $0.updatedAt) < ($1.completedAt ?? $1.updatedAt)
        }
    }

    private var receivedTickets: [TicketListItem] {
        Array(
            ticketStore.receivedTickets
                .filter { $0.status != .completed }
                .sorted { ($0.sentAt ?? $0.updatedAt) > ($1.sentAt ?? $1.updatedAt) }
                .prefix(3)
        )
    }

    private var isLoading: Bool {
        presentation == .loading
            || (presentation == .automatic
                && (isInitialLoad
                    || (notificationStore.isLoading && ticketStore.tickets.isEmpty)))
    }

    private var hasLoadError: Bool {
        presentation == .error
            || (presentation == .automatic
                && (notificationStore.error != nil
                    || ticketStore.lastErrorMessage != nil))
    }

    private func refresh() async {
        async let tickets: Bool = ticketStore.reloadRemoteTickets()
        async let notifications: Void = notificationStore.reload()
        _ = await (tickets, notifications)
    }

    private func revealOnce() {
        guard !hasAppeared else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            hasAppeared = true
        }
    }
}

enum HomePreviewPresentation: Equatable {
    case automatic
    case loading
    case error
}

private enum HomeDestination: Hashable {
    case ticket(UUID)
}

#Preview("通常") {
    HomePreviewFactory.make()
}

#Preview("受取チケットなし") {
    HomePreviewFactory.make(tickets: [])
}

#Preview("メインチケットあり") {
    HomePreviewFactory.make(tickets: HomePreviewData.normalTickets)
}

#Preview("Loading") {
    HomePreviewFactory.make(presentation: .loading)
}

#Preview("Error") {
    HomePreviewFactory.make(presentation: .error)
}
