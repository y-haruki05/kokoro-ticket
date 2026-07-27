import SwiftUI

struct TicketListCardView: View {
    let ticket: TicketListItem

    var body: some View {
        TicketVisualView(
            title: ticket.title,
            message: ticket.message,
            illustration: ticket.illustration,
            design: ticket.design,
            senderName: displayName,
            date: ticket.sentAt ?? ticket.createdAt,
            size: .compact
        )
    }

    private var displayName: String {
        ticket.perspective == .sender
            ? (ticket.receiverName ?? ticket.senderName)
            : ticket.senderName
    }
}

#Preview {
    TicketListCardView(ticket: MockTicketListItems.items[0])
        .padding()
        .background(AppColors.background)
}
