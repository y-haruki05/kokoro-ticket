import SwiftUI

struct MemoriesEmptyView: View {
    let onCreateTicket: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(width: 126, height: 126)

            Text("まだ思い出はありません。")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("大切なチケットを送り合うと\nここに増えていきます。")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button(action: onCreateTicket) {
                Text("チケットを作る")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 50)
                    .background(AppColors.primary)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
    }
}

#Preview {
    MemoriesEmptyView(onCreateTicket: {})
        .background(AppColors.background)
}
