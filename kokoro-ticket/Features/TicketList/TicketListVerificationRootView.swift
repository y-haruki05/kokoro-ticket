#if DEBUG
import SwiftUI

@MainActor
struct TicketListVerificationRootView: View {
    var body: some View {
        NavigationStack {
            if CommandLine.arguments.contains("-ticket-detail-preview"),
               let ticket = tickets.first {
                TicketDetailView(
                    ticketID: ticket.id,
                    store: TicketStore(previewTickets: tickets),
                    friendStore: FriendStore(
                        repository: InMemoryFriendRepository()
                    )
                )
            } else {
                TicketListView(
                    store: TicketStore(previewTickets: tickets),
                    friendStore: FriendStore(
                        repository: InMemoryFriendRepository()
                    ),
                    onCreateTicket: {},
                    initialStatus: initialStatus,
                    loadsRemoteData: false
                )
            }
        }
    }

    private var tickets: [TicketListItem] {
        CommandLine.arguments.contains("-ticket-list-empty")
            ? []
            : MockTicketListItems.allPerspectives
    }

    private var initialStatus: TicketStatus {
        guard
            let rawValue = CommandLine.arguments
                .first(where: { $0.hasPrefix("-ticket-status=") })?
                .split(separator: "=")
                .last
        else {
            return .draft
        }
        return TicketStatus(rawValue: String(rawValue)) ?? .draft
    }
}
#endif
