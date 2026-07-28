import SwiftUI

struct ProfileSettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.border.opacity(0.85), lineWidth: 1)
            }
            .shadow(color: AppColors.shadow.opacity(0.65), radius: 8, y: 4)
        }
    }
}

struct ProfileSettingsRow: View {
    let title: String
    let systemImage: String
    var detail: String? = nil
    var tint = AppColors.primaryDark
    var showsChevron = true
    var isDestructive = false

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.09))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isDestructive ? Color.red : AppColors.textPrimary)

            Spacer()

            if let detail {
                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.65))
            }
        }
        .frame(minHeight: 54)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct ProfileSettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(AppColors.border.opacity(0.55))
            .padding(.leading, 63)
    }
}

struct ProfileInformationView: View {
    let title: String
    let message: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("cat_default")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 126, height: 108)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text(message)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
