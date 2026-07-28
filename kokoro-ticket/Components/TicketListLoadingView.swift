import SwiftUI

struct TicketListLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("cat_default")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 92)
                .accessibilityHidden(true)

            ProgressView()
                .tint(AppColors.primary)

            Text("チケットをひらいています…")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
}

struct TicketListLoadErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 92)
                .accessibilityHidden(true)

            Text("チケットを読み込めませんでした")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text("通信状態を確認して、もう一度お試しください")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button("もう一度読み込む", action: onRetry)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryDark)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(AppColors.primarySoft)
                .clipShape(Capsule())
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 58)
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
