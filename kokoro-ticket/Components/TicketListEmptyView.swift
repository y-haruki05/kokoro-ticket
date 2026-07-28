import SwiftUI

struct TicketListEmptyView: View {
    let status: TicketStatus
    let onCreateTicket: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 104)
                .accessibilityHidden(true)

            Text(message)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            if status == .draft {
                Button(action: onCreateTicket) {
                    Text("チケットを作る")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                        .contentShape(RoundedRectangle(cornerRadius: 17))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 230)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 62)
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
}

#Preview {
    TicketListEmptyView(status: .draft, onCreateTicket: {})
        .padding()
        .background(AppColors.background)
}
