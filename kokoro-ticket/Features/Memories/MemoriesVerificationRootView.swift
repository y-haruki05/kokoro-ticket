#if DEBUG
import SwiftUI

@MainActor
struct MemoriesVerificationRootView: View {
    var body: some View {
        NavigationStack {
            if CommandLine.arguments.contains("-memories-detail"),
               let ticket = tickets.first {
                MemoryDetailView(
                    ticketID: ticket.id,
                    store: TicketStore(previewTickets: tickets)
                )
            } else {
                MemoriesView(
                    store: TicketStore(previewTickets: tickets),
                    onCreateTicket: {}
                )
            }
        }
    }

    private var tickets: [TicketListItem] {
        if CommandLine.arguments.contains("-memories-empty") {
            return []
        }
        if CommandLine.arguments.contains("-memories-single") {
            return [MemoryPreviewData.single]
        }
        if CommandLine.arguments.contains("-memories-long-text") {
            return [MemoryPreviewData.longText]
        }
        return MemoryPreviewData.multipleMonths
    }
}
#endif
