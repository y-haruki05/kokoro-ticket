import SwiftUI

struct TicketCreationNavigationButtons: View {
    var primaryTitle = "次へ"
    let onBack: () -> Void
    let onNext: () -> Void
    var isPrimaryDisabled = false

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                buttonLabel(
                    "戻る",
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: AppColors.cardBackground
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.border, lineWidth: 1.5)
                }
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                buttonLabel(
                    primaryTitle,
                    foregroundColor: .white,
                    backgroundColor: isPrimaryDisabled
                        ? AppColors.textSecondary.opacity(0.35)
                        : AppColors.primary
                )
                .shadow(color: AppColors.shadow, radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isPrimaryDisabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(AppColors.cardBackground)
        .overlay(alignment: .top) {
            Divider().overlay(AppColors.divider)
        }
    }

    private func buttonLabel(
        _ title: String,
        foregroundColor: Color,
        backgroundColor: Color
    ) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    TicketCreationNavigationButtons(onBack: {}, onNext: {})
}
