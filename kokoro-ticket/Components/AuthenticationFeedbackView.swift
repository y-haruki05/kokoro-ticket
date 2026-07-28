import SwiftUI

struct AuthenticationFeedbackView: View {
    let imageName: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 72)

            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.primaryDark)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.primaryDark)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(AppColors.primarySoft)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 10, y: 5)
    }
}

#Preview {
    AuthenticationFeedbackView(
        imageName: "cat_sad",
        title: "うまくログインできませんでした",
        message: "メールアドレスとパスワードを確認して、もう一度お試しください。",
        actionTitle: "閉じる",
        action: {}
    )
    .padding()
    .background(AppColors.background)
}
