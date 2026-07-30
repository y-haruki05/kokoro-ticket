import SwiftUI

struct TicketListEmptyView: View {
    let status: TicketStatus
    let onCreateTicket: () -> Void

    var body: some View {
        AppEmptyStateView(
            imageName: assetName,
            title: message,
            message: guidance,
            buttonTitle: status == .draft ? "チケットを作る" : nil,
            action: onCreateTicket
        )
    }

    private var assetName: String {
        switch status {
        case .draft: "cat_ticket"
        case .received: "cat_welcome"
        case .requested: "cat_default"
        case .completed: "cat_happy"
        case .sent: "cat_sad"
        }
    }

    private var message: String {
        switch status {
        case .draft: "保存したチケットはまだありません"
        case .sent: "送ったチケットはまだありません"
        case .received: "受け取ったチケットはありません"
        case .requested: "対応待ちのチケットはありません"
        case .completed: "まだ完了したチケットはありません"
        }
    }

    private var guidance: String? {
        status == .draft ? "大切な人へ気持ちを届けてみよう" : nil
    }
}

#Preview {
    TicketListEmptyView(status: .draft, onCreateTicket: {})
        .padding()
        .background(AppColors.background)
}
