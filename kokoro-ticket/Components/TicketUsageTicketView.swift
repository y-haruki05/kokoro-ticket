import SwiftUI

struct TicketUsageTicketView: View {
    let ticket: TicketListItem

    var body: some View {
        VStack(spacing: 12) {
            IllustrationPlaceholderView(compact: true)
                .frame(width: 112, height: 78)

            VStack(spacing: 5) {
                Text(ticket.title)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)
                    .lineLimit(1)

                Text(ticket.message)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ticket.design.backgroundColor.color)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            TicketBorderShape(
                style: ticket.design.borderStyle,
                color: AppColors.primary
            )
        }
        .shadow(color: AppColors.shadow, radius: 14, y: 7)
    }
}

#Preview {
    TicketUsageTicketView(ticket: MockTicketListItems.items[0])
        .frame(width: 330, height: 230)
        .padding()
        .background(AppColors.primarySoft)
}
