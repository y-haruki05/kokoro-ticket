import SwiftUI

struct MemoriesEmptyView: View {
    let onCreateTicket: () -> Void

    var body: some View {
        AppEmptyStateView(
            imageName: "cat_sad",
            title: "まだ思い出はありません。",
            message: "大切なチケットを送り合うと\nここに増えていきます。",
            buttonTitle: "チケットを作る",
            action: onCreateTicket
        )
    }
}

#Preview {
    MemoriesEmptyView(onCreateTicket: {})
        .background(AppColors.background)
}
