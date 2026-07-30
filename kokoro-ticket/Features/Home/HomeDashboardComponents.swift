import SwiftUI

enum HomeLayout {
    static let horizontalPadding = AppLayout.screenHorizontalPadding
    static let sectionSpacing = AppLayout.sectionSpacing
    static let cardCornerRadius = AppLayout.cardCornerRadius
}

struct HomeGreetingView: View {
    let displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(greeting)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text("今日はどんなきもちを届ける？")
                .font(AppTypography.body)
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
        TicketVisualView(
            title: ticket.title,
            message: ticket.message,
            illustration: ticket.illustration,
            design: ticket.design,
            senderName: ticket.senderName,
            date: ticket.receivedAt ?? ticket.sentAt ?? ticket.updatedAt,
            size: .large
        )
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
        .background(AppColors.cardBackground)
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
        TicketVisualView(
            title: ticket.title,
            message: ticket.message,
            illustration: ticket.illustration,
            design: ticket.design,
            senderName: ticket.senderName,
            date: ticket.receivedAt ?? ticket.sentAt ?? ticket.updatedAt,
            size: .compact
        )
        .frame(width: 210)
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
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }
}

struct HomeLoadingView: View {
    var body: some View {
        AppLoadingView(message: "ホームを準備しています")
            .frame(minHeight: 210)
    }
}

struct HomeErrorCard: View {
    let retry: () async -> Void

    var body: some View {
        AppErrorStateView(
            title: "最新の情報を読み込めませんでした",
            message: "通信状態を確認して、もう一度お試しください",
            retryTitle: "もう一度読み込む"
        ) {
            Task {
                await retry()
            }
        }
        .appCard(padding: 0)
    }
}
