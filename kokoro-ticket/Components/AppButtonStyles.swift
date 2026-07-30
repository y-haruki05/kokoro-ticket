import SwiftUI

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppLayout.buttonHeight)
            .padding(.horizontal, 18)
            .background(AppColors.primary)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
            )
            .shadow(color: AppColors.shadow, radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundStyle(AppColors.primaryDark)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppLayout.buttonHeight)
            .padding(.horizontal, 18)
            .background(AppColors.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
                .stroke(AppColors.border, lineWidth: 1)
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AppDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundStyle(AppColors.error)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppLayout.buttonHeight)
            .padding(.horizontal, 18)
            .background(AppColors.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
                .stroke(AppColors.error.opacity(0.35), lineWidth: 1)
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppLayout.controlCornerRadius,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
