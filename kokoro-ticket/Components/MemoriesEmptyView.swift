import SwiftUI

struct MemoriesEmptyView: View {
    let onCreateTicket: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            IllustrationPlaceholderView(compact: true)
                .frame(width: 116, height: 88)

            Text("まだ思い出はありません")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Button(action: onCreateTicket) {
                Text("チケットを作る")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 54)
    }
}

#Preview {
    MemoriesEmptyView(onCreateTicket: {})
        .padding()
        .background(AppColors.background)
}
