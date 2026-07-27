import SwiftUI

enum HomeLayout {
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 22
    static let cardCornerRadius: CGFloat = 22
}

struct HomeGreetingView: View {
    let displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(greeting)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text("今日はどんなきもちを届ける？")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 3)
    }

    private var greeting: String {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix: String
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<11: prefix = "おはよう"
        case 11..<18: prefix = "こんにちは"
        default: prefix = "こんばんは"
        }
        return name.isEmpty ? "\(prefix)！" : "\(prefix)、\(name)さん！"
    }
}

struct HomeFeaturedTicketView: View {
    let ticket: TicketListItem

    var body: some View {
        VStack(spacing: 10) {
            Text(ticket.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(ticket.message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Image("cat_happy")
                .resizable()
                .scaledToFit()
                .frame(height: 144)
                .accessibilityHidden(true)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(ticket.senderName)さんから")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("受け取りました")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Text(receivedDate)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: HomeLayout.cardCornerRadius))
        .overlay {
            TicketBorderShape(
                style: ticket.design.borderStyle,
                color: AppColors.primary.opacity(0.62)
            )
        }
        .shadow(color: AppColors.shadow.opacity(0.6), radius: 6, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: HomeLayout.cardCornerRadius))
        .accessibilityElement(children: .combine)
    }

    private var receivedDate: String {
        (ticket.receivedAt ?? ticket.sentAt ?? ticket.updatedAt)
            .formatted(date: .numeric, time: .omitted)
    }
}

struct HomeFeaturedEmptyView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 11) {
            Image("cat_ticket")
                .resizable()
                .scaledToFit()
                .frame(height: 116)
                .accessibilityHidden(true)

            Text("大切な人へチケットを作ってみよう")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Button(action: onCreate) {
                Text("チケットを作る")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: HomeLayout.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: HomeLayout.cardCornerRadius)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }
}

struct HomeCompactTicketView: View {
    let ticket: TicketListItem

    var body: some View {
        VStack(spacing: 7) {
            Image("cat_default")
                .resizable()
                .scaledToFit()
                .frame(height: 68)
                .accessibilityHidden(true)

            Text(ticket.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(ticket.senderName)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            Text((ticket.receivedAt ?? ticket.sentAt ?? ticket.updatedAt)
                .formatted(date: .numeric, time: .omitted))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary.opacity(0.85))
        }
        .frame(width: 140, height: 153)
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .overlay {
            RoundedRectangle(cornerRadius: 19)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow.opacity(0.5), radius: 5, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 19))
        .accessibilityElement(children: .combine)
    }
}

struct HomeReceivedTicketsEmptyView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            Text("まだチケットは届いていません")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }
}

struct HomeLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primary)
            Text("ホームを準備しています")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
    }
}

struct HomeErrorCard: View {
    let retry: () async -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(height: 68)

            Text("最新の情報を読み込めませんでした")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Button("もう一度読み込む") {
                Task { await retry() }
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.primaryDark)
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }
}
