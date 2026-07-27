import SwiftUI

struct TicketCreationHeaderView: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Text("チケットを作る")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.primaryDark)

                Text("大切な人へ気持ちを届けよう")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.primaryDark)
                        .frame(width: 44, height: 44)
                        .background(AppColors.primarySoft)
                        .clipShape(Circle())
                }
                .accessibilityLabel("戻る")

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TicketCreationHeaderView(onBack: {})
        .padding()
}
