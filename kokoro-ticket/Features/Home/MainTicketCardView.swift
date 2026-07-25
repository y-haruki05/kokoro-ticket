import SwiftUI

struct MainTicketCardView: View {
    let ticket: Ticket

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 5) {
                Text(ticket.title)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)

                Text(ticket.message)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primary)
            }

            IllustrationPlaceholderView()
                .frame(height: 130)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(AppColors.border, lineWidth: 1.5)
        }
        .shadow(color: AppColors.shadow, radius: 14, y: 7)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MainTicketCardView(ticket: MockTickets.today)
        .padding()
        .background(AppColors.background)
}
