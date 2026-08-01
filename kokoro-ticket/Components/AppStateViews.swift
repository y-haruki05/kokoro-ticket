import SwiftUI

/// ここにゃん・説明・任意の導線を組み合わせる共通Empty State
struct AppEmptyStateView: View {
    let imageName: String
    let title: String
    let message: String?
    var buttonTitle: String? = nil
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 14) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: AppLayout.stateImageSize,
                    height: AppLayout.stateImageSize
                )
                .accessibilityHidden(true)

            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            if let message, !message.isEmpty {
                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            if let buttonTitle {
                Button(buttonTitle, action: action)
                    .buttonStyle(AppPrimaryButtonStyle())
                    .frame(maxWidth: 260)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
    }
}

struct AppLoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.regular)
                .tint(AppColors.primary)
                .accessibilityLabel("読み込み中")

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
        .padding(.vertical, 56)
    }
}

struct AppErrorStateView: View {
    let title: String
    let message: String
    var retryTitle = "もう一度試す"
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image("cat_sad")
                .resizable()
                .scaledToFit()
                .frame(
                    width: AppLayout.stateImageSize,
                    height: AppLayout.stateImageSize
                )
                .accessibilityHidden(true)

            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .lineSpacing(4)

            Button(retryTitle, action: onRetry)
                .buttonStyle(AppPrimaryButtonStyle())
                .frame(maxWidth: 260)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppLayout.screenHorizontalPadding)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
#Preview("Empty Light") {
    AppEmptyStateView(
        imageName: "cat_ticket",
        title: "まだチケットはありません",
        message: "大切な人へ気持ちを届けてみよう",
        buttonTitle: "チケットを作る"
    )
    .background(AppColors.background)
}

#Preview("Loading Dark") {
    AppLoadingView(message: "読み込んでいます")
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("Error iPhone SE", traits: .fixedLayout(width: 320, height: 568)) {
    AppErrorStateView(
        title: "読み込めませんでした",
        message: "通信状態を確認して、もう一度お試しください",
        onRetry: {}
    )
    .background(AppColors.background)
}
#endif
