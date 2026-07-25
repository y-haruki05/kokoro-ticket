import SwiftUI

struct TicketCreationHeaderView: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text("チケット作成")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

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
