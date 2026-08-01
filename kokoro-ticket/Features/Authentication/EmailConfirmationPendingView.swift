import SwiftUI

/// 新規登録後に確認メールの送信先と次の操作を案内する画面
struct EmailConfirmationPendingView: View {
    let email: String
    let onReturnToLogin: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image("cat_ticket")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 154, height: 126)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("確認メールを送りました")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColors.primaryDark)
                        .multilineTextAlignment(.center)

                    Text(maskedEmail)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.primarySoft)
                        .clipShape(Capsule())

                    Text("メール内のリンクを押して、登録を完了してください。確認後はログイン画面から入れます。")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PrimaryActionButton(
                    title: "ログインへ戻る",
                    action: onReturnToLogin
                )

                Text("メールが届かない場合は、迷惑メールフォルダや入力したアドレスをご確認ください。")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 26)
            .padding(.top, 72)
            .padding(.bottom, 36)
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var maskedEmail: String {
        let parts = email.split(separator: "@", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return email }

        let local = parts[0]
        let visibleCount = min(2, local.count)
        let prefix = String(local.prefix(visibleCount))
        let mask = String(repeating: "•", count: max(3, local.count - visibleCount))
        return "\(prefix)\(mask)@\(parts[1])"
    }
}

#Preview {
    EmailConfirmationPendingView(
        email: "kokoro@example.com",
        onReturnToLogin: {}
    )
}
