import SwiftUI

struct MemoryTicketCardView: View {
    let ticket: TicketListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            TicketVisualView(
                title: ticket.title,
                message: ticket.message,
                illustration: ticket.illustration,
                design: ticket.design,
                senderName: ticket.senderName,
                date: ticket.completedAt ?? ticket.updatedAt,
                size: .compact
            )

            if let completedAt = ticket.completedAt {
                Text("思い出になった日：\(completedAt.formatted(date: .numeric, time: .omitted))")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 8)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MemoryTicketCardView(
        ticket: MockTicketListItems.items.first { $0.status == .completed }
            ?? MockTicketListItems.items[0]
    )
    .padding()
    .background(AppColors.background)
}
