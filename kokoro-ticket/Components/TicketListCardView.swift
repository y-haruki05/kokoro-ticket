import SwiftUI

/// チケットBOX用に相手・日時・状態の補足を加えた一覧カード
struct TicketListCardView: View {
    let ticket: TicketListItem

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TicketVisualView(
                title: ticket.title,
                message: ticket.message,
                illustration: ticket.illustration,
                design: ticket.design,
                senderName: displayName,
                date: displayDate,
                size: .compact
            )

            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                    .font(.system(size: 11, weight: .bold))
                Text(contextText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(statusColor)
            .padding(.horizontal, 11)
            .frame(height: 28)
            .background(statusColor.opacity(0.09))
            .clipShape(Capsule())
        }
    }

    private var displayName: String {
        ticket.perspective == .sender
            ? (ticket.receiverName ?? ticket.senderName)
            : ticket.senderName
    }

    private var displayDate: Date {
        ticket.completedAt
            ?? ticket.requestedAt
            ?? ticket.receivedAt
            ?? ticket.sentAt
            ?? ticket.createdAt
    }

    private var contextText: String {
        switch (ticket.perspective, ticket.status) {
        case (_, .draft): "編集・送信できます"
        case (.receiver, .sent): "受け取る"
        case (.receiver, .requested): "相手の対応待ち"
        case (.sender, .requested), (.local, .requested): "対応待ち"
        case (_, .completed): "完了しました"
        case (.sender, .sent), (.sender, .received), (.local, .sent): "送信済み"
        case (_, .received): "受け取りました"
        }
    }

    private var statusIcon: String {
        switch ticket.status {
        case .draft: "square.and.pencil"
        case .sent: "paperplane.fill"
        case .received: "checkmark.circle.fill"
        case .requested: "clock.fill"
        case .completed: "heart.fill"
        }
    }

    private var statusColor: Color {
        ticket.status == .completed ? AppColors.textSecondary : AppColors.primaryDark
    }
}

#Preview {
    TicketListCardView(ticket: MockTicketListItems.items[0])
        .padding()
        .background(AppColors.background)
}
