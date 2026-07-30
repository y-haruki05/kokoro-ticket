import SwiftUI

struct TicketListLoadingView: View {
    var body: some View {
        AppLoadingView(message: "チケットをひらいています…")
    }
}

struct TicketListLoadErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        AppErrorStateView(
            title: "チケットを読み込めませんでした",
            message: "通信状態を確認して、もう一度お試しください",
            retryTitle: "もう一度読み込む",
            onRetry: onRetry
        )
    }
}

#Preview("Loading") {
    TicketListLoadingView()
        .background(AppColors.background)
}

#Preview("Error") {
    TicketListLoadErrorView(onRetry: {})
        .background(AppColors.background)
}
