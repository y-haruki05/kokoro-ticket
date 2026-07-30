import SwiftUI

struct TicketDetailHeaderView: View {
    var title = "チケット詳細"
    let onBack: () -> Void

    var body: some View {
        AppScreenHeader(title: title, onBack: onBack)
    }
}

#Preview {
    TicketDetailHeaderView(onBack: {})
        .padding()
}
