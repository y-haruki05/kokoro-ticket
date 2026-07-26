import SwiftUI

struct MemoryTicketCardView: View {
    let ticket: TicketListItem

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            IllustrationPlaceholderView(compact: true)
                .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 9) {
                Text(ticket.title.valueOrFallback("こころチケット"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)
                    .lineLimit(1)

                Text(ticket.message.valueOrFallback("ありがとうの気持ち"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    personLabel(title: "差出人", value: ticket.senderName)
                    personLabel(title: "宛先", value: ticket.receiverName ?? "未設定")
                }

                if let completedAt = ticket.completedAt {
                    Text("完了日：\(completedAt.formatted(date: .numeric, time: .omitted))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.85))
                }

                HStack(spacing: 10) {
                    dateLabel(title: "送信", date: ticket.sentAt)
                    dateLabel(title: "受取", date: ticket.receivedAt)
                    dateLabel(title: "依頼", date: ticket.requestedAt)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(17)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 9, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private func personLabel(title: String, value: String) -> some View {
        Text("\(title)：\(value.valueOrFallback("かぞく"))")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private func dateLabel(title: String, date: Date?) -> some View {
        Text("\(title)：\(date?.formatted(date: .numeric, time: .omitted) ?? "—")")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(AppColors.textSecondary.opacity(0.8))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private extension String {
    func valueOrFallback(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
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
