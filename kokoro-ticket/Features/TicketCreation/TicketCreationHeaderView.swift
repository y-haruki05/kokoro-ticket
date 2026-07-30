import SwiftUI

struct TicketCreationHeaderView: View {
    let onBack: () -> Void

    var body: some View {
        AppScreenHeader(
            title: "チケットを作る",
            subtitle: "大切な人へ気持ちを届けよう",
            onBack: onBack
        )
    }
}

#Preview {
    TicketCreationHeaderView(onBack: {})
        .padding()
}
