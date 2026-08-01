import SwiftUI

/// 画面タイトルと補足文の余白・文字組みを統一するヘッダー
struct AppScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    var trailing: AnyView? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Text(title)
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, onBack == nil && trailing == nil ? 0 : 52)

            HStack {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColors.primaryDark)
                            .frame(
                                width: AppLayout.minimumTapTarget,
                                height: AppLayout.minimumTapTarget
                            )
                            .background(AppColors.primarySoft)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("戻る")
                }

                Spacer()

                if let trailing {
                    trailing
                        .frame(
                            minWidth: AppLayout.minimumTapTarget,
                            minHeight: AppLayout.minimumTapTarget
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: AppLayout.minimumTapTarget)
    }
}

struct AppSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            if let actionTitle {
                Button(actionTitle, action: action)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryDark)
                    .frame(minHeight: AppLayout.minimumTapTarget)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
