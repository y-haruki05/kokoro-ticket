import SwiftUI

struct MemoryTicketCardView: View {
    let ticket: TicketListItem

    var body: some View {
        HStack(spacing: 16) {
            catArtwork

            VStack(alignment: .leading, spacing: 8) {
                Text(ticket.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryDark)
                    .lineLimit(2)

                if !ticket.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(ticket.message)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    personLabel("贈った人", ticket.senderName)
                    Text("・")
                        .foregroundStyle(AppColors.border)
                    personLabel("受け取った人", ticket.receiverName ?? "たいせつな人")
                }

                HStack {
                    if let completedAt = ticket.completedAt {
                        Label(
                            completedAt.formatted(
                                Date.FormatStyle(date: .abbreviated, time: .omitted)
                                    .locale(Locale(identifier: "ja_JP"))
                            ),
                            systemImage: "calendar"
                        )
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 4) {
                        Text("詳しく見る")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.border.opacity(0.85), lineWidth: 1)
        }
        .shadow(color: AppColors.shadow.opacity(0.5), radius: 8, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var catArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ticket.design.backgroundColor.color)

            Image(ticket.illustration?.assetName ?? "cat_default")
                .resizable()
                .scaledToFit()
                .padding(9)
        }
        .frame(width: 92, height: 108)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.border.opacity(0.75), lineWidth: 1)
        }
    }

    private func personLabel(_ title: String, _ name: String) -> some View {
        Text("\(title)：\(name)")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

#if DEBUG
#Preview {
    MemoryTicketCardView(ticket: MemoryPreviewData.single)
        .padding()
        .background(AppColors.background)
}
#endif
