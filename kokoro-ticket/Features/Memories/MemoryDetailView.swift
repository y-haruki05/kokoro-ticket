import SwiftUI

struct MemoryDetailView: View {
    let ticketID: TicketListItem.ID
    let store: TicketStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TicketDetailHeaderView(title: "思い出詳細") {
                    dismiss()
                }

                if let ticket = store.ticket(id: ticketID), ticket.status == .completed {
                    memoryContent(ticket)
                } else {
                    unavailableContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func memoryContent(_ ticket: TicketListItem) -> some View {
        VStack(spacing: 20) {
            TicketVisualView(
                title: ticket.title,
                message: ticket.message,
                illustration: ticket.illustration,
                design: ticket.design,
                senderName: ticket.senderName,
                date: ticket.completedAt,
                size: .large
            )

            VStack(alignment: .leading, spacing: 18) {
                Text("思い出の記録")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                if !ticket.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(ticket.message)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider().overlay(AppColors.border.opacity(0.7))

                HStack(alignment: .top, spacing: 14) {
                    person(title: "送り主", value: ticket.senderName)
                    person(title: "受取人", value: ticket.receiverName ?? "たいせつな人")
                }

                VStack(spacing: 11) {
                    dateRow("送信日", ticket.sentAt)
                    dateRow("受取日", ticket.receivedAt)
                    dateRow("使用リクエスト日", ticket.requestedAt)
                    dateRow("完了日", ticket.completedAt)
                }

                HStack(spacing: 10) {
                    designValue("背景色", ticket.design.backgroundColor.displayName)
                    designValue("枠デザイン", ticket.design.borderStyle.displayName)
                }
            }
            .padding(20)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppColors.border.opacity(0.85), lineWidth: 1)
            }
            .shadow(color: AppColors.shadow.opacity(0.5), radius: 9, y: 4)
        }
        .accessibilityElement(children: .contain)
    }

    private func person(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func dateRow(_ title: String, _ date: Date?) -> some View {
        if let date {
            HStack {
                Text(title)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(
                    date.formatted(
                        Date.FormatStyle(date: .abbreviated, time: .shortened)
                            .locale(Locale(identifier: "ja_JP"))
                    )
                )
                    .foregroundStyle(AppColors.textPrimary)
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
    }

    private func designValue(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.primarySoft.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var unavailableContent: some View {
        VStack(spacing: 14) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            Text("この思い出を表示できません")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
            Text("情報が更新された可能性があります。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MemoryDetailView(
            ticketID: MemoryPreviewData.single.id,
            store: TicketStore(previewTickets: [MemoryPreviewData.single])
        )
    }
}
#endif
