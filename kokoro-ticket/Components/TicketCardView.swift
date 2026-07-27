import SwiftUI

struct TicketCardView: View {
    let ticket: Ticket

    var body: some View {
        TicketVisualView(
            title: ticket.title,
            message: ticket.message,
            illustration: ticket.illustration.map(TicketIllustration.init(id:)),
            design: TicketDesign(
                backgroundColor: TicketBackgroundColor(rawValue: ticket.backgroundColor) ?? .white,
                borderStyle: TicketBorderStyle(rawValue: ticket.borderStyle) ?? .simple
            ),
            senderName: ticket.senderName,
            date: ticket.createdAt,
            size: .compact
        )
        .frame(width: 210)
    }
}

#Preview {
    TicketCardView(ticket: MockTickets.received[0])
        .padding()
        .background(AppColors.background)
}
