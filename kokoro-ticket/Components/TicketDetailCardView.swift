import SwiftUI

struct TicketDetailCardView: View {
    let ticket: TicketListItem

    var body: some View {
        VStack(spacing: 22) {
            TicketVisualView(
                title: ticket.title,
                message: ticket.message,
                illustration: ticket.illustration,
                design: ticket.design,
                senderName: ticket.senderName,
                date: ticket.sentAt ?? ticket.createdAt,
                size: .large
            )

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("チケットについて")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    TicketStatusLabel(
                        status: ticket.status,
                        title: contextualStatusText
                    )
                }

                if !ticket.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(ticket.message)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                    .overlay(AppColors.border.opacity(0.7))

                HStack(alignment: .top, spacing: 16) {
                    personDetail(title: "差出人", value: ticket.senderName)
                    personDetail(title: "受け取る人", value: ticket.receiverName ?? "まだ選ばれていません")
                }

                VStack(spacing: 11) {
                    infoRow(
                        title: "作成日",
                        date: ticket.createdAt
                    )
                    if let sentAt = ticket.sentAt {
                        infoRow(title: "送信日", date: sentAt)
                    }
                    if let receivedAt = ticket.receivedAt {
                        infoRow(title: "受取日", date: receivedAt)
                    }
                    if let requestedAt = ticket.requestedAt {
                        infoRow(title: "リクエスト日", date: requestedAt)
                    }
                    if let completedAt = ticket.completedAt {
                        infoRow(title: "完了日", date: completedAt)
                    }
                }

                HStack(spacing: 8) {
                    designDetail(
                        title: "背景",
                        value: ticket.design.backgroundColor.displayName
                    )
                    designDetail(
                        title: "枠",
                        value: ticket.design.borderStyle.displayName
                    )
                }
            }
            .padding(20)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(AppColors.border.opacity(0.85), lineWidth: 1)
            }
            .shadow(color: AppColors.shadow.opacity(0.65), radius: 10, y: 5)
        }
        .accessibilityElement(children: .combine)
    }

    private func personDetail(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)

            Text(value.valueOrFallback("かぞく"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoRow(title: String, date: Date) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(date.formatted(date: .numeric, time: .shortened))
                .foregroundStyle(AppColors.textPrimary)
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
    }

    private func designDetail(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.primarySoft.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var contextualStatusText: String {
        switch (ticket.perspective, ticket.status) {
        case (.receiver, .requested): "相手の対応待ち"
        case (.sender, .requested), (.local, .requested): "対応待ち"
        case (.receiver, .sent): "受け取れます"
        case (_, .completed): "完了しました"
        default: ticket.status.statusLabel
        }
    }
}

private extension String {
    func valueOrFallback(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

#Preview {
    TicketDetailCardView(ticket: MockTicketListItems.items[0])
        .padding()
        .background(AppColors.background)
}
