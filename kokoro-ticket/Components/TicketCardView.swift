import SwiftUI

struct TicketCardView: View {
    let ticket: Ticket

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            IllustrationPlaceholderView(compact: true)
                .frame(height: 82)

            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)
                    .lineLimit(1)

                Text("\(ticket.senderName)から")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(14)
        .frame(width: 176, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 10, y: 5)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TicketCardView(ticket: MockTickets.received[0])
        .padding()
        .background(AppColors.background)
}
