import SwiftUI

struct TicketListCardView: View {
    let ticket: TicketListItem

    var body: some View {
        HStack(spacing: 15) {
            IllustrationPlaceholderView(compact: true)
                .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 8) {
                Text(ticket.title.valueOrFallback("こころチケット"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)
                    .lineLimit(1)

                Text("\(ticket.counterpartLabel)：\(ticket.counterpartName.valueOrFallback("かぞく"))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)

                Text(ticket.createdAt.formatted(date: .numeric, time: .omitted))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.8))
            }

            Spacer(minLength: 4)

            TicketStatusLabel(status: ticket.status)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 9, y: 4)
        .accessibilityElement(children: .combine)
    }
}

private extension String {
    func valueOrFallback(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

#Preview {
    TicketListCardView(ticket: MockTicketListItems.items[0])
        .padding()
        .background(AppColors.background)
}
