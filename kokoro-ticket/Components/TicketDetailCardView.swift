import SwiftUI

struct TicketDetailCardView: View {
    let ticket: TicketListItem

    var body: some View {
        VStack(spacing: 18) {
            TicketVisualView(
                title: ticket.title,
                message: ticket.message,
                illustration: ticket.illustration,
                design: ticket.design,
                senderName: ticket.senderName,
                date: ticket.sentAt ?? ticket.createdAt,
                size: .large
            )

            Divider()
                .overlay(AppColors.border.opacity(0.7))

            HStack(alignment: .top, spacing: 16) {
                personDetail(title: "差出人", value: ticket.senderName)
                personDetail(title: "宛先", value: ticket.receiverName ?? "送り先未選択")
            }

            HStack {
                metadata(
                    title: "作成日",
                    value: ticket.createdAt.formatted(date: .numeric, time: .omitted)
                )

                Spacer()

                TicketStatusLabel(status: ticket.status)
            }

            if let sentAt = ticket.sentAt {
                HStack {
                    metadata(
                        title: "送信日時",
                        value: sentAt.formatted(date: .numeric, time: .shortened)
                    )

                    Spacer()
                }
                .padding(.top, -4)
            }

            if let requestedAt = ticket.requestedAt {
                HStack {
                    metadata(
                        title: "リクエスト日時",
                        value: requestedAt.formatted(date: .numeric, time: .shortened)
                    )
                    Spacer()
                }
                .padding(.top, -4)
            }

            if let receivedAt = ticket.receivedAt {
                HStack {
                    metadata(
                        title: "受取日時",
                        value: receivedAt.formatted(date: .numeric, time: .shortened)
                    )
                    Spacer()
                }
                .padding(.top, -4)
            }

            if let completedAt = ticket.completedAt {
                HStack {
                    metadata(
                        title: "完了日時",
                        value: completedAt.formatted(date: .numeric, time: .shortened)
                    )
                    Spacer()
                }
                .padding(.top, -4)
            }

            HStack(spacing: 10) {
                designDetail(
                    title: "背景色",
                    value: ticket.design.backgroundColor.displayName
                )
                designDetail(
                    title: "枠デザイン",
                    value: ticket.design.borderStyle.displayName
                )
            }
        }
        .padding(18)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 14, y: 7)
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

    private func metadata(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
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
        .background(AppColors.cardBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
